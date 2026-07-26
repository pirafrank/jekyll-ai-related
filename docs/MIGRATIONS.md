# Migrations and rebuilds

## Adding embedding fingerprint cache (0.2.2+)

Run [`sql/supabase/migrate_add_embedding_fingerprint.sql`](../sql/supabase/migrate_add_embedding_fingerprint.sql) on every `page_embeddings` table you use, including environment-suffixed tables such as `page_embeddings_production`.

Existing rows keep a null `embedding_fingerprint` and are re-embedded once on the next write-enabled run. After that, unchanged posts skip OpenAI calls. No full table rebuild is required unless you also change the embedding model or dimensions.

## From 0.1.0 to 0.2.0

Version 0.2.0 introduced `precision`, configurable `db_table` and `db_function`, and environment suffixes. Follow [`MIGRATE.md`](../MIGRATE.md) for the project migration notes.

The 0.2.0 similarity handling changed stored/query behavior. Drop the old objects, recreate the schema, and run the plugin again when upgrading from 0.1.0.

## Changing the embedding model or dimensions

Vectors from incompatible models or dimensions cannot safely share one vector column. Use this sequence:

1. Create a new table with the required vector dimension and cosine index.
2. Create a matching RPC function with the expected return columns.
3. Point the plugin at the new table/function, preferably using a separate `JEKYLL_ENV`.
4. Run without `--dry-run` to populate every included post.
5. Validate related results and switch the site to the new names.
6. Retire the old objects only after rollback is no longer needed.

## Changing content input

The current vector input is `post.content`. If preprocessing changes, treat all existing embeddings as stale and rebuild them; timestamp comparison alone cannot detect a change in the preprocessing algorithm.

## Changing unique identifiers

Changing `post_unique_field` creates a new identity space. Existing rows and YAML files keyed by the old identifier are not automatically migrated or deleted. Plan a cleanup or table rebuild, and verify links in templates.

## Changing metadata or result shape

The Ruby query expects these result columns in order: `title`, `uid`, `most_recent_edit`, `url`, `date`, and `similarity`. Update the SQL function return type and the consumer together, then test generated YAML and Liquid templates.

## Environment migration

When introducing `JEKYLL_ENV`, provision the suffixed table, index, and RPC function first. Run a full write-enabled generation against that environment before changing production consumers. Always set `JEKYLL_ENV` explicitly in automation to avoid writing to an unintended default table.

