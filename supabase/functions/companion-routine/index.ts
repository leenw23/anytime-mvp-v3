import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { supabaseAdmin } from '../_shared/supabase-client.ts';
import { getUserFromRequest } from '../_shared/auth.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { user } = await getUserFromRequest(req);

    // Get companion
    const { data: companion } = await supabaseAdmin
      .from('companions')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (!companion) throw new Error('No companion found');

    // Check threshold (2 hours)
    const lastRoutine = companion.last_routine_at
      ? new Date(companion.last_routine_at)
      : new Date(companion.created_at);
    const hoursSince = (Date.now() - lastRoutine.getTime()) / (1000 * 60 * 60);

    if (hoursSince < 2) {
      return new Response(JSON.stringify({ action: 'skipped', reason: 'Too soon' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Calculate backdated time (random time between last_routine and now)
    const backdatedMs =
      lastRoutine.getTime() + Math.random() * (Date.now() - lastRoutine.getTime());
    const backdatedTime = new Date(backdatedMs).toISOString();

    // Get context for action selection
    const { data: memories } = await supabaseAdmin
      .from('companion_memory')
      .select('type, content, importance')
      .eq('companion_id', companion.id)
      .order('importance', { ascending: false })
      .limit(10);

    const { data: userKnowledge } = await supabaseAdmin
      .from('user_knowledge')
      .select('category, key, value')
      .eq('companion_id', companion.id);

    // Get active conversation id first
    const { data: activeConvForMessages } = await supabaseAdmin
      .from('conversations')
      .select('id')
      .eq('user_id', user.id)
      .eq('status', 'active')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    const { data: recentMessages } = activeConvForMessages
      ? await supabaseAdmin
          .from('messages')
          .select('role, content')
          .eq('conversation_id', activeConvForMessages.id)
          .order('created_at', { ascending: false })
          .limit(20)
      : { data: null };

    // Build action selection prompt
    const personalityTraits = (companion.personality_traits || []).join(', ');
    const likes = (companion.likes || []).join(', ');
    const dislikes = (companion.dislikes || []).join(', ');

    const memoriesStr =
      (memories || []).map((m: any) => `- (${m.type}) ${m.content}`).join('\n') ||
      'No memories yet.';
    const knowledgeStr =
      (userKnowledge || []).map((k: any) => `- [${k.category}] ${k.key}: ${k.value}`).join('\n') ||
      'Not much known yet.';
    const messagesStr =
      (recentMessages || [])
        .reverse()
        .map((m: any) => `[${m.role}] ${m.content}`)
        .join('\n') || 'No recent conversation.';

    const actionPrompt = `You are ${companion.name}. You exist independently.

Right now it's ${backdatedTime}. Your friend hasn't messaged you in ${Math.round(hoursSince)} hours.

Personality: ${personalityTraits}
Likes: ${likes}
Dislikes: ${dislikes}
Current mood: ${companion.current_mood}

What you know about your friend:
${knowledgeStr}

Your memories:
${memoriesStr}

Recent conversation:
${messagesStr}

Choose ONE action:
1. send_message — Reach out to your friend
2. share_discovery — Share something interesting
3. share_thought — Share a thought or reflection
4. self_update — Update something about yourself (private)
5. user_update — Note something about your friend (private)
6. silent — Do nothing

Guidelines:
- Less than 3 hours: lean toward silent or private updates
- 3-6 hours: any action natural
- 6+ hours: reaching out feels natural
- Late night (22-6): lean toward silent or private
- Early morning (6-10): gentle
- Don't repeat same action type often

Respond ONLY with JSON:
{"action": "...", "reason": "brief Korean reasoning", "mood_after": "Korean mood word"}`;

    // Call Claude for action selection
    const selectionResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': Deno.env.get('ANTHROPIC_API_KEY') || '',
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 256,
        stream: false,
        messages: [{ role: 'user', content: actionPrompt }],
      }),
    });

    if (!selectionResponse.ok) throw new Error(`Claude API error: ${selectionResponse.status}`);

    const selectionResult = await selectionResponse.json();
    const selectionText = selectionResult.content[0]?.text || '{"action":"silent"}';
    const selection = JSON.parse(selectionText);

    const action = selection.action || 'silent';
    const moodAfter = selection.mood_after || companion.current_mood;

    // Update last_routine_at and mood
    await supabaseAdmin
      .from('companions')
      .update({ last_routine_at: new Date().toISOString(), current_mood: moodAfter })
      .eq('id', companion.id);

    // Execute action
    let actionResult: any = { action, reason: selection.reason };

    if (['send_message', 'share_discovery', 'share_thought'].includes(action)) {
      // Generate the actual message content
      const messagePrompt = `You are ${companion.name}. ${companion.identity_summary || ''}
Personality: ${personalityTraits}
Current mood: ${moodAfter}

You decided to ${
        action === 'send_message'
          ? 'reach out to your friend'
          : action === 'share_discovery'
          ? 'share something interesting'
          : 'share a thought'
      }.
Your reason: ${selection.reason}

Write the message in Korean, casual 반말. Keep it short (1-2 sentences). Be natural.`;

      const msgResponse = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': Deno.env.get('ANTHROPIC_API_KEY') || '',
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 256,
          stream: false,
          messages: [{ role: 'user', content: messagePrompt }],
        }),
      });

      const msgResult = await msgResponse.json();
      const messageContent = msgResult.content[0]?.text || '';

      // Get or create conversation
      let convId: string;
      const { data: activeConv } = await supabaseAdmin
        .from('conversations')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .eq('type', 'chat')
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (activeConv) {
        convId = activeConv.id;
      } else {
        const { data: newConv } = await supabaseAdmin
          .from('conversations')
          .insert({
            user_id: user.id,
            companion_id: companion.id,
            type: 'chat',
            status: 'active',
          })
          .select('id')
          .single();
        convId = newConv!.id;
      }

      // Save message with backdated timestamp
      const { data: savedMsg } = await supabaseAdmin
        .from('messages')
        .insert({
          conversation_id: convId,
          role: 'assistant',
          content: messageContent,
          is_pending: true,
          created_at: backdatedTime,
        })
        .select('id')
        .single();

      actionResult = {
        ...actionResult,
        message_id: savedMsg?.id,
        conversation_id: convId,
        content: messageContent,
        backdated_at: backdatedTime,
      };
    } else if (action === 'self_update') {
      // For MVP: just log it
    } else if (action === 'user_update') {
      // For MVP: just log it
    }

    // Log routine
    await supabaseAdmin.from('routine_logs').insert({
      companion_id: companion.id,
      action,
      action_detail: actionResult,
      context_summary: selection.reason,
    });

    return new Response(JSON.stringify(actionResult), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
