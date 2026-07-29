# Architecture

Jekyll AI Related is a Ruby gem that adds the `jekyll related` command to Jekyll. The command reads the site's posts, reuses cached embeddings when possible or generates them through OpenAI, stores vectors and post metadata in Supabase/Postgres, performs a similarity search, and writes the resulting related-post lists into the site's `_data` directory.

The generated YAML is deliberately local to the site. A normal `jekyll build` can therefore consume related-post data without calling OpenAI or Supabase; the command is run separately when content changes.

## System boundary

```text
Jekyll site                         External services                 Generated site data
-----------                         ------------------                 -------------------
posts + front matter
        |
        v
`jekyll related` --> OpenAI embeddings API
        |                    |
        |                    v
        +------------> Supabase REST API
                         (Postgres + pgvector)
                                |
                                v
                         similarity results
                                |
                                v
                         `_data/<path>/*.yml`
                                |
                                v
                 normal Jekyll templates / `site.data`
```

The repository contains the gem code under `lib/`, the Supabase bootstrap SQL under `sql/supabase/`, and packaging/release configuration. There are no application controllers, web server, runtime database connections, or test suite in this repository; the plugin runs as a batch command during content maintenance.

## Runtime components

- `lib/jekyll-ai-related.rb` loads Jekyll and the processor.
- `lib/jekyll/commands/generator.rb` registers the `related` Jekyll command and translates CLI flags into options.
- `lib/jekyll/embeddings-generator/init.rb` builds and validates configuration, then creates and reads a Jekyll site. `site.generate` is called so other Jekyll generator plugins can enrich post data before processing.
- `lib/jekyll/processor.rb` coordinates the two phases: embedding persistence and related-post generation.
- `embeddings/generate.rb` calls `https://api.openai.com/v1/embeddings` using the `text-embedding-3-small` model.
- `embeddings/store.rb` communicates with Supabase using its REST/PostgREST endpoints. It handles existence checks, upserts, vector retrieval, and the similarity RPC call.
- `models/data.rb` creates the database payload. `models/metadata.rb` creates the JSON metadata stored beside each vector.
- `sql/supabase/create.sql` enables pgvector, creates the table and IVFFlat cosine index, and defines the stored procedure used by the plugin.

## Command lifecycle

1. Jekyll loads the gem and exposes `bundle exec jekyll related`.
2. The command combines `_config.yml`, CLI flags, environment variables, and defaults. It validates `OPENAI_API_KEY`, `SUPABASE_URL`, and `SUPABASE_KEY`.
3. A fresh Jekyll site is built with the configured draft and future-post settings. The site is read and generators are run.
4. For every included post, the plugin extracts `post.content` and metadata, computes a model/content fingerprint, and fetches the existing Supabase record.
5. The plugin reuses the stored embedding when the fingerprint and vector are present; otherwise it calls OpenAI. It upserts when the row is missing, the fingerprint changed, or the configured update value is newer.
6. For every included post, it fetches that post's stored embedding and submits a SQL query through the configured Supabase RPC function. The query excludes the current post, applies the score threshold, sorts by cosine distance, and limits the result count.
7. Non-empty results are serialized as YAML to `_data/<output_path>/<safe-uid>.yml`. Existing files for the same post are overwritten; an empty result does not remove an older file.

The two phases are sequential. If related-post lookup fails for one post, the error is logged and processing continues with the next post.

## Configuration and naming

The `jekyll-ai-related` section of `_config.yml` supports:

| Setting | Default | Role |
| --- | --- | --- |
| `post_unique_field` | `slug` | Post field used as the database `uid` and output filename key |
| `post_updated_field` | `date` | Post field used for update comparison |
| `output_path` | `related_posts` | Subdirectory under `_data` |
| `include_drafts` | `false` | Include drafts in the generated Jekyll site |
| `include_future` | `false` | Include future-dated posts |
| `related_posts_limit` | `3` | Maximum result count per post |
| `related_posts_score_threshold` | `0.5` | Minimum cosine similarity |
| `precision` | `3` | Decimal places used for returned similarity values |
| `db_table` | `page_embeddings` | Supabase table name |
| `db_function` | `cosine_similarity` | Supabase RPC function name |

`JEKYLL_ENV`, when present, is appended to both database names with an underscore. For example, `JEKYLL_ENV=production` changes the defaults to `page_embeddings_production` and `cosine_similarity_production`. The corresponding objects must exist in Supabase; the plugin does not create environment-specific objects automatically.

CLI flags can enable drafts, future posts, and dry-run mode for a single invocation. `--debug` and `--quiet` adjust Jekyll logging.

## Output contract

For the default configuration, a post with slug `my-post` produces:

```text
_data/related_posts/my-post.yml
```

The YAML value is an array of result objects returned by Supabase. Each result contains `title`, `uid`, `most_recent_edit`, `url`, `date`, and a rounded `similarity` value. Templates access it as `site.data.related_posts[page.slug]`.

The filename is lowercased and every character outside `[a-z0-9-_]` is replaced by `-`. The database lookup still uses the original configured post value, so the filename is only a filesystem-safe representation.

## Operational characteristics

- API keys are read only from environment variables and are sent in the OpenAI and Supabase HTTP headers.
- The command is not part of the normal build path. Keep generated `_data` files available to the site build, and schedule `jekyll related` after creating or editing posts.
- OpenAI is called only for cache misses: new posts, changed rendered content, legacy rows without a fingerprint, or after an embedding model change. Supabase reads and similarity searches still run for every included post.
- `--dry-run` still reads from both services and may generate embeddings for cache misses; it skips Supabase updates and local file writes. It is therefore useful for exercising the flow, but it is not an offline mode.
- The included SQL uses an IVFFlat index with `vector_cosine_ops` and `lists = 100`. The vector dimension must remain compatible with the selected OpenAI model and the table definition.
- The plugin uses raw SQL text assembled in Ruby and executes it through a `SECURITY DEFINER` PostgreSQL function. Table/function names and the SQL setup should be treated as trusted deployment configuration.
