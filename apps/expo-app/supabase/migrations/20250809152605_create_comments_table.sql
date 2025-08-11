-- Migration: Create comments table
-- Date: 2025-01-09
-- Description: Creates the comments table according to BD-context.txt specifications
-- Purpose: Stores comments on activity logs with user attribution and audit trail

BEGIN;

-- Create comments table with all required columns from BD-context.txt
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    log_activite_id UUID NOT NULL REFERENCES public.log_activites(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL
);

-- Add CHECK constraints as specified in BD-context.txt
ALTER TABLE public.comments 
ADD CONSTRAINT check_body_length 
CHECK (char_length(body) <= 5000);

-- Add comments for documentation
COMMENT ON TABLE public.comments IS 'Comments on activity logs';
COMMENT ON COLUMN public.comments.id IS 'Primary key UUID for comment identification';
COMMENT ON COLUMN public.comments.log_activite_id IS 'Reference to the activity log being commented on';
COMMENT ON COLUMN public.comments.user_id IS 'Reference to user who wrote the comment';
COMMENT ON COLUMN public.comments.body IS 'Comment content (max 5000 chars)';
COMMENT ON COLUMN public.comments.created_at IS 'Timestamp when comment was created';
COMMENT ON COLUMN public.comments.updated_at IS 'Timestamp when comment was last updated';
COMMENT ON COLUMN public.comments.created_by IS 'User who created this comment (audit)';
COMMENT ON COLUMN public.comments.updated_by IS 'User who last updated this comment (audit)';

-- Create indexes as specified in BD-context.txt
CREATE INDEX IF NOT EXISTS idx_comments_log_activite_id ON public.comments(log_activite_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);

-- Enable RLS (Row Level Security)
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for comments table
-- Users can read comments on activity logs they can access
CREATE POLICY comments_read ON public.comments
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.log_activites la
            WHERE la.id = log_activite_id
            AND (
                la.user_id = auth.uid() OR -- Own activity logs
                la.privacy = 'public' OR -- Public activity logs
                (la.privacy = 'team' AND EXISTS (
                    SELECT 1 FROM public.users_challenges uc
                    WHERE uc.challenge_id = la.challenge_id
                    AND uc.user_id = auth.uid()
                )) -- Team activity logs if user is in same challenge
            )
        )
    );

-- Users can insert comments on activity logs they can access
CREATE POLICY comments_insert ON public.comments
    FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM public.log_activites la
            WHERE la.id = log_activite_id
            AND (
                la.user_id = auth.uid() OR -- Own activity logs
                la.privacy = 'public' OR -- Public activity logs
                (la.privacy = 'team' AND EXISTS (
                    SELECT 1 FROM public.users_challenges uc
                    WHERE uc.challenge_id = la.challenge_id
                    AND uc.user_id = auth.uid()
                )) -- Team activity logs if user is in same challenge
            )
        )
    );

-- Users can update their own comments
CREATE POLICY comments_update ON public.comments
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own comments
CREATE POLICY comments_delete ON public.comments
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.comments TO authenticated;

-- Function to automatically update updated_at column and set audit fields
CREATE OR REPLACE FUNCTION public.update_comments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-update updated_at and updated_by
CREATE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION public.update_comments_updated_at();

-- Function to set created_by on insert
CREATE OR REPLACE FUNCTION public.set_comments_created_by()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by = auth.uid();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-set created_by and updated_by on insert
CREATE TRIGGER set_comments_created_by
    BEFORE INSERT ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION public.set_comments_created_by();

-- Function to protect sensitive fields from client updates
CREATE OR REPLACE FUNCTION public.protect_comments_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent direct updates to audit fields from client
    IF current_user IN ('authenticated', 'anon') THEN
        IF NEW.id <> OLD.id THEN
            RAISE EXCEPTION 'Cannot update comment ID';
        END IF;
        
        IF NEW.created_at <> OLD.created_at THEN
            RAISE EXCEPTION 'Cannot update created_at field';
        END IF;
        
        IF NEW.created_by IS DISTINCT FROM OLD.created_by THEN
            RAISE EXCEPTION 'Cannot update created_by field';
        END IF;
        
        -- Prevent changing log_activite_id and user_id after creation
        IF NEW.log_activite_id <> OLD.log_activite_id THEN
            RAISE EXCEPTION 'Cannot update log_activite_id after creation';
        END IF;
        
        IF NEW.user_id <> OLD.user_id THEN
            RAISE EXCEPTION 'Cannot update user_id after creation';
        END IF;
        
        -- updated_by is handled by the trigger above, reset any client attempt
        NEW.updated_by = auth.uid();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to protect sensitive fields
CREATE TRIGGER protect_comments_fields
    BEFORE UPDATE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_comments_fields();

COMMIT;
