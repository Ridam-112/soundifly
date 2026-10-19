-- Phase 5: Add Live Lyrics & Notification Experience preferences to user_settings
ALTER TABLE public.user_settings 
ADD COLUMN IF NOT EXISTS live_lyrics_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS mini_player_lyrics_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS notification_lyrics_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS mini_player_initial_mode_lyrics BOOLEAN DEFAULT false;
