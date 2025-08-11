-- Migration: Align database with updated BD design
-- Date: 2025-08-11
-- Description: Aligns the database schema with the updated BD-context.txt design
-- Purpose: Remove users table, update all references to use accounts.id, rename tables and columns
-- Changes:
--   - Drop users table (functionality moved to accounts table)
--   - Rename users_challenges to accounts_challenges
--   - Update all user_id columns to account_id
--   - Update all foreign key references from users.id to accounts.id
--   - Update all audit field references to use accounts.id

BEGIN;

-- Step 1: Drop existing policies and triggers to avoid conflicts
-- Drop policies on users_challenges table
DROP POLICY IF EXISTS users_challenges_read ON public.users_challenges;
DROP POLICY IF EXISTS users_challenges_insert ON public.users_challenges;
DROP POLICY IF EXISTS users_challenges_update ON public.users_challenges;
DROP POLICY IF EXISTS users_challenges_delete ON public.users_challenges;

-- Drop triggers on users_challenges table
DROP TRIGGER IF EXISTS update_users_challenges_updated_at ON public.users_challenges;
DROP TRIGGER IF EXISTS set_users_challenges_created_by ON public.users_challenges;
DROP TRIGGER IF EXISTS protect_users_challenges_fields ON public.users_challenges;

-- Drop policies on users table
DROP POLICY IF EXISTS users_read_own ON public.users;
DROP POLICY IF EXISTS users_update_own ON public.users;

-- Drop triggers on users table
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS set_users_created_by ON public.users;
DROP TRIGGER IF EXISTS protect_users_fields ON public.users;

-- Step 2: Rename users_challenges table to accounts_challenges
ALTER TABLE IF EXISTS public.users_challenges RENAME TO accounts_challenges;

-- Step 3: Update column names in accounts_challenges table
ALTER TABLE public.accounts_challenges 
RENAME COLUMN user_id TO account_id;

-- Step 4: Update foreign key references in accounts_challenges
-- Drop existing foreign key constraints
ALTER TABLE public.accounts_challenges 
DROP CONSTRAINT IF EXISTS users_challenges_user_id_fkey;

ALTER TABLE public.accounts_challenges 
DROP CONSTRAINT IF EXISTS users_challenges_challenge_id_fkey;

ALTER TABLE public.accounts_challenges 
DROP CONSTRAINT IF EXISTS users_challenges_created_by_fkey;

ALTER TABLE public.accounts_challenges 
DROP CONSTRAINT IF EXISTS users_challenges_updated_by_fkey;

-- Add new foreign key constraints referencing accounts.id
ALTER TABLE public.accounts_challenges 
ADD CONSTRAINT accounts_challenges_account_id_fkey 
FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;

ALTER TABLE public.accounts_challenges 
ADD CONSTRAINT accounts_challenges_challenge_id_fkey 
FOREIGN KEY (challenge_id) REFERENCES public.challenges(id) ON DELETE CASCADE;

ALTER TABLE public.accounts_challenges 
ADD CONSTRAINT accounts_challenges_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.accounts(id) ON DELETE SET NULL;

ALTER TABLE public.accounts_challenges 
ADD CONSTRAINT accounts_challenges_updated_by_fkey 
FOREIGN KEY (updated_by) REFERENCES public.accounts(id) ON DELETE SET NULL;

-- Step 5: Update log_activites table
-- Rename user_id to account_id
ALTER TABLE public.log_activites 
RENAME COLUMN user_id TO account_id;

-- Drop existing foreign key constraints
ALTER TABLE public.log_activites 
DROP CONSTRAINT IF EXISTS log_activites_user_id_fkey;

ALTER TABLE public.log_activites 
DROP CONSTRAINT IF EXISTS log_activites_created_by_fkey;

ALTER TABLE public.log_activites 
DROP CONSTRAINT IF EXISTS log_activites_updated_by_fkey;

-- Add new foreign key constraints
ALTER TABLE public.log_activites 
ADD CONSTRAINT log_activites_account_id_fkey 
FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;

ALTER TABLE public.log_activites 
ADD CONSTRAINT log_activites_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.accounts(id) ON DELETE SET NULL;

ALTER TABLE public.log_activites 
ADD CONSTRAINT log_activites_updated_by_fkey 
FOREIGN KEY (updated_by) REFERENCES public.accounts(id) ON DELETE SET NULL;

-- Step 6: Update comments table
-- Rename user_id to account_id
ALTER TABLE public.comments 
RENAME COLUMN user_id TO account_id;

-- Drop existing foreign key constraints
ALTER TABLE public.comments 
DROP CONSTRAINT IF EXISTS comments_user_id_fkey;

ALTER TABLE public.comments 
DROP CONSTRAINT IF EXISTS comments_created_by_fkey;

ALTER TABLE public.comments 
DROP CONSTRAINT IF EXISTS comments_updated_by_fkey;

-- Add new foreign key constraints
ALTER TABLE public.comments 
ADD CONSTRAINT comments_account_id_fkey 
FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;

ALTER TABLE public.comments 
ADD CONSTRAINT comments_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.accounts(id) ON DELETE SET NULL;

ALTER TABLE public.comments 
ADD CONSTRAINT comments_updated_by_fkey 
FOREIGN KEY (updated_by) REFERENCES public.accounts(id) ON DELETE SET NULL;

-- Step 7: Update challenges table audit fields
-- Drop existing foreign key constraints
ALTER TABLE public.challenges 
DROP CONSTRAINT IF EXISTS challenges_created_by_fkey;

ALTER TABLE public.challenges 
DROP CONSTRAINT IF EXISTS challenges_updated_by_fkey;

-- Add new foreign key constraints
ALTER TABLE public.challenges 
ADD CONSTRAINT challenges_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.accounts(id) ON DELETE SET NULL;

ALTER TABLE public.challenges 
ADD CONSTRAINT challenges_updated_by_fkey 
FOREIGN KEY (updated_by) REFERENCES public.accounts(id) ON DELETE SET NULL;

-- Step 8: Drop old indexes and create new ones
-- Drop old indexes
DROP INDEX IF EXISTS idx_users_challenges_user_id;
DROP INDEX IF EXISTS idx_users_challenges_challenge_id;
DROP INDEX IF EXISTS idx_log_activites_user_id;
DROP INDEX IF EXISTS idx_comments_user_id;
DROP INDEX IF EXISTS idx_users_email;

-- Create new indexes
CREATE INDEX IF NOT EXISTS idx_accounts_challenges_account_id ON public.accounts_challenges(account_id);
CREATE INDEX IF NOT EXISTS idx_accounts_challenges_challenge_id ON public.accounts_challenges(challenge_id);
CREATE INDEX IF NOT EXISTS idx_log_activites_account_id ON public.log_activites(account_id);
CREATE INDEX IF NOT EXISTS idx_comments_account_id ON public.comments(account_id);

-- Step 9: Add unique constraint on accounts_challenges
ALTER TABLE public.accounts_challenges 
ADD CONSTRAINT accounts_challenges_unique_participation 
UNIQUE (account_id, challenge_id);

-- Step 10: Update RLS policies for accounts_challenges
-- Users can read their own challenge participations
CREATE POLICY accounts_challenges_read_own ON public.accounts_challenges
    FOR SELECT TO authenticated
    USING (auth.uid() = account_id);

-- Users can read public challenge participations (for team visibility)
CREATE POLICY accounts_challenges_read_public ON public.accounts_challenges
    FOR SELECT TO authenticated
    USING (true);

-- Users can insert their own challenge participations
CREATE POLICY accounts_challenges_insert ON public.accounts_challenges
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = account_id);

-- Users can update their own challenge participations
CREATE POLICY accounts_challenges_update ON public.accounts_challenges
    FOR UPDATE TO authenticated
    USING (auth.uid() = account_id)
    WITH CHECK (auth.uid() = account_id);

-- Users can delete their own challenge participations
CREATE POLICY accounts_challenges_delete ON public.accounts_challenges
    FOR DELETE TO authenticated
    USING (auth.uid() = account_id);

-- Step 11: Update RLS policies for log_activites
-- Update existing policies to use account_id instead of user_id
DROP POLICY IF EXISTS log_activites_read_own ON public.log_activites;
DROP POLICY IF EXISTS log_activites_insert ON public.log_activites;
DROP POLICY IF EXISTS log_activites_update ON public.log_activites;
DROP POLICY IF EXISTS log_activites_delete ON public.log_activites;
DROP POLICY IF EXISTS log_activites_read_public ON public.log_activites;
DROP POLICY IF EXISTS log_activites_read_team ON public.log_activites;

CREATE POLICY log_activites_read_own ON public.log_activites
    FOR SELECT TO authenticated
    USING (auth.uid() = account_id);

CREATE POLICY log_activites_read_public ON public.log_activites
    FOR SELECT TO authenticated
    USING (privacy = 'public');

CREATE POLICY log_activites_read_team ON public.log_activites
    FOR SELECT TO authenticated
    USING (
        privacy = 'team' AND 
        EXISTS (
            SELECT 1 FROM public.accounts_challenges 
            WHERE challenge_id = log_activites.challenge_id 
            AND account_id = auth.uid()
        )
    );

CREATE POLICY log_activites_insert ON public.log_activites
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = account_id);

CREATE POLICY log_activites_update ON public.log_activites
    FOR UPDATE TO authenticated
    USING (auth.uid() = account_id)
    WITH CHECK (auth.uid() = account_id);

CREATE POLICY log_activites_delete ON public.log_activites
    FOR DELETE TO authenticated
    USING (auth.uid() = account_id);

-- Step 12: Update RLS policies for comments
-- Update existing policies to use account_id instead of user_id
DROP POLICY IF EXISTS comments_read ON public.comments;
DROP POLICY IF EXISTS comments_insert ON public.comments;
DROP POLICY IF EXISTS comments_update ON public.comments;
DROP POLICY IF EXISTS comments_delete ON public.comments;
DROP POLICY IF EXISTS comments_read_own ON public.comments;
DROP POLICY IF EXISTS comments_update_own ON public.comments;

CREATE POLICY comments_read ON public.comments
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY comments_insert ON public.comments
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = account_id);

CREATE POLICY comments_update ON public.comments
    FOR UPDATE TO authenticated
    USING (auth.uid() = account_id)
    WITH CHECK (auth.uid() = account_id);

CREATE POLICY comments_delete ON public.comments
    FOR DELETE TO authenticated
    USING (auth.uid() = account_id);

-- Step 13: Update RLS policies for challenges
-- Update existing policies to use account_id instead of user_id
DROP POLICY IF EXISTS challenges_read ON public.challenges;
DROP POLICY IF EXISTS challenges_insert ON public.challenges;
DROP POLICY IF EXISTS challenges_update ON public.challenges;
DROP POLICY IF EXISTS challenges_delete ON public.challenges;
DROP POLICY IF EXISTS challenges_read_own ON public.challenges;
DROP POLICY IF EXISTS challenges_update_own ON public.challenges;

CREATE POLICY challenges_read ON public.challenges
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY challenges_insert ON public.challenges
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY challenges_update ON public.challenges
    FOR UPDATE TO authenticated
    USING (auth.uid() = created_by)
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY challenges_delete ON public.challenges
    FOR DELETE TO authenticated
    USING (auth.uid() = created_by);

-- Step 14: Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.accounts_challenges TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.log_activites TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.comments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.challenges TO authenticated;

-- Step 15: Create triggers for accounts_challenges
-- Function to automatically update updated_at column and set audit fields
CREATE OR REPLACE FUNCTION public.update_accounts_challenges_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-update updated_at and updated_by
CREATE TRIGGER update_accounts_challenges_updated_at
    BEFORE UPDATE ON public.accounts_challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.update_accounts_challenges_updated_at();

-- Function to set created_by on insert
CREATE OR REPLACE FUNCTION public.set_accounts_challenges_created_by()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by = auth.uid();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-set created_by and updated_by on insert
CREATE TRIGGER set_accounts_challenges_created_by
    BEFORE INSERT ON public.accounts_challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.set_accounts_challenges_created_by();

-- Function to protect sensitive fields from client updates
CREATE OR REPLACE FUNCTION public.protect_accounts_challenges_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent direct updates to audit fields from client
    IF current_user IN ('authenticated', 'anon') THEN
        IF NEW.id <> OLD.id THEN
            RAISE EXCEPTION 'Cannot update accounts_challenges ID';
        END IF;
        
        IF NEW.created_at <> OLD.created_at THEN
            RAISE EXCEPTION 'Cannot update created_at field';
        END IF;
        
        IF NEW.created_by IS DISTINCT FROM OLD.created_by THEN
            RAISE EXCEPTION 'Cannot update created_by field';
        END IF;
        
        -- Prevent changing account_id and challenge_id after creation
        IF NEW.account_id <> OLD.account_id THEN
            RAISE EXCEPTION 'Cannot update account_id after creation';
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
CREATE TRIGGER protect_accounts_challenges_fields
    BEFORE UPDATE ON public.accounts_challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_accounts_challenges_fields();

-- Step 16: Update existing trigger functions to use account_id
-- Update log_activites trigger functions
CREATE OR REPLACE FUNCTION public.update_log_activites_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.set_log_activites_created_by()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by = auth.uid();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
        
        -- Prevent changing account_id and challenge_id after creation
        IF NEW.account_id <> OLD.account_id THEN
            RAISE EXCEPTION 'Cannot update account_id after creation';
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

-- Step 17: Update comments trigger functions
CREATE OR REPLACE FUNCTION public.update_comments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.set_comments_created_by()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by = auth.uid();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.protect_comments_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent direct updates to audit fields from client
    IF current_user IN ('authenticated', 'anon') THEN
        IF NEW.id <> OLD.id THEN
            RAISE EXCEPTION 'Cannot update comments ID';
        END IF;
        
        IF NEW.created_at <> OLD.created_at THEN
            RAISE EXCEPTION 'Cannot update created_at field';
        END IF;
        
        IF NEW.created_by IS DISTINCT FROM OLD.created_by THEN
            RAISE EXCEPTION 'Cannot update created_by field';
        END IF;
        
        -- Prevent changing account_id and log_activite_id after creation
        IF NEW.account_id <> OLD.account_id THEN
            RAISE EXCEPTION 'Cannot update account_id after creation';
        END IF;
        
        IF NEW.log_activite_id <> OLD.log_activite_id THEN
            RAISE EXCEPTION 'Cannot update log_activite_id after creation';
        END IF;
        
        -- updated_by is handled by the trigger above, reset any client attempt
        NEW.updated_by = auth.uid();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 18: Update challenges trigger functions
CREATE OR REPLACE FUNCTION public.update_challenges_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.set_challenges_created_by()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by = auth.uid();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.protect_challenges_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent direct updates to audit fields from client
    IF current_user IN ('authenticated', 'anon') THEN
        IF NEW.id <> OLD.id THEN
            RAISE EXCEPTION 'Cannot update challenges ID';
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

-- Step 19: Finally, drop the users table
DROP TABLE IF EXISTS public.users CASCADE;

-- Step 20: Update comments for documentation
COMMENT ON TABLE public.accounts_challenges IS 'Join table linking accounts to challenges they participate in';
COMMENT ON COLUMN public.accounts_challenges.account_id IS 'Reference to the account participating in the challenge';
COMMENT ON COLUMN public.accounts_challenges.challenge_id IS 'Reference to the challenge the account is participating in';
COMMENT ON COLUMN public.accounts_challenges.created_by IS 'Account who created this participation record (audit)';
COMMENT ON COLUMN public.accounts_challenges.updated_by IS 'Account who last updated this participation record (audit)';

COMMENT ON COLUMN public.log_activites.account_id IS 'Reference to the account who owns this activity log';
COMMENT ON COLUMN public.log_activites.created_by IS 'Account who created this activity log (audit)';
COMMENT ON COLUMN public.log_activites.updated_by IS 'Account who last updated this activity log (audit)';

COMMENT ON COLUMN public.comments.account_id IS 'Reference to the account who wrote this comment';
COMMENT ON COLUMN public.comments.created_by IS 'Account who created this comment (audit)';
COMMENT ON COLUMN public.comments.updated_by IS 'Account who last updated this comment (audit)';

COMMENT ON COLUMN public.challenges.created_by IS 'Account who created this challenge (audit)';
COMMENT ON COLUMN public.challenges.updated_by IS 'Account who last updated this challenge (audit)';

COMMIT;
