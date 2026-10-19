-- ==============================================================================
-- Soundifly — Phase 3: User Features SQL Migration
-- Playlists, Playlist Tracks, User Settings, and Profile Enhancements with RLS
-- Execute this script in your Supabase SQL Editor:
-- Dashboard -> SQL Editor -> New query -> Paste & Run
-- ==============================================================================

-- 1. Upgrade profiles table with username and display_name
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS display_name TEXT;

-- Enforce lowercase alphanumeric + underscores for username
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'check_valid_username'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT check_valid_username
      CHECK (username IS NULL OR (length(username) >= 3 AND length(username) <= 30 AND username ~ '^[a-z0-9_]+$'));
  END IF;
END $$;

-- 2. Create Playlists Table
CREATE TABLE IF NOT EXISTS public.playlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  cover_url TEXT DEFAULT '',
  is_public BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indexes for playlists
CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON public.playlists(user_id);
CREATE INDEX IF NOT EXISTS idx_playlists_is_public ON public.playlists(is_public) WHERE is_public = true;

-- 3. Create Playlist Tracks Table
CREATE TABLE IF NOT EXISTS public.playlist_tracks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  playlist_id UUID NOT NULL REFERENCES public.playlists(id) ON DELETE CASCADE,
  song_id TEXT NOT NULL,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  cover_url TEXT DEFAULT '',
  duration_seconds INTEGER DEFAULT 0,
  audio_url TEXT DEFAULT '',
  position INTEGER NOT NULL DEFAULT 0,
  added_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT unique_playlist_position UNIQUE (playlist_id, position)
);

CREATE INDEX IF NOT EXISTS idx_playlist_tracks_playlist ON public.playlist_tracks(playlist_id, position ASC);

-- 4. Create User Settings Table
CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  theme_mode TEXT NOT NULL DEFAULT 'dark',
  audio_quality TEXT NOT NULL DEFAULT 'high',
  autoplay BOOLEAN NOT NULL DEFAULT true,
  keep_history BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playlist_tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for Playlists
-- SELECT: Users can view their own playlists OR any public playlist
DROP POLICY IF EXISTS "Users can view own or public playlists" ON public.playlists;
CREATE POLICY "Users can view own or public playlists"
  ON public.playlists
  FOR SELECT
  TO authenticated, anon
  USING (is_public = true OR auth.uid() = user_id);

-- INSERT: Authenticated users can create playlists for themselves
DROP POLICY IF EXISTS "Users can create own playlists" ON public.playlists;
CREATE POLICY "Users can create own playlists"
  ON public.playlists
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: Only owner can update playlist
DROP POLICY IF EXISTS "Users can update own playlists" ON public.playlists;
CREATE POLICY "Users can update own playlists"
  ON public.playlists
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DELETE: Only owner can delete playlist
DROP POLICY IF EXISTS "Users can delete own playlists" ON public.playlists;
CREATE POLICY "Users can delete own playlists"
  ON public.playlists
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 7. RLS Policies for Playlist Tracks
-- SELECT: Viewable if playlist is public OR owned by the user
DROP POLICY IF EXISTS "Users can view tracks of permitted playlists" ON public.playlist_tracks;
CREATE POLICY "Users can view tracks of permitted playlists"
  ON public.playlist_tracks
  FOR SELECT
  TO authenticated, anon
  USING (
    EXISTS (
      SELECT 1 FROM public.playlists p
      WHERE p.id = playlist_tracks.playlist_id
        AND (p.is_public = true OR p.user_id = auth.uid())
    )
  );

-- INSERT: Only playlist owner can add tracks
DROP POLICY IF EXISTS "Playlist owners can insert tracks" ON public.playlist_tracks;
CREATE POLICY "Playlist owners can insert tracks"
  ON public.playlist_tracks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.playlists p
      WHERE p.id = playlist_tracks.playlist_id
        AND p.user_id = auth.uid()
    )
  );

-- UPDATE: Only playlist owner can reorder/update tracks
DROP POLICY IF EXISTS "Playlist owners can update tracks" ON public.playlist_tracks;
CREATE POLICY "Playlist owners can update tracks"
  ON public.playlist_tracks
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.playlists p
      WHERE p.id = playlist_tracks.playlist_id
        AND p.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.playlists p
      WHERE p.id = playlist_tracks.playlist_id
        AND p.user_id = auth.uid()
    )
  );

-- DELETE: Only playlist owner can remove tracks
DROP POLICY IF EXISTS "Playlist owners can delete tracks" ON public.playlist_tracks;
CREATE POLICY "Playlist owners can delete tracks"
  ON public.playlist_tracks
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.playlists p
      WHERE p.id = playlist_tracks.playlist_id
        AND p.user_id = auth.uid()
    )
  );

-- 8. RLS Policies for Listening History Deletion (Allow users to clear history)
DROP POLICY IF EXISTS "Users can clear their own listening history" ON public.listening_history;
CREATE POLICY "Users can clear their own listening history"
  ON public.listening_history
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 9. RLS Policies for User Settings
DROP POLICY IF EXISTS "Users can view their own settings" ON public.user_settings;
CREATE POLICY "Users can view their own settings"
  ON public.user_settings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own settings" ON public.user_settings;
CREATE POLICY "Users can insert their own settings"
  ON public.user_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own settings" ON public.user_settings;
CREATE POLICY "Users can update their own settings"
  ON public.user_settings
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 10. Storage Bucket Setup for Avatars (Safe idempotent setup)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies for avatars
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );
