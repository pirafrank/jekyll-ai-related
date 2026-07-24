# Supabase setup and maintenance

## Default schema

Run [`sql/supabase/create.sql`](../sql/supabase/create.sql) in the Supabase SQL editor. It:

1. Enables the `vector` extension.
2. Creates `page_embeddings`.
3. Adds a unique constraint on `uid`.
4. Adds an IVFFlat index using cosine distance.
5. Creates the `cosine_similarity(text)` RPC function.

The table stores `vector(1536)`, matching the current `text-embedding-3-small` response used by the code.

## Required API behavior

The plugin uses Supabase REST endpoints, not a native database driver:

- `GET /rest/v1/<table>` checks freshness and retrieves a vector.
- `POST /rest/v1/<table>?on_conflict=uid` performs an upsert.
- `POST /rest/v1/rpc/<function>` executes the similarity query.

The configured key must be authorized to perform these operations. The URL should be the project URL, for example `https://project-ref.supabase.co`.

## Environment-specific objects

`JEKYLL_ENV` changes names only; it does not create objects. For `production`, create a complete matching set such as:

```text
page_embeddings_production
page_embeddings_production_embedding_idx
cosine_similarity_production(text)
```

Copy and adapt the SQL before running it. Keep development and production credentials and table names separate.

## Index considerations

The supplied schema uses:

```sql
using ivfflat (embedding vector_cosine_ops)
with (lists = 100)
```

The index is appropriate for the repository's cosine-distance query, but index sizing and refresh strategy may need adjustment for a substantially larger corpus. The query also filters out the source `uid`, applies the configured threshold, orders by distance, and applies the configured limit.

## Cleanup and rebuild

[`drop.sql`](../sql/supabase/drop.sql) removes the default index, function, and table. It does not target suffixed environment objects. Treat it as destructive and verify the exact environment before running it.

To rebuild vectors safely, create or select an isolated table, run the plugin without dry run, validate the results, then switch `db_table`/`JEKYLL_ENV` when ready.

## Security note

The default RPC function is `SECURITY DEFINER` and executes query text supplied by the plugin. Review ownership, execute grants, search path, and exposure before using it in a shared or untrusted Supabase project. See [Security](SECURITY.md).

