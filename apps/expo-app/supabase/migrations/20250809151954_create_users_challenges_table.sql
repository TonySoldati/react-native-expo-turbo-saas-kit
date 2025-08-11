-- Migration: Create users_challenges table
-- Date: 2025-01-09
-- Description: Creates the users_challenges join table according to BD-context.txt specifications
-- Purpose: Many-to-many relationship between users and challenges (challenge participation)

BEGIN;

-- Create users_challenges table with all required columns from BD-context.txt
CREATE TABLE IF NOT EXISTS public.users_challenges (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL
);

-- Add unique constraint to prevent duplicate user-challenge pairs
ALTER TABLE public.users_challenges 
ADD CONSTRAINT unique_user_challenge 
UNIQUE (user_id, challenge_id);

-- Add comments for documentation
COMMENT ON TABLE public.users_challenges IS 'Many-to-many relationship between users and challenges';
COMMENT ON COLUMN public.users_challenges.id IS 'Primary key UUID for the participation record';
COMMENT ON COLUMN public.users_challenges.user_id IS 'Reference to user participating in challenge';
COMMENT ON COLUMN public.users_challenges.challenge_id IS 'Reference to challenge being participated in';
COMMENT ON COLUMN public.users_challenges.created_at IS 'Timestamp when user joined challenge';
COMMENT ON COLUMN public.users_challenges.updated_at IS 'Timestamp when participation was last updated';
COMMENT ON COLUMN public.users_challenges.created_by IS 'User who created this participation record (audit)';
COMMENT ON COLUMN public.users_challenges.updated_by IS 'User who last updated this participation record (audit)';

-- Create indexes as specified in BD-context.txt
CREATE INDEX IF NOT EXISTS idx_users_challenges_user_id ON public.users_challenges(user_id);
CREATE INDEX IF NOT EXISTS idx_users_challenges_challenge_id ON public.users_challenges(challenge_id);

-- Enable RLS (Row Level Security)
ALTER TABLE public.users_challenges ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users_challenges table
-- Users can read their own participations and participations in challenges they can see
CREATE POLICY users_challenges_read_own ON public.users_challenges
    FOR SELECT TO authenticated
    USING (
        auth.uid() = user_id OR 
        EXISTS (
            SELECT 1 FROM public.challenges 
            WHERE id = challenge_id
        )
    );

-- Users can insert their own participations
CREATE POLICY users_challenges_insert_own ON public.users_challenges
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own participations
CREATE POLICY users_challenges_update_own ON public.users_challenges
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own participations
CREATE POLICY users_challenges_delete_own ON public.users_challenges
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users_challenges TO authenticated;

-- Function to automatically update updated_at column and set audit fields
CREATE OR REPLACE FUNCTION public.update_users_challenges_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-update updated_at and updated_by
CREATE TRIGGER update_users_challenges_updated_at
    BEFORE UPDATE ON public.users_challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.update_users_challenges_updated_at();

-- Function to set created_by on insert
CREATE OR REPLACE FUNCTION public.set_users_challenges_created_by()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by = auth.uid();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-set created_by and updated_by on insert
CREATE TRIGGER set_users_challenges_created_by
    BEFORE INSERT ON public.users_challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.set_users_challenges_created_by();

-- Function to protect sensitive fields from client updates
CREATE OR REPLACE FUNCTION public.protect_users_challenges_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent direct updates to audit fields from client
    IF current_user IN ('authenticated', 'anon') THEN
        IF NEW.id <> OLD.id THEN
            RAISE EXCEPTION 'Cannot update users_challenges ID';
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
CREATE TRIGGER protect_users_challenges_fields
    BEFORE UPDATE ON public.users_challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_users_challenges_fields();

COMMIT;
