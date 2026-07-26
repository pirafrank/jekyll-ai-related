# Configuration reference

Configuration is read from the `jekyll-ai-related` section of `_config.yml`.

```yaml
jekyll-ai-related:
  post_unique_field: slug
  post_updated_field: date
  output_path: related_posts
  include_drafts: false
  include_future: false
  related_posts_limit: 3
  related_posts_score_threshold: 0.5
  precision: 3
  db_table: page_embeddings
  db_function: cosine_similarity
```

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `post_unique_field` | string | `slug` | Post field used as the database `uid` and output filename key. |
| `post_updated_field` | string | `date` | Post field compared with the stored `most_recent_edit`. |
| `output_path` | string | `related_posts` | Directory under `_data` for generated YAML. |
| `include_drafts` | boolean | `false` | Include drafts when building the processing site. |
| `include_future` | boolean | `false` | Include future-dated posts. |
| `related_posts_limit` | integer | `3` | Maximum number of results per source post. |
| `related_posts_score_threshold` | number | `0.5` | Minimum cosine similarity. |
| `precision` | integer | `3` | Decimal places used in returned similarity values. |
| `db_table` | string | `page_embeddings` | Supabase table containing vectors. |
| `db_function` | string | `cosine_similarity` | Supabase RPC function used for the search. |

> [!NOTE]
> `related_posts_limit` and `related_posts_score_threshold` work together: the plugin returns up to `related_posts_limit` posts whose similarity is greater than `related_posts_score_threshold`. A post can have no qualifying related posts, and the threshold can result in fewer results than the limit.

CLI flags are invocation-level overrides for drafts, future posts, and dry run:

```text
--drafts       include drafts
--future       include future posts
--dry-run      skip database updates and file writes
--debug        enable debug logging
--quiet        suppress info logging
```

For drafts and future posts, a true value in `_config.yml` or the corresponding CLI flag enables inclusion. `--dry-run` is not an offline mode.

## Environment naming

If `JEKYLL_ENV` is set, its value is appended to both database names:

```sh
JEKYLL_ENV=production
```

With the defaults, the plugin uses `page_embeddings_production` and `cosine_similarity_production`. The suffixed objects must already exist.

## Credentials

Credentials are not Jekyll configuration values. They are required environment variables:

- `OPENAI_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_KEY`

Missing credentials stop configuration validation before processing posts.

## Precedence and important behavior

Configuration values come from `_config.yml` and defaults; CLI flags can enable drafts, future posts, and dry run for the current command. `post_unique_field` and `post_updated_field` must exist on every processed post. The plugin computes a content fingerprint before calling OpenAI and reuses stored vectors when the fingerprint matches. Metadata-only changes still trigger a database upsert when the configured update timestamp is newer than the stored value.

## Advanced custom fields

Sites can use custom post metadata for identity and freshness. For example, a plugin that adds a unique `uid` and a `most_recent_edit` field can use:

```yaml
jekyll-ai-related:
  post_unique_field: uid
  post_updated_field: most_recent_edit
```

The fields must be available on the post after Jekyll's generators have run. `uid` must be unique across the configured Supabase table, and `most_recent_edit` must be comparable with the stored timestamp.
