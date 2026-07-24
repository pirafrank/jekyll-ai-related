# Troubleshooting

## Missing credential errors

Symptoms include `Missing OpenAI API key`, `Missing Supabase URL`, or `Missing Supabase key`.

Check that the variables are exported in the same shell or injected into the same CI step:

```sh
env | grep -E '^(OPENAI_API_KEY|SUPABASE_URL|SUPABASE_KEY)='
```

Do not print secret values in shared logs.

## OpenAI API errors

Use `--debug` and confirm the key has access to the embeddings endpoint. Check account limits, model availability, request size, and network access. The plugin sends one request per post and has no built-in retry or backoff.

## Supabase 404 or relation/function errors

Confirm the effective names. `JEKYLL_ENV=production` changes `page_embeddings` to `page_embeddings_production` and `cosine_similarity` to `cosine_similarity_production`. Create the suffixed objects or unset the environment variable when using the defaults.

## Vector dimension errors

The database expects `vector(1536)`. A model or request configuration producing another dimension cannot be inserted. Rebuild the schema and all stored vectors together when changing dimensions or models; see [Migrations](MIGRATIONS.md).

## No related posts

Check the following:

- The source post has a stored vector in the selected table.
- The database contains more than one eligible post.
- `related_posts_score_threshold` is not too high.
- `related_posts_limit` is greater than zero.
- The selected posts are not excluded as drafts or future posts.
- The RPC function returns the six columns expected by the plugin.

## Results are stale

Run the command again without `--dry-run`. Confirm that `post_updated_field` exists and is newer than the stored `most_recent_edit`. Remember that empty results do not remove an old YAML file, and deleted or renamed posts require manual generated-file cleanup.

## Custom unique or update fields do not work

The plugin calls `post.data[post_unique_field]` and `post.data[post_updated_field]`. Ensure those values are present after Jekyll plugins run. The command invokes `site.generate` before processing, which allows generator plugins to add fields.

## YAML is not written

Check for `--dry-run`, an empty result set, filesystem permissions, and the resolved `output_path`. The plugin creates the output directory but writes no file for an empty result.

## Debugging checklist

```sh
JEKYLL_ENV=development bundle exec jekyll related --dry-run --debug
```

Then inspect the selected table, the source `uid`, the stored vector, and the RPC response. Avoid enabling debug logging where it could expose sensitive request or response data.

