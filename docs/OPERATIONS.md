# Operations

## Recommended workflow

Run the command after adding or editing posts:

```sh
bundle exec jekyll related
bundle exec jekyll build
```

Review the generated `_data/<output_path>` files and commit them if generated data is part of the site's source workflow.

> [!IMPORTANT]
> Re-run the plugin whenever you add or update posts to refresh the related-post lists. The timestamp comparison prevents unchanged rows from being upserted, but the current implementation still generates an OpenAI embedding for every included post on each run.

## Dry runs

```sh
bundle exec jekyll related --dry-run --debug
```

Dry run skips database upserts and YAML writes. It still builds the Jekyll site, may call OpenAI for cache misses, checks Supabase, and performs similarity reads. It cannot populate a new database.

## CI/CD

Store the three credentials as CI secrets. Set `JEKYLL_ENV` explicitly in deployments, especially when production and development tables coexist:

```sh
JEKYLL_ENV=production bundle exec jekyll related
```

A CI job should fail on command errors, preserve or publish generated `_data` files, and run the regular Jekyll build afterward. The repository does not provide a CI workflow for site consumers, so the exact job configuration is site-specific.

## Cost and runtime

Processing is sequential. OpenAI is called only on cache misses: new posts, edited content, legacy rows without a fingerprint, or after an embedding model change. Supabase reads and similarity searches still run for every included post. The timestamp comparison still controls metadata-only upserts when content is unchanged.

The code has no explicit retry or timeout policy. If a request fails, investigate the error and rerun the command; partial database updates may already have occurred.

## Generated files

Files are written under `_data/<output_path>` and existing files for a post are overwritten. Empty search results do not delete old files. Decide whether your project commits these files or generates them in CI, and add cleanup for deleted posts or changed identifiers if necessary.

## Environment isolation

Use distinct table and RPC names for development, CI, staging, and production. Verify the effective environment in command logs before running a write-enabled command.
