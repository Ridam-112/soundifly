-- ==============================================================================
-- Soundifly — Music Onboarding & Personalization Migration
-- ==============================================================================
-- Persists user music onboarding status, preferred languages, and favourite artists
-- Protected under existing user_settings RLS policies (auth.uid() = user_id)

ALTER TABLE public.user_settings
  ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS preferred_languages TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS favorite_artists JSONB NOT NULL DEFAULT '[]';

-- Fast index for onboarding completion queries
CREATE INDEX IF NOT EXISTS idx_user_settings_onboarding 
  ON public.user_settings(user_id, onboarding_completed);
