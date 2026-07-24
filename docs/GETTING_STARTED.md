# Getting started

## Requirements

- Ruby `>= 3.2`.
- Jekyll `>= 3.7` and `< 5.0`.
- An OpenAI API key.
- A Supabase project with the pgvector extension available.
- A site with posts containing a unique identifier, normally `slug`.

## Install

Add the gem to the Jekyll site's `Gemfile`:

```ruby
group :jekyll_plugins do
  gem "jekyll-ai-related"
end
```

Then run:

```sh
bundle install
```

## Create the database objects

Run [`sql/supabase/create.sql`](../sql/supabase/create.sql) in the Supabase SQL editor. The default objects are:

- table: `page_embeddings`
- RPC function: `cosine_similarity`
- vector dimension: `1536`

See [Supabase setup](SUPABASE.md) before using production data or environment suffixes.

## Set credentials

Set these variables in the shell or CI secret store:

```sh
export OPENAI_API_KEY="..."
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_KEY="..."
```

Do not commit these values.

## Configure and run

The defaults work with the bundled SQL:

```sh
bundle exec jekyll related
```

A useful first validation is:

```sh
bundle exec jekyll related --dry-run --debug
```

Dry-run mode still calls OpenAI and reads Supabase, but does not update the database or write files. Run without `--dry-run` to populate the database and generate output.

## Use the output

The default output for a post with slug `my-post` is:

```text
_data/related_posts/my-post.yml
```

Jekyll exposes it as `site.data.related_posts[page.slug]`. See [Integration](INTEGRATION.md) for a complete Liquid example.

