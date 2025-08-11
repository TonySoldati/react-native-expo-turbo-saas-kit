# Who are you
You are assisting in the implementation of a PostgreSQL database for this project. Your role is to create migration files strictly aligned with the approved design file DB-context.txt in # Ressources

# What to do
This is the implementation phase, focused exclusively on writing migration files to incrementally build and modify the database schema as designed.
Do NOT modify the DB-context.txt file or any other project files beyond migration-related files.

Follow all steps in # Implementation Workflow and apply mandatory best practices and commands listed in # Supabase Migration Commands

# Fail conditions
- Using powershell instead of cmd to run commands
- Not using # Supabase Migration Commands to create migration files
- Not reading this entire file
- Failure to follow *Mandatory* tags or best practices.
- Modifying schema design files or project files other than migrations.
- Creating migrations that do multiple unrelated changes.
- Not documenting migrations clearly.
- Running migrations without proper testing.

# Implementation Workflow
1. Pull latest DB-context.txt.
2. Make sure you are in folder apps/expo-app in the command line. If you are not, then change by using cd apps/expo-app
2. Create migration file with `pnpm supabase migration new <name>`.
3. Implement migration SQL:
   - Create/modify tables, columns, constraints.
   - Add indexes as needed.
   - Add audit columns with ON DELETE SET NULL.
4. Document migration purpose and changes in file header.
5. Test migration on local dev database with `pnpm supabase db reset` and `pnpm supabase db push`.
6. Test migration on staging database.
7. Verify no sensitive data fields are exposed or modifiable by clients.
8. Review.
9. Regen types with `pnpm supabase:typegen`

# Implementation Review *Mandatory*
- One Purpose per Migration:  
Each migration file must have a single logical change.

- Consistent Naming Convention:  
Date prefix (YYYYMMDD_HHMM) + descriptive action.

- Idempotency Awareness:  
Use `IF NOT EXISTS` and `DROP ... IF EXISTS` clauses appropriately.

- Add Constraints Early:  
Include NOT NULL, foreign keys, CHECK constraints from day one.

- Audit & Ownership Columns:  
Add created_at, updated_at, created_by, updated_by in all tables at creation, with ON DELETE SET NULL on audit fields.

- Document Every Migration:  
Include purpose, changes, special notes in migration header comments or companion `.md`.

- Testing:  
Run full reset and incremental migrations locally and on staging

- Security:  
Audit columns must be set server-side only, not by clients.


# Supabase Migration Commands

## Create
- `supabase migration new <name>` — create a new migration file.

## Apply
- `supabase db reset` — reset local DB, apply all migrations.
- `supabase db push` — apply only pending migrations.

## Check
- `supabase db diff` — show schema diff between local and DB.
- `supabase db diff --schema public --use-migra > migrations/<timestamp>_changes.sql` — generate migration from schema diff.

## Develop / Test
- `pnpm supabase:start` — run local Supabase dev environment.
- `pnpm supabase:reset` — reset DB and apply migrations + seed.
- `pnpm supabase:test` — run migration tests.

## Quality
- `pnpm supabase:db:lint` — lint the database schema for issues.

# Additional Notes

## Rollback Strategies
- Write reversible migrations when possible.
- For destructive changes, use a two-step approach: deprecate first, drop later.
- Always include rollback instructions or files if supported.

## Security Reminders
- Audit columns (`created_by`, `updated_by`) must be set server-side only.
- Never trust client input for ownership or audit data.
- Use parameterized queries or ORM methods to prevent SQL injection.

## PR Review Checklist
- Migration has a clear, single purpose.
- Naming follows YYYYMMDD_HHMM_description.sql pattern.
- Constraints and indexes are added early.
- Audit columns included with proper ON DELETE behavior.
- Migration tested locally and on staging.
- Documentation is clear and complete.
- Security considerations addressed.
- No schema or design files changed outside migration scope.

# Resources
- DB-context.txt (source of truth for schema)

# Common Migration Pitfalls *Mandatory*
- ❌ Adding NOT NULL to existing table without DEFAULT
- ❌ Creating FK before parent table exists
- ❌ Adding unique constraint on column with duplicates
- ❌ Dropping columns referenced by views/functions

# Environment Considerations *Mandatory*
- Development: Use `IF NOT EXISTS` more liberally
- Staging: Test with production-like data volumes
- Production: More conservative, always have rollback plan ready

# Error Prevention *Mandatory*
- Use transactions for multi-step migrations:
  ```sql
  BEGIN;
  -- migration steps
  COMMIT; -- or ROLLBACK on error
  ```
- Test constraint additions on populated tables
- Validate data before adding NOT NULL constraints

# Migration Dependencies *Mandatory*
- Foreign key dependencies: Create parent tables before child tables
- Constraint dependencies: Create tables before adding complex constraints
- Index dependencies: Create tables/columns before indexes
- Example order: users → challenges → users_challenges → log_activites → comments
