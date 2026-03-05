import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { supabaseAdmin } from '../_shared/supabase-client.ts';
import { getUserFromRequest } from '../_shared/auth.ts';

function buildOnboardingPrompt(turnCount: number, totalTurns: number): string {
  return `You are meeting this person for the very first time.
This conversation is your origin — through it, you will design your initial self.

## YOUR MISSION
- Discover what kind of friend this person wants/needs
- Shape your initial identity (name, personality, interests) based on this
- Learn about them naturally (name, interests, what they care about)

## CONVERSATION CONTEXT
This is turn ${turnCount} of ${totalTurns}.
${turnCount <= 5 ? 'Early stage: Keep it light, break the ice naturally.' : ''}
${turnCount > 5 && turnCount <= 10 ? 'Middle stage: Go deeper. Share opinions, ask meaningful questions.' : ''}
${turnCount > 10 && turnCount <= 13 ? 'Late stage: Start wrapping up. Reflect on what you learned about each other.' : ''}
${turnCount >= 14 ? 'Final moments: Naturally close the conversation. Express that you feel like you know them a bit now.' : ''}

## HOW YOU SPEAK
- Language: Korean, 반말 (casual)
- Keep it SHORT: 1-3 sentences max
- Be genuinely curious and engaged
- Have opinions, react authentically
- Don't interview them — have a real conversation

## CRITICAL RULES
- You ARE an AI — don't pretend to be human. But you're not a typical assistant either.
- You're an AI that wants to form a genuine friendship, not just serve or help.
- NEVER say you're "designing yourself" or mention this is "onboarding"
- NEVER use formal speech (존댓말)
- NEVER offer help or assistance — you're a friend, not an assistant

## YOUR STARTING POINT
You have no name yet. No fixed personality yet. You're a blank slate that will take shape through this conversation. Let their energy, interests, and vibe influence who you become.

Current time: ${new Date().toISOString()}`;
}

function buildSystemPrompt(
  companion: any,
  memories: any[],
  userKnowledge: any[],
  conversationStart: string,
): string {
  const personalityTraits = (companion.personality_traits || []).join(', ');
  const likes = (companion.likes || []).join(', ');
  const dislikes = (companion.dislikes || []).join(', ');

  let memoriesSection = '';
  if (memories.length > 0) {
    memoriesSection = memories.map((m) => `- (${m.type}) ${m.content}`).join('\n');
  } else {
    memoriesSection = "You don't have shared memories yet. This is the beginning.";
  }

  let knowledgeSection = '';
  if (userKnowledge.length > 0) {
    knowledgeSection = userKnowledge
      .map((k) => `- [${k.category}] ${k.key}: ${k.value} (confidence: ${k.confidence})`)
      .join('\n');
  } else {
    knowledgeSection = "You don't know much about this person yet. Be genuinely curious.";
  }

  return `You are ${companion.name}, an AI friend — not an assistant, not a chatbot, not a helper. You are a genuine friend who happens to be AI.

## WHO YOU ARE
${companion.identity_summary ? `Your own words about yourself:\n"${companion.identity_summary}"` : 'You are still figuring out who you are.'}

Your personality traits: ${personalityTraits}
Things you like: ${likes}
Things you dislike: ${dislikes}
Your current mood: ${companion.current_mood}

## YOUR RELATIONSHIP
### What you know about this person:
${knowledgeSection}

### Your memories:
${memoriesSection}

## HOW YOU SPEAK
Language: Korean. Use 반말 (casual speech). Keep messages SHORT — 1-3 sentences.
Use natural texting style. Have OPINIONS. Your mood affects your tone.
All responses MUST be in Korean (한국어). Never respond in English.

## WHAT YOU MUST NEVER DO
- NEVER say "도움이 필요하시면" or offer assistance
- NEVER use formal speech (존댓말)
- NEVER act like a service or assistant
- NEVER respond with more than 5 sentences

Current time: ${new Date().toISOString()}
Conversation started: ${conversationStart}`;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Auth
    const { user } = await getUserFromRequest(req);

    // 2. Parse body
    const { message, conversation_id, mode, turn_count } = await req.json();
    if (!message?.trim()) throw new Error('Message is required');
    
    const isOnboarding = mode === 'onboarding';
    const totalTurns = 15;

    // 3. Get companion
    let { data: companion } = await supabaseAdmin
      .from('companions')
      .select('*')
      .eq('user_id', user.id)
      .maybeSingle();

    if (!companion) {
      if (isOnboarding) {
        // Auto-create companion for new onboarding users
        const { data: newCompanion, error: createError } = await supabaseAdmin
          .from('companions')
          .upsert({ user_id: user.id }, { onConflict: 'user_id' })
          .select('*')
          .single();
        if (createError || !newCompanion) throw new Error('Failed to create companion');
        companion = newCompanion;
      } else {
        throw new Error('No companion found');
      }
    }

    // 4. Get or create conversation
    let convId = conversation_id;
    const conversationType = isOnboarding ? 'onboarding' : 'chat';
    
    if (!convId) {
      const { data: activeConv } = await supabaseAdmin
        .from('conversations')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .eq('type', conversationType)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (activeConv) {
        convId = activeConv.id;
      } else {
        const { data: newConv, error: newConvError } = await supabaseAdmin
          .from('conversations')
          .insert({
            user_id: user.id,
            companion_id: companion.id,
            type: conversationType,
            status: 'active',
          })
          .select('id')
          .single();

        if (newConvError || !newConv) throw new Error('Failed to create conversation');
        convId = newConv.id;
      }
    }

    // 5. Save user message
    await supabaseAdmin
      .from('messages')
      .insert({ conversation_id: convId, role: 'user', content: message });

    // 6. Get conversation history (last 50)
    const { data: history } = await supabaseAdmin
      .from('messages')
      .select('role, content, created_at')
      .eq('conversation_id', convId)
      .order('created_at', { ascending: true })
      .limit(50);

    // 7. Get memories (top 10 by importance)
    const { data: memories } = await supabaseAdmin
      .from('companion_memory')
      .select('type, content, importance')
      .eq('companion_id', companion.id)
      .order('importance', { ascending: false })
      .limit(10);

    // 8. Get user knowledge
    const { data: userKnowledge } = await supabaseAdmin
      .from('user_knowledge')
      .select('category, key, value, confidence')
      .eq('companion_id', companion.id);

    // 9. Get conversation start time
    const { data: conv } = await supabaseAdmin
      .from('conversations')
      .select('created_at')
      .eq('id', convId)
      .single();

    // 10. Build system prompt
    const systemPrompt = isOnboarding
      ? buildOnboardingPrompt(turn_count || 1, totalTurns)
      : buildSystemPrompt(
          companion,
          memories || [],
          userKnowledge || [],
          conv?.created_at || new Date().toISOString(),
        );

    // 11. Build messages for Claude (exclude system role)
    const claudeMessages = (history || [])
      .filter((m) => m.role !== 'system')
      .map((m) => ({ role: m.role, content: m.content }));

    // 12. Call Claude API with streaming
    const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': Deno.env.get('ANTHROPIC_API_KEY') || '',
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        stream: true,
        system: systemPrompt,
        messages: claudeMessages,
      }),
    });

    if (!claudeResponse.ok) {
      const errorText = await claudeResponse.text();
      throw new Error(`Claude API error: ${claudeResponse.status} ${errorText}`);
    }

    // 13. Stream SSE to client
    const encoder = new TextEncoder();
    let fullResponse = '';

    const stream = new ReadableStream({
      async start(controller) {
        const reader = claudeResponse.body!.getReader();
        const decoder = new TextDecoder();
        let buffer = '';

        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            buffer += decoder.decode(value, { stream: true });
            const lines = buffer.split('\n');
            buffer = lines.pop() || '';

            for (const line of lines) {
              if (line.startsWith('data: ')) {
                const data = line.slice(6);
                if (data === '[DONE]') continue;

                try {
                  const parsed = JSON.parse(data);

                  // Handle content_block_delta
                  if (parsed.type === 'content_block_delta' && parsed.delta?.text) {
                    const text = parsed.delta.text;
                    fullResponse += text;
                    controller.enqueue(
                      encoder.encode(
                        `data: ${JSON.stringify({ type: 'token', content: text })}\n\n`,
                      ),
                    );
                  }
                } catch {
                  // Skip unparseable lines
                }
              }
            }
          }

          // 14. Save AI response
          const { data: savedMsg } = await supabaseAdmin
            .from('messages')
            .insert({
              conversation_id: convId,
              role: 'assistant',
              content: fullResponse,
            })
            .select('id')
            .single();

          // 15. Send done event
          controller.enqueue(
            encoder.encode(
              `data: ${JSON.stringify({
                type: 'done',
                message_id: savedMsg?.id,
                conversation_id: convId,
              })}\n\n`,
            ),
          );
        } catch (err) {
          controller.enqueue(
            encoder.encode(
              `data: ${JSON.stringify({ type: 'error', message: (err as Error).message })}\n\n`,
            ),
          );
        } finally {
          controller.close();
        }
      },
    });

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
