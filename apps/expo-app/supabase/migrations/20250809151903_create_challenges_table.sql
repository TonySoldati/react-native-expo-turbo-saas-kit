-- Migration: Create challenges table
-- Date: 2025-01-09
-- Description: Creates the challenges table according to BD-context.txt specifications
-- Purpose: Stores challenge definitions that users can participate in

BEGIN;

-- Create challenges table with all required columns from BD-context.txt
CREATE TABLE IF NOT EXISTS public.challenges (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    title TEXT NOT NULL,
    picture_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL
);

-- Add CHECK constraints as specified in BD-context.txt
ALTER TABLE public.challenges 
ADD CONSTRAINT check_title_length 
CHECK (char_length(title) <= 255);

ALTER TABLE public.challenges 
ADD CONSTRAINT check_picture_url_format 
CHECK (picture_url IS NULL OR picture_url ~ '^https?://');

-- Add comments for documentation
COMMENT ON TABLE public.challenges IS 'Challenges that users can participate in';
COMMENT ON COLUMN public.challenges.id IS 'Primary key UUID for challenge identification';
COMMENT ON COLUMN public.challenges.title IS 'Challenge title with max 255 characters';
COMMENT ON COLUMN public.challenges.picture_url IS 'Optional challenge picture URL';
COMMENT ON COLUMN public.challenges.created_at IS 'Timestamp when challenge was created';
COMMENT ON COLUMN public.challenges.updated_at IS 'Timestamp when challenge was last updated';
COMMENT ON COLUMN public.challenges.created_by IS 'User who created this challenge (audit)';
COMMENT ON COLUMN public.challenges.updated_by IS 'User who last updated this challenge (audit)';

-- Enable RLS (Row Level Security)
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;

-- RLS Policies for challenges table
-- All authenticated users can read challenges (public challenges)
-- Change here if we want to make challenges private or organization-only bounded
CREATE POLICY challenges_read_all ON public.challenges
    FOR SELECT TO authenticated
    USING (true);

-- Only the creator can update their own challenges
CREATE POLICY challenges_update_own ON public.challenges
    FOR UPDATE TO authenticated
    USING (auth.uid() = created_by)
    WITH CHECK (auth.uid() = created_by);

-- Only the creator can delete their own challenges
CREATE POLICY challenges_delete_own ON public.challenges
    FOR DELETE TO authenticated
    USING (auth.uid() = created_by);

-- Authenticated users can create challenges
-- Change here if we want to make challenges only created by admins
CREATE POLICY challenges_insert ON public.challenges
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = created_by);

-- Grant necessary permissions to authenticated users
-- Change here if we want to make challenges only modified by admins and higher security levels
GRANT SELECT, INSERT, UPDATE, DELETE ON public.challenges TO authenticated;

-- Function to automatically update updated_at column and set audit fields
CREATE OR REPLACE FUNCTION public.update_challenges_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-update updated_at and updated_by
CREATE TRIGGER update_challenges_updated_at
    BEFORE UPDATE ON public.challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.update_challenges_updated_at();

-- Function to set created_by on insert
CREATE OR REPLACE FUNCTION public.set_challenges_created_by()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by = auth.uid();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-set created_by and updated_by on insert
CREATE TRIGGER set_challenges_created_by
    BEFORE INSERT ON public.challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.set_challenges_created_by();

-- Function to protect sensitive fields from client updates
CREATE OR REPLACE FUNCTION public.protect_challenges_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent direct updates to audit fields from client
    IF current_user IN ('authenticated', 'anon') THEN
        IF NEW.id <> OLD.id THEN
            RAISE EXCEPTION 'Cannot update challenge ID';
        END IF;
        
        IF NEW.created_at <> OLD.created_at THEN
            RAISE EXCEPTION 'Cannot update created_at field';
        END IF;
        
        -- Modify here for admin level modifications by organization
        IF NEW.created_by IS DISTINCT FROM OLD.created_by THEN
            RAISE EXCEPTION 'Cannot update created_by field';
        END IF;
        
        -- updated_by is handled by the trigger above, reset any client attempt
        NEW.updated_by = auth.uid();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to protect sensitive fields
CREATE TRIGGER protect_challenges_fields
    BEFORE UPDATE ON public.challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_challenges_fields();

COMMIT;
