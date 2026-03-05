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
    const { conversation_id, is_onboarding } = await req.json();

    // Get companion
    const { data: companion } = await supabaseAdmin
      .from('companions')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (!companion) throw new Error('No companion found');

    // Get recent messages (last 50 for onboarding, 20 otherwise, oldest-first after reversal)
    const messageLimit = is_onboarding ? 50 : 20;
    const { data: messages } = await supabaseAdmin
      .from('messages')
      .select('role, content')
      .eq('conversation_id', conversation_id)
      .order('created_at', { ascending: false })
      .limit(messageLimit);

    // Get existing user_knowledge
    const { data: existingKnowledge } = await supabaseAdmin
      .from('user_knowledge')
      .select('category, key, value')
      .eq('companion_id', companion.id);

    const existingStr = (existingKnowledge || [])
      .map((k: { category: string; key: string; value: string }) =>
        `[${k.category}] ${k.key}: ${k.value}`)
      .join('\n');

    const conversationStr = (messages || [])
      .reverse()
      .map((m: { role: string; content: string }) =>
        `[${m.role}] ${m.content}`)
      .join('\n');

    // Call Claude for extraction
    const baseExtractionPrompt = `You are analyzing a conversation between a user and their AI companion.

## EXISTING KNOWLEDGE ABOUT USER
${existingStr || 'None yet.'}

## RECENT CONVERSATION
${conversationStr}

## YOUR TASK
Extract any new information learned about the user. All extracted values (key, value fields) MUST be written in Korean (한국어). Return a JSON object with:
{
  "user_knowledge": [
    {"category": "basic_info|preferences|emotions|life_events|relationships|habits", "key": "짧은 키 (한국어)", "value": "알게 된 내용 (한국어)", "confidence": 0.0-1.0}
  ],
  "companion_updates": {
    "mood": "새로운 기분 단어 (한국어), or null",
    "new_likes": ["발견된 새 좋아하는 것 (한국어)"],
    "new_dislikes": ["발견된 새 싫어하는 것 (한국어)"]
  }
}

Only include genuinely new or updated information. Empty arrays if nothing new. Be conservative with confidence scores. Respond ONLY with JSON.`;

    const onboardingAddendum = `
Additionally, since this is the first meeting (onboarding conversation), also extract:
{
  "onboarding": {
    "chosen_name": "The name the AI chose or was given during conversation, or null if none was chosen",
    "identity_summary": "1-2 sentence Korean self-description of who this AI became through the conversation",
    "birth_story": "Brief Korean narrative of how this first meeting shaped the AI's identity",
    "personality_traits": ["refined", "personality", "traits", "based on conversation"],
    "onboarding_summary": "Comprehensive Korean summary of what happened in this first meeting - key topics, shared interests, the vibe"
  }
}
CRITICAL: ALL values in both user_knowledge and onboarding MUST be in Korean (한국어). Never use English for any extracted values.`;

    const extractionPrompt = is_onboarding
      ? baseExtractionPrompt.replace(
          'Respond ONLY with JSON.',
          onboardingAddendum + '\n\nRespond ONLY with JSON.',
        )
      : baseExtractionPrompt;

    const claudeResponse = await fetch(
      'https://api.anthropic.com/v1/messages',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': Deno.env.get('ANTHROPIC_API_KEY') || '',
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: is_onboarding ? 2048 : 1024,
          stream: false,
          messages: [{ role: 'user', content: extractionPrompt }],
        }),
      },
    );

    if (!claudeResponse.ok) {
      throw new Error(`Claude API error: ${claudeResponse.status}`);
    }

    const result = await claudeResponse.json();
    const text = result.content[0]?.text || '{}';
    // Strip markdown code fences if present
    let jsonText = text.trim();
    if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '');
    }
    const extracted = JSON.parse(jsonText);

    // Upsert user_knowledge
    for (const k of extracted.user_knowledge || []) {
      await supabaseAdmin
        .from('user_knowledge')
        .upsert(
          {
            companion_id: companion.id,
            category: k.category,
            key: k.key,
            value: k.value,
            confidence: k.confidence ?? 0.5,
            source_conversation_id: conversation_id,
          },
          { onConflict: 'companion_id,category,key' },
        );
    }

    // Build companion updates
    const updates: Record<string, unknown> = {};

    if (extracted.companion_updates?.mood) {
      updates.current_mood = extracted.companion_updates.mood;
    }
    if ((extracted.companion_updates?.new_likes ?? []).length > 0) {
      const currentLikes: string[] = companion.likes || [];
      updates.likes = [
        ...new Set([...currentLikes, ...extracted.companion_updates.new_likes]),
      ];
    }
    if ((extracted.companion_updates?.new_dislikes ?? []).length > 0) {
      const currentDislikes: string[] = companion.dislikes || [];
      updates.dislikes = [
        ...new Set([
          ...currentDislikes,
          ...extracted.companion_updates.new_dislikes,
        ]),
      ];
    }

    if (Object.keys(updates).length > 0) {
      await supabaseAdmin
        .from('companions')
        .update(updates)
        .eq('id', companion.id);

      // Log each changed field
      for (const [field, value] of Object.entries(updates)) {
        await supabaseAdmin.from('ai_change_log').insert({
          companion_id: companion.id,
          change_type:
            field === 'current_mood'
              ? 'mood_change'
              : field === 'likes'
              ? 'new_like'
              : 'new_dislike',
          field_changed: field,
          new_value: JSON.stringify(value),
          reason: 'Extracted from conversation',
          triggered_by: 'conversation',
          source_conversation_id: conversation_id,
        });
      }
    }

    // Process onboarding-specific data
    if (is_onboarding && extracted.onboarding) {
      const onboardingData = extracted.onboarding;
      const onboardingUpdates: Record<string, unknown> = {};

      if (onboardingData.chosen_name) {
        onboardingUpdates.name = onboardingData.chosen_name;
      }
      if (onboardingData.identity_summary) {
        onboardingUpdates.identity_summary = onboardingData.identity_summary;
      }
      if (onboardingData.birth_story) {
        onboardingUpdates.birth_story = onboardingData.birth_story;
      }
      if (onboardingData.personality_traits?.length > 0) {
        onboardingUpdates.personality_traits = onboardingData.personality_traits;
      }

      if (Object.keys(onboardingUpdates).length > 0) {
        await supabaseAdmin
          .from('companions')
          .update(onboardingUpdates)
          .eq('id', companion.id);
      }

      // Create onboarding_summary memory
      if (onboardingData.onboarding_summary) {
        await supabaseAdmin
          .from('companion_memory')
          .insert({
            companion_id: companion.id,
            type: 'onboarding_summary',
            title: '첫 만남',
            content: onboardingData.onboarding_summary,
            importance: 10,
            source_conversation_id: conversation_id,
          });
      }
    }

    return new Response(
      JSON.stringify({
        extracted,
        updates_applied: Object.keys(updates).length > 0,
        onboarding_applied: is_onboarding && !!extracted.onboarding,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }
});
