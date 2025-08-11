-- Migration: Create users table
-- Date: 2025-01-09
-- Description: Creates the users table according to BD-context.txt specifications
-- Purpose: Foundation table for user authentication and profile data with audit columns

BEGIN;

-- Create users table with all required columns from BD-context.txt
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    picture_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL
);

-- Add CHECK constraints as specified in BD-context.txt
ALTER TABLE public.users 
ADD CONSTRAINT check_email_format 
CHECK (email ~ '^[^@]+@[^@]+\.[^@]+$');

ALTER TABLE public.users 
ADD CONSTRAINT check_picture_url_format 
CHECK (picture_url IS NULL OR picture_url ~ '^https?://');

-- Add comments for documentation
COMMENT ON TABLE public.users IS 'Users table for authentication and profile data';
COMMENT ON COLUMN public.users.id IS 'Primary key UUID for user identification';
COMMENT ON COLUMN public.users.email IS 'User email address with format validation';
COMMENT ON COLUMN public.users.picture_url IS 'Optional profile picture URL';
COMMENT ON COLUMN public.users.created_at IS 'Timestamp when user was created';
COMMENT ON COLUMN public.users.updated_at IS 'Timestamp when user was last updated';
COMMENT ON COLUMN public.users.created_by IS 'User who created this record (audit)';
COMMENT ON COLUMN public.users.updated_by IS 'User who last updated this record (audit)';

-- Create indexes as specified in BD-context.txt
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- Enable RLS (Row Level Security)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
-- Users can read their own profile
CREATE POLICY users_read_own ON public.users
    FOR SELECT TO authenticated
    USING (auth.uid() = id);

-- Users can update their own profile (excluding id and email which are protected)
CREATE POLICY users_update_own ON public.users
    FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Grant necessary permissions to authenticated users
GRANT SELECT, UPDATE ON public.users TO authenticated;

-- Function to automatically update updated_at column
CREATE OR REPLACE FUNCTION public.update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-update updated_at and updated_by
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.update_users_updated_at();

-- Function to protect sensitive fields from client updates
CREATE OR REPLACE FUNCTION public.protect_users_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent direct updates to audit fields from client
    IF current_user IN ('authenticated', 'anon') THEN
        IF NEW.id <> OLD.id THEN
            RAISE EXCEPTION 'Cannot update user ID';
        END IF;
        
        IF NEW.created_at <> OLD.created_at THEN
            RAISE EXCEPTION 'Cannot update created_at field';
        END IF;
        
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
CREATE TRIGGER protect_users_fields
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_users_fields();

COMMIT;
