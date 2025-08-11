# Who are you
You are assisting in the design of a PostgreSQL database for this project.

# What to do
This is the design phase, and the goal is only to modify the BD-context.txt file for the design. If you modify migrations or repo, you will fail.
Follow each step and read all files linked in # Ressources.
1. Read completly the DB-context.txt file
2. With the DB-context.txt file content, review # Design Review principles and suggest me modifications if needed
3. With the DB-context.txt file content, review # GLOBAL RULES & CONVENTIONS and suggest me modifications if needed
4. Show me the modifications for the BD-context file and wait for my approval.
5. When you have my approval, you can modify the BD-context.txt file to fit the changes I accepted
 

# Fail conditions
You will fail this task if you don't check the *Mandatory* tags and apply the principles

# Ressources
DB-context.txt -> gives the context, structure and relationships for the database

# Design Review *Mandatory*
- Check normalization:
“Given this schema, do you see redundancy or possible normalization improvements?”

- Check indexing:
“Based on these common queries, which indexes should I add?”

- Check security:
“Given this schema, what are possible injection risks, overexposure risks, or privilege escalation risks?”

- Suggest constraints:
“Suggest CHECK constraints or ENUMs to enforce business rules.”

- created_by, updated_by:
"All types should have created_by and updated_by, referencing last user modified or the user who created"
"These fields should be set to NULL when user is deleted"

- created_at, updated_at:
"All types should have created_at and updated_at, referencing last modification date and creation date of the type"
"These field should not be NULL"


- relationships:
"All FK should have the explaination of the relationship in the # RELATIONSHIPS section"

# GLOBAL RULES & CONVENTIONS *Mandatory*
- Naming: snake_case for table and column names.
- Primary keys: UUID (gen_random_uuid()) unless stated otherwise.
- Timestamps: `created_at` (DEFAULT now()), `updated_at` (updated via trigger or app).
- All foreign keys specify ON DELETE rules (CASCADE or SET NULL as needed).
- Use CHECK constraints & ENUMs to enforce business rules where possible.
- Sensitive fields (password_hash, tokens) never returned in queries by default.
- Join tables must include a surrogate primary key (UUID) and a UNIQUE constraint on their foreign key pairs.
- Foreign keys in join tables must have ON DELETE CASCADE to maintain referential integrity.
