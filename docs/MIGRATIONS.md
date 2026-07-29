# Migrations and rebuilds

## From 0.2.x to 0.3.0

Version 0.3.0 adds content-based embedding caching. It introduces the `embedding_fingerprint` column and changes processing so unchanged posts reuse their stored vectors instead of making another OpenAI request. Supabase reads and similarity searches still run for every included post.

### Database migration

Fresh installations created with [`sql/supabase/create.sql`](../sql/supabase/create.sql) already include the new column. Existing installations must apply [`sql/supabase/migrations/v0.3.0/001_migrate_add_embedding_fingerprint.sql`](../sql/supabase/migrations/v0.3.0/001_migrate_add_embedding_fingerprint.sql) before running v0.3.0:

1. Back up or verify the target Supabase table.
2. Run the migration against the default `page_embeddings` table.
3. For each environment-suffixed table, such as `page_embeddings_production`, change the table name in the migration and run it separately.
4. Deploy or install v0.3.0.
5. Run `bundle exec jekyll related` without `--dry-run` for each environment so existing rows can be backfilled.

The migration is additive and safe to run with `if not exists`. It does not populate fingerprints. Existing rows retain a null fingerprint and are re-embedded once, then stored with a fingerprint, the next time they are processed by a write-enabled run. A dry run does not backfill the column.

### Runtime and cost changes

The cost saving is specifically on OpenAI embedding requests. Before v0.3.0, every included post made an embedding request on every `jekyll related` run. With v0.3.0, a post with unchanged rendered content and the same embedding model reuses its stored vector, so it makes no OpenAI request on later runs. For example, rerunning a site whose 100 posts are all unchanged avoids 100 embedding requests.

- New posts, changed rendered content, legacy rows with a null fingerprint, and model changes still call OpenAI.
- Metadata-only changes still upsert when `post_updated_field` is newer, while reusing the existing vector and avoiding an OpenAI request.
- Supabase reads, upserts when needed, vector retrieval, and similarity searches still run for included posts. v0.3.0 does not eliminate those database or network costs.
- The first write-enabled run after the migration re-embeds legacy rows once, so OpenAI usage may temporarily increase before subsequent runs become cheaper.
- Dry runs do not persist fingerprints. A dry run may call OpenAI for cache misses again on a later dry run; use a write-enabled run to establish the cache.
- If a post has no stored vector, related-post generation returns no similarity results until a non-dry run stores one.
- A full re-embedding is not required for this release unless you also change the embedding model, vector dimensions, or content preprocessing.

Rolling back to a pre-0.3.0 plugin does not require removing the column; older versions ignore it. Reapplying v0.3.0 still requires the column to exist.

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
