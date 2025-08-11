-- Migration: Create log_activite table
-- Date: 2024-10-16
-- Description: Stores activity logs (equivalent of posts) with account, title, description, and picture.

-- Create log_activite table
CREATE TABLE IF NOT EXISTS public.log_activite (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    picture_url VARCHAR(1000),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add comments for documentation
COMMENT ON TABLE public.log_activite IS 'Activity logs (posts) linked to accounts';
COMMENT ON COLUMN public.log_activite.account_id IS 'Reference to the account that owns this activity log';
COMMENT ON COLUMN public.log_activite.title IS 'Title of the activity log';
COMMENT ON COLUMN public.log_activite.description IS 'Description/content of the activity log';
COMMENT ON COLUMN public.log_activite.picture_url IS 'URL to the picture associated with this activity log';

-- Enable RLS on the log_activite table
ALTER TABLE public.log_activite ENABLE ROW LEVEL SECURITY;

-- RLS Policies for log_activite
-- Users can read their own activity logs
CREATE POLICY log_activite_read ON public.log_activite
    FOR SELECT TO authenticated
    USING (auth.uid() = account_id);

-- Users can insert their own activity logs
CREATE POLICY log_activite_insert ON public.log_activite
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = account_id);

-- Users can update their own activity logs
CREATE POLICY log_activite_update ON public.log_activite
    FOR UPDATE TO authenticated
    USING (auth.uid() = account_id)
    WITH CHECK (auth.uid() = account_id);

-- Users can delete their own activity logs
CREATE POLICY log_activite_delete ON public.log_activite
    FOR DELETE TO authenticated
    USING (auth.uid() = account_id);

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.log_activite TO authenticated;

-- Create indexes for better performance
CREATE INDEX idx_log_activite_account_id ON public.log_activite(account_id);
CREATE INDEX idx_log_activite_created_at ON public.log_activite(created_at);
CREATE INDEX idx_log_activite_title ON public.log_activite(title);

-- Function to auto-update updated_at column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update updated_at
CREATE TRIGGER update_log_activite_updated_at
    BEFORE UPDATE ON public.log_activite
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
