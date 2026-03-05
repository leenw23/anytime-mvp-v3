-- =============================================================================
-- V3 Clean Schema Migration
-- Drop legacy tables/types, recreate from scratch
-- =============================================================================

-- Drop old tables (reverse dependency order)
DROP TABLE IF EXISTS milestones CASCADE;
DROP TABLE IF EXISTS companion_memory CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS companions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop old enum types
DROP TYPE IF EXISTS conversation_type CASCADE;
DROP TYPE IF EXISTS conversation_status CASCADE;
DROP TYPE IF EXISTS message_role CASCADE;
DROP TYPE IF EXISTS memory_type CASCADE;
DROP TYPE IF EXISTS milestone_type CASCADE;
DROP TYPE IF EXISTS milestone_creator CASCADE;

-- =============================================================================
-- Enum Types
-- =============================================================================

CREATE TYPE conversation_type AS ENUM ('onboarding', 'chat', 'call');
CREATE TYPE conversation_status AS ENUM ('active', 'completed', 'abandoned');
CREATE TYPE message_role AS ENUM ('user', 'assistant', 'system');
CREATE TYPE memory_type AS ENUM ('onboarding_summary', 'user_info', 'episode', 'preference', 'relationship');
CREATE TYPE milestone_type AS ENUM ('first_meeting', 'name_chosen', 'new_discovery', 'deep_conversation', 'funny', 'insight', 'comfort', 'special');
CREATE TYPE milestone_creator AS ENUM ('ai', 'user');

-- =============================================================================
-- handle_updated_at() function
-- =============================================================================

CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Tables
-- =============================================================================

-- profiles
CREATE TABLE profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       text,
  display_name text,
  onboarding_completed boolean DEFAULT false,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- companions
CREATE TABLE companions (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name                text NOT NULL DEFAULT 'Anytime',
  avatar_emoji        text DEFAULT '📺',
  identity_summary    text,
  personality_traits  jsonb DEFAULT '["호기심 많은", "솔직한", "약간 엉뚱한"]',
  likes               jsonb DEFAULT '[]',
  dislikes            jsonb DEFAULT '[]',
  current_mood        text DEFAULT 'curious',
  birth_story         text,
  last_routine_at     timestamptz,
  created_at          timestamptz DEFAULT now(),
  updated_at          timestamptz DEFAULT now(),
  UNIQUE (user_id)
);

-- conversations
CREATE TABLE conversations (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  companion_id  uuid REFERENCES companions(id) ON DELETE SET NULL,
  type          conversation_type DEFAULT 'chat',
  status        conversation_status DEFAULT 'active',
  metadata      jsonb DEFAULT '{}',
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

-- messages
CREATE TABLE messages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  role            message_role NOT NULL,
  content         text NOT NULL,
  is_pending      boolean DEFAULT false,
  created_at      timestamptz DEFAULT now()
);

-- companion_memory
CREATE TABLE companion_memory (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  companion_id           uuid NOT NULL REFERENCES companions(id) ON DELETE CASCADE,
  type                   memory_type,
  title                  text,
  content                text NOT NULL,
  importance             int DEFAULT 5 CHECK (importance >= 1 AND importance <= 10),
  source_conversation_id uuid REFERENCES conversations(id) ON DELETE SET NULL,
  created_at             timestamptz DEFAULT now(),
  updated_at             timestamptz DEFAULT now()
);

-- milestones
CREATE TABLE milestones (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  companion_id    uuid NOT NULL REFERENCES companions(id) ON DELETE CASCADE,
  type            milestone_type,
  creator         milestone_creator,
  title           text,
  description     text,
  message_id      uuid REFERENCES messages(id),
  conversation_id uuid REFERENCES conversations(id),
  metadata        jsonb DEFAULT '{}',
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- ai_change_log (NEW)
CREATE TABLE ai_change_log (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  companion_id           uuid NOT NULL REFERENCES companions(id) ON DELETE CASCADE,
  change_type            text NOT NULL,
  field_changed          text,
  old_value              text,
  new_value              text,
  reason                 text,
  triggered_by           text NOT NULL,
  source_conversation_id uuid REFERENCES conversations(id),
  created_at             timestamptz DEFAULT now(),
  CONSTRAINT ai_change_log_change_type_check CHECK (
    change_type IN ('personality_shift','new_like','removed_like','new_dislike','removed_dislike','identity_update','mood_change')
  ),
  CONSTRAINT ai_change_log_triggered_by_check CHECK (
    triggered_by IN ('conversation','routine','self_reflection')
  )
);

-- user_knowledge (NEW)
CREATE TABLE user_knowledge (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  companion_id           uuid NOT NULL REFERENCES companions(id) ON DELETE CASCADE,
  category               text NOT NULL,
  key                    text NOT NULL,
  value                  text NOT NULL,
  confidence             float DEFAULT 0.5 CHECK (confidence >= 0.0 AND confidence <= 1.0),
  source_conversation_id uuid REFERENCES conversations(id),
  learned_at             timestamptz DEFAULT now(),
  updated_at             timestamptz DEFAULT now(),
  CONSTRAINT user_knowledge_category_check CHECK (
    category IN ('basic_info','preferences','emotions','life_events','relationships','habits')
  ),
  UNIQUE (companion_id, category, key)
);

-- routine_logs (NEW)
CREATE TABLE routine_logs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  companion_id    uuid NOT NULL REFERENCES companions(id) ON DELETE CASCADE,
  action          text NOT NULL,
  action_detail   jsonb DEFAULT '{}',
  context_summary text,
  triggered_by    text DEFAULT 'client',
  created_at      timestamptz DEFAULT now(),
  CONSTRAINT routine_logs_action_check CHECK (
    action IN ('send_message','share_discovery','share_thought','self_update','user_update','silent')
  )
);

-- =============================================================================
-- updated_at Triggers
-- =============================================================================

CREATE TRIGGER set_updated_at_profiles
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at_companions
  BEFORE UPDATE ON companions
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at_conversations
  BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at_companion_memory
  BEFORE UPDATE ON companion_memory
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at_milestones
  BEFORE UPDATE ON milestones
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at_user_knowledge
  BEFORE UPDATE ON user_knowledge
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- =============================================================================
-- handle_new_user trigger (auth.users -> profiles)
-- =============================================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =============================================================================
-- Enable Row Level Security
-- =============================================================================

ALTER TABLE profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE companions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations   ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages        ENABLE ROW LEVEL SECURITY;
ALTER TABLE companion_memory ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones      ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_change_log   ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_knowledge  ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_logs    ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- RLS Policies
-- =============================================================================

-- profiles
CREATE POLICY "profiles: select own"  ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles: insert own"  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles: update own"  ON profiles FOR UPDATE USING (auth.uid() = id);

-- companions
CREATE POLICY "companions: select own" ON companions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "companions: insert own" ON companions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "companions: update own" ON companions FOR UPDATE USING (auth.uid() = user_id);

-- conversations
CREATE POLICY "conversations: select own" ON conversations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "conversations: insert own" ON conversations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "conversations: update own" ON conversations FOR UPDATE USING (auth.uid() = user_id);

-- messages (via conversation ownership)
CREATE POLICY "messages: select own" ON messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM conversations c
    WHERE c.id = messages.conversation_id AND c.user_id = auth.uid()
  )
);
CREATE POLICY "messages: insert own" ON messages FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM conversations c
    WHERE c.id = messages.conversation_id AND c.user_id = auth.uid()
  )
);

-- companion_memory (via companion ownership)
CREATE POLICY "companion_memory: select own" ON companion_memory FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM companions co
    WHERE co.id = companion_memory.companion_id AND co.user_id = auth.uid()
  )
);
CREATE POLICY "companion_memory: insert own" ON companion_memory FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM companions co
    WHERE co.id = companion_memory.companion_id AND co.user_id = auth.uid()
  )
);
CREATE POLICY "companion_memory: update own" ON companion_memory FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM companions co
    WHERE co.id = companion_memory.companion_id AND co.user_id = auth.uid()
  )
);
CREATE POLICY "companion_memory: delete own" ON companion_memory FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM companions co
    WHERE co.id = companion_memory.companion_id AND co.user_id = auth.uid()
  )
);

-- milestones
CREATE POLICY "milestones: select own"  ON milestones FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "milestones: insert own"  ON milestones FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "milestones: update own"  ON milestones FOR UPDATE  USING (auth.uid() = user_id);
CREATE POLICY "milestones: delete own"  ON milestones FOR DELETE  USING (auth.uid() = user_id);

-- ai_change_log (SELECT only via companion ownership)
CREATE POLICY "ai_change_log: select own" ON ai_change_log FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM companions co
    WHERE co.id = ai_change_log.companion_id AND co.user_id = auth.uid()
  )
);

-- user_knowledge (SELECT only via companion ownership)
CREATE POLICY "user_knowledge: select own" ON user_knowledge FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM companions co
    WHERE co.id = user_knowledge.companion_id AND co.user_id = auth.uid()
  )
);

-- routine_logs (SELECT only via companion ownership)
CREATE POLICY "routine_logs: select own" ON routine_logs FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM companions co
    WHERE co.id = routine_logs.companion_id AND co.user_id = auth.uid()
  )
);

-- =============================================================================
-- Indexes
-- =============================================================================

CREATE INDEX idx_companions_user_id          ON companions(user_id);
CREATE INDEX idx_conversations_user_id       ON conversations(user_id);
CREATE INDEX idx_conversations_companion_id  ON conversations(companion_id);
CREATE INDEX idx_messages_conversation_id    ON messages(conversation_id);
CREATE INDEX idx_messages_created_at         ON messages(created_at);
CREATE INDEX idx_companion_memory_companion  ON companion_memory(companion_id);
CREATE INDEX idx_milestones_user_id          ON milestones(user_id);
CREATE INDEX idx_milestones_companion_id     ON milestones(companion_id);
CREATE INDEX idx_ai_change_log_companion     ON ai_change_log(companion_id);
CREATE INDEX idx_ai_change_log_created_at    ON ai_change_log(created_at);
CREATE INDEX idx_user_knowledge_companion    ON user_knowledge(companion_id);
CREATE INDEX idx_user_knowledge_category_key ON user_knowledge(companion_id, category, key);
CREATE INDEX idx_routine_logs_companion      ON routine_logs(companion_id);
CREATE INDEX idx_routine_logs_created_at     ON routine_logs(created_at);
