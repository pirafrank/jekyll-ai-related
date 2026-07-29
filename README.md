# Jekyll AI Related

[![Gem Version](https://img.shields.io/gem/v/jekyll-ai-related)](https://rubygems.org/gems/jekyll-ai-related)
[![GitHub Release](https://img.shields.io/github/v/release/pirafrank/jekyll-ai-related)](https://github.com/pirafrank/jekyll-ai-related/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A [Jekyll](https://jekyllrb.com/) command plugin that uses OpenAI embeddings and Supabase/pgvector to generate related-post data for your blog.

The plugin writes related-post results to `_data`, so normal `jekyll build` runs do not call OpenAI or Supabase. Run `jekyll related` when posts are added or changed, or run it in your CI pipeline.

## Quick start

### Requirements

- Ruby `>= 3.2`
- Jekyll `>= 3.7` and `< 5.0`
- An OpenAI API key
- A Supabase project with pgvector available

### 1. Create the database objects

Run [`sql/supabase/create.sql`](sql/supabase/create.sql) in the Supabase SQL editor. This creates the default `page_embeddings` table and `cosine_similarity` function.

For existing installations, follow the [migration guide](docs/MIGRATIONS.md), especially the v0.3.0 `embedding_fingerprint` column migration. See [Supabase setup](docs/SUPABASE.md) for environment-specific tables and maintenance.

### 2. Install the plugin

Add the gem to the Jekyll site's `Gemfile`:

```ruby
group :jekyll_plugins do
  gem "jekyll-ai-related"
end
```

Then install it:

```sh
bundle install
```

To use the unreleased `main` branch instead:

```ruby
group :jekyll_plugins do
  gem "jekyll-ai-related", git: "https://github.com/pirafrank/jekyll-ai-related", branch: "main"
end
```

### 3. Configure the site

Add the plugin configuration to `_config.yml`:

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

These defaults are optional. Set the required credentials in the environment:

```sh
export OPENAI_API_KEY="your_openai_api_key"
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_KEY="your_supabase_api_key"
```

Never commit API keys. See the [configuration reference](docs/CONFIGURATION.md) for all settings and custom post fields.

### 4. Generate related posts

```sh
bundle exec jekyll related
```

A useful validation run is:

```sh
bundle exec jekyll related --dry-run --debug
```

Dry-run mode does not update Supabase or write YAML files, but it may call OpenAI for cache misses. Use a normal run to populate the database and generate output.

Generated data is written under `_data/related_posts/`, for example:

```text
_data/related_posts/my-post.yml
```

See the [integration guide](docs/INTEGRATION.md) for using the data in Liquid templates.

## Environments

Set `JEKYLL_ENV` to isolate development, staging, and production data:

```sh
JEKYLL_ENV=production bundle exec jekyll related
```

The environment suffix is appended to the configured table and RPC function names, so the corresponding Supabase objects must already exist. See [Supabase setup](docs/SUPABASE.md) for details.

## Documentation

The [documentation index](docs/README.md) groups the complete guides by setup, operation, implementation, and development.

- [Getting started](docs/GETTING_STARTED.md)
- [Configuration](docs/CONFIGURATION.md)
- [Migrations](docs/MIGRATIONS.md)
- [Workflow and operations](docs/WORKFLOW.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Architecture and embeddings](docs/ARCHITECTURE.md), [embedding details](docs/EMBEDDINGS.md)
- [Development](docs/DEVELOPMENT.md)
- [Security](docs/SECURITY.md)

## Development

```sh
bundle install
bundle exec rake test
bundle exec rake lint
bundle exec rake build
```

See [Development](docs/DEVELOPMENT.md) for the repository layout, validation workflow, and release process.

## Contributing and license

[Bug reports](https://github.com/pirafrank/jekyll-ai-related/issues) and [pull requests](https://github.com/pirafrank/jekyll-ai-related/pulls) are welcome. The project is available under the [MIT License](https://opensource.org/licenses/MIT).

This plugin uses OpenAI and Supabase services. Users are responsible for complying with their respective terms of service. The plugin is not affiliated with either service.
