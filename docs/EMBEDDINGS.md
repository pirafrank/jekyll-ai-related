# Embeddings and similarity search

This document describes the embedding pipeline and the Supabase data contract implemented by Jekyll AI Related.

## Model and vector shape

The plugin sends each post's rendered Jekyll content (`post.content`) to the OpenAI embeddings endpoint:

```http
POST https://api.openai.com/v1/embeddings
Authorization: Bearer $OPENAI_API_KEY
Content-Type: application/json
```

```json
{
  "model": "text-embedding-3-small",
  "input": "post content"
}
```

The first item in the API response is used as the vector. The bundled schema defines `embedding vector(1536)`, so the selected model must produce 1536-dimensional vectors. The code does not set an explicit OpenAI `dimensions` parameter, batch inputs, retry policy, timeout, or rate-limit handling.

Only `post.content` is embedded. Title, description, tags, categories, and other front matter are stored as metadata but are not concatenated into the embedding input unless they are already part of the post content.

## Supabase record

The default table is `page_embeddings` (or `page_embeddings_<JEKYLL_ENV>` when an environment is set). The bootstrap SQL creates:

| Column | Type | Meaning |
| --- | --- | --- |
| `id` | identity bigint | Database primary key |
| `uid` | `varchar(255)` unique | Configured post identifier, normally `slug` |
| `most_recent_edit` | timestamptz | Source post update value used for freshness checks |
| `content` | text | Post content sent to OpenAI |
| `embedding` | `vector(1536)` | OpenAI embedding |
| `metadata` | jsonb | Selected display and navigation metadata |
| `created_at` | timestamptz | Insert timestamp |

The metadata object is built from these post fields when present: `title`, `subtitle`, `description`, `date`, `slug`, `uid`, `url`, `categories`, `tags`, `updates`, and `most_recent_edit` (stored under the metadata key `last_edit`). Values that are `nil` are omitted. The configurable `post_updated_field` controls freshness, but it does not change which field the metadata builder reads for `last_edit`.

The plugin upserts with `on_conflict=uid`. Before the upsert it performs a GET for the same `uid`, selecting only `uid` and `most_recent_edit`. It writes when no row exists or when the source timestamp is newer than the stored timestamp.

## Similarity calculation

For a source post, the plugin retrieves its stored vector, then asks the configured Supabase RPC function to execute a query equivalent to:

```sql
select
  metadata->>'title' as title,
  uid,
  most_recent_edit,
  metadata->>'url' as url,
  metadata->>'date' as date,
  trunc((1 - (embedding <=> '<query-vector>'))::numeric, 3) as similarity
from page_embeddings
where uid != '<source-uid>'
  and 1 - (embedding <=> '<query-vector>') > 0.5
order by embedding <=> '<query-vector>'
limit 3;
```

`<=>` is pgvector's cosine distance operator. The plugin converts it to a similarity score with `1 - distance`, filters before returning rows, orders by smallest distance (highest similarity), and truncates the displayed score to the configured `precision`. The score is not rounded for filtering; the threshold comparison uses the calculated value.

The default `cosine_similarity(query text)` function is a thin PL/pgSQL `SECURITY DEFINER` wrapper that executes the supplied query and declares the result columns expected by the plugin. If `db_function` is customized, the replacement function must accept one `text` argument, execute the query, and return the same six columns in the same order and compatible types.

## Index and setup

`sql/supabase/create.sql`:

1. Enables the `vector` extension.
2. Creates `page_embeddings` with a 1536-dimensional vector column and unique `uid`.
3. Creates an IVFFlat index using cosine distance:

   ```sql
   create index page_embeddings_embedding_idx
   on page_embeddings
   using ivfflat (embedding vector_cosine_ops)
   with (lists = 100);
   ```

4. Creates the similarity RPC function.

For an environment suffix, create matching suffixed tables, indexes, and functions yourself. The plugin only changes the names it requests; it does not suffix or execute the SQL scripts dynamically. `drop.sql` is destructive for the default objects and should be used deliberately.

## Run behavior and cost

The command processes posts one at a time. For each included post it performs an OpenAI embedding request and then Supabase requests for freshness, possible upsert, vector retrieval, and related-post search. A normal rerun therefore still incurs embedding API calls for unchanged posts; only unchanged database rows avoid the upsert.

`--dry-run` skips the upsert and skips writing YAML, but it still performs embedding generation and related-post reads. A first dry run cannot populate an empty database, so a later non-dry run is required before similarity results can be complete.

If no source vector is found in Supabase, the lookup returns no vector and the subsequent similarity query cannot produce a meaningful result. In practice, run a non-dry command successfully against the intended table before relying on generated related-post files.

## Compatibility and maintenance notes

- Keep the database vector dimension aligned with the model response.
- Keep `post_updated_field` populated with a value comparable to the stored `timestamptz`; it controls whether a vector is refreshed.
- Changing the embedding model, embedding dimensions, or content normalization strategy requires rebuilding the stored vectors and updating the schema/index as appropriate.
- Changing the metadata fields or result shape requires updating both the Ruby consumer and the Supabase function return definition.
- The current SQL function executes query text supplied by the plugin. Restrict access to the RPC/database objects appropriately and do not expose the function as a general-purpose arbitrary SQL endpoint.
