-- =============================================================================
-- Migration 001: registration follows the course flow
-- =============================================================================
-- The profile row is now created by the app: SignUpUseCase creates the Auth
-- account and then inserts the user_profile row with the returned user id.
-- The database trigger that used to create the row from the signUp metadata
-- must go, otherwise the app's insert collides with it (duplicate id_user).
--
-- HOW TO APPLY (once per Supabase project):
--   1. Supabase dashboard > SQL Editor > New query > paste this file > Run.
--   2. Supabase dashboard > Authentication > Providers > Email:
--      turn "Confirm email" OFF (the profile insert needs the session that
--      signUp returns; with confirmation on, there is no session yet).
--
-- Existing accounts keep their profile rows; nothing is deleted.
-- =============================================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
