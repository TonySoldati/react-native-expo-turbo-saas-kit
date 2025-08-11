-- Migration: Update log_activite table to match BD-context.txt specifications
-- Date: 2025-01-09
-- Description: Updates existing log_activite table to match log_activites specification in BD-context.txt
-- Purpose: Rename table, add missing columns, update constraints and relationships

BEGIN;

-- First, drop existing policies and triggers to avoid conflicts
DROP POLICY IF EXISTS log_activite_read ON public.log_activite;
DROP POLICY IF EXISTS log_activite_insert ON public.log_activite;
DROP POLICY IF EXISTS log_activite_update ON public.log_activite;
DROP POLICY IF EXISTS log_activite_delete ON public.log_activite;
DROP TRIGGER IF EXISTS update_log_activite_updated_at ON public.log_activite;
DROP FUNCTION IF EXISTS public.update_updated_at_column();

-- Rename the table from log_activite to log_activites (plural)
ALTER TABLE IF EXISTS public.log_activite RENAME TO log_activites;

-- Add missing columns according to BD-context.txt
-- Change account_id to user_id and reference users table instead of accounts
ALTER TABLE public.log_activites 
DROP COLUMN IF EXISTS account_id;

ALTER TABLE public.log_activites 
ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE;

-- Rename description to body
ALTER TABLE public.log_activites 
RENAME COLUMN description TO body;

-- Change picture_url to image_url
ALTER TABLE public.log_activites 
RENAME COLUMN picture_url TO image_url;

-- Add missing audit columns
ALTER TABLE public.log_activites 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE public.log_activites 
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL;

-- Add challenge_id column
ALTER TABLE public.log_activites 
ADD COLUMN IF NOT EXISTS challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE;

-- Create privacy enum type
DROP TYPE IF EXISTS privacy_level;
CREATE TYPE privacy_level AS ENUM ('public', 'team', 'private');

-- Add privacy column with default 'public'
ALTER TABLE public.log_activites 
ADD COLUMN IF NOT EXISTS privacy privacy_level DEFAULT 'public';

-- Add CHECK constraints as specified in BD-context.txt
ALTER TABLE public.log_activites 
DROP CONSTRAINT IF EXISTS check_title_length;
ALTER TABLE public.log_activites 
ADD CONSTRAINT check_title_length 
CHECK (char_length(title) <= 255);

ALTER TABLE public.log_activites 
DROP CONSTRAINT IF EXISTS check_image_url_format;
ALTER TABLE public.log_activites 
ADD CONSTRAINT check_image_url_format 
CHECK (image_url IS NULL OR image_url ~ '^https?://');

-- Update comments for documentation
COMMENT ON TABLE public.log_activites IS 'Activity logs linked to users and challenges';
COMMENT ON COLUMN public.log_activites.user_id IS 'Reference to the user who owns this activity log';
COMMENT ON COLUMN public.log_activites.title IS 'Title of the activity log (max 255 chars)';
COMMENT ON COLUMN public.log_activites.body IS 'Body/content of the activity log';
COMMENT ON COLUMN public.log_activites.image_url IS 'URL to the image associated with this activity log';
COMMENT ON COLUMN public.log_activites.challenge_id IS 'Reference to the challenge this activity belongs to';
COMMENT ON COLUMN public.log_activites.privacy IS 'Privacy level: public, team, or private';
COMMENT ON COLUMN public.log_activites.created_by IS 'User who created this activity log (audit)';
COMMENT ON COLUMN public.log_activites.updated_by IS 'User who last updated this activity log (audit)';

-- Drop old indexes and create new ones as specified in BD-context.txt
DROP INDEX IF EXISTS idx_log_activite_account_id;
DROP INDEX IF EXISTS idx_log_activite_created_at;
DROP INDEX IF EXISTS idx_log_activite_title;

CREATE INDEX IF NOT EXISTS idx_log_activites_user_id ON public.log_activites(user_id);
CREATE INDEX IF NOT EXISTS idx_log_activites_challenge_id ON public.log_activites(challenge_id);

-- RLS Policies for log_activites table based on privacy levels
-- Users can read their own activity logs
CREATE POLICY log_activites_read_own ON public.log_activites
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

-- Users can read public activity logs
CREATE POLICY log_activites_read_public ON public.log_activites
    FOR SELECT TO authenticated
    USING (privacy = 'public');

-- Users can read team activity logs if they participate in the same challenge
CREATE POLICY log_activites_read_team ON public.log_activites
    FOR SELECT TO authenticated
    USING (
        privacy = 'team' AND 
        EXISTS (
            SELECT 1 FROM public.users_challenges 
            WHERE challenge_id = log_activites.challenge_id 
            AND user_id = auth.uid()
        )
    );

-- Users can insert their own activity logs
CREATE POLICY log_activites_insert ON public.log_activites
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own activity logs (business rule: only author can edit)
CREATE POLICY log_activites_update ON public.log_activites
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own activity logs (business rule: only author can delete)
CREATE POLICY log_activites_delete ON public.log_activites
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.log_activites TO authenticated;

-- Function to automatically update updated_at column and set audit fields
CREATE OR REPLACE FUNCTION public.update_log_activites_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-update updated_at and updated_by
CREATE TRIGGER update_log_activites_updated_at
    BEFORE UPDATE ON public.log_activites
    FOR EACH ROW
    EXECUTE FUNCTION public.update_log_activites_updated_at();

-- Function to set created_by on insert
CREATE OR REPLACE FUNCTION public.set_log_activites_created_by()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by = auth.uid();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-set created_by and updated_by on insert
CREATE TRIGGER set_log_activites_created_by
    BEFORE INSERT ON public.log_activites
    FOR EACH ROW
    EXECUTE FUNCTION public.set_log_activites_created_by();

-- Function to protect sensitive fields from client updates
CREATE OR REPLACE FUNCTION public.protect_log_activites_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent direct updates to audit fields from client
    IF current_user IN ('authenticated', 'anon') THEN
        IF NEW.id <> OLD.id THEN
            RAISE EXCEPTION 'Cannot update log_activites ID';
        END IF;
        
        IF NEW.created_at <> OLD.created_at THEN
            RAISE EXCEPTION 'Cannot update created_at field';
        END IF;
        
        IF NEW.created_by IS DISTINCT FROM OLD.created_by THEN
            RAISE EXCEPTION 'Cannot update created_by field';
        END IF;
        
        -- Prevent changing user_id and challenge_id after creation
        IF NEW.user_id <> OLD.user_id THEN
            RAISE EXCEPTION 'Cannot update user_id after creation';
        END IF;
        
        IF NEW.challenge_id <> OLD.challenge_id THEN
            RAISE EXCEPTION 'Cannot update challenge_id after creation';
        END IF;
        
        -- updated_by is handled by the trigger above, reset any client attempt
        NEW.updated_by = auth.uid();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to protect sensitive fields
CREATE TRIGGER protect_log_activites_fields
    BEFORE UPDATE ON public.log_activites
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_log_activites_fields();

COMMIT;
