-- ==============================================================================
-- Soundifly — Music Listening History & Favorites Tables
-- Execute this script in your Supabase SQL Editor:
-- Dashboard -> SQL Editor -> New query -> Paste & Run
-- ==============================================================================

-- 1. Listening History Table
CREATE TABLE IF NOT EXISTS public.listening_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  song_id TEXT NOT NULL,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  cover_url TEXT,
  duration_seconds INTEGER DEFAULT 0,
  played_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index for speedy queries on user history ordered by recent plays
CREATE INDEX IF NOT EXISTS idx_listening_history_user_played
  ON public.listening_history(user_id, played_at DESC);

-- 2. User Favorites Table
CREATE TABLE IF NOT EXISTS public.user_favorites (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  song_id TEXT NOT NULL,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  cover_url TEXT,
  duration_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (user_id, song_id)
);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.listening_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for listening_history
DROP POLICY IF EXISTS "Users can view their own listening history" ON public.listening_history;
CREATE POLICY "Users can view their own listening history"
  ON public.listening_history
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert into their own listening history" ON public.listening_history;
CREATE POLICY "Users can insert into their own listening history"
  ON public.listening_history
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 5. RLS Policies for user_favorites
DROP POLICY IF EXISTS "Users can view their own favorites" ON public.user_favorites;
CREATE POLICY "Users can view their own favorites"
  ON public.user_favorites
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can add to their own favorites" ON public.user_favorites;
CREATE POLICY "Users can add to their own favorites"
  ON public.user_favorites
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can remove their own favorites" ON public.user_favorites;
CREATE POLICY "Users can remove their own favorites"
  ON public.user_favorites
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
