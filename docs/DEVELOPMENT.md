# Development

## Local setup

The repository is a Ruby gem. Install dependencies with:

```sh
bundle install
```

The implementation is under `lib/jekyll`; Supabase SQL is under `sql/supabase`.

## Main code paths

- `lib/jekyll/commands/generator.rb` registers `jekyll related`.
- `lib/jekyll/processor.rb` coordinates processing.
- `lib/jekyll/embeddings-generator/init.rb` builds configuration and the Jekyll site.
- `lib/jekyll/embeddings-generator/embeddings/fingerprint.rb` computes model/content cache keys.
- `lib/jekyll/embeddings-generator/embeddings/generate.rb` calls OpenAI.
- `lib/jekyll/embeddings-generator/embeddings/store.rb` calls Supabase.
- `lib/jekyll/embeddings-generator/models/` defines payload and metadata objects.

## Checks

Run the test suite:

```sh
bundle exec rake test
```

Run RuboCop through the Rake task:

```sh
bundle exec rake lint
```

Build the gem with:

```sh
bundle exec rake build
```

Changes to API payloads, SQL, configuration, or output should also be validated against a disposable Jekyll site and isolated Supabase objects.

## Safe manual validation

1. Set development-only OpenAI and Supabase credentials.
2. Set `JEKYLL_ENV=development`.
3. Run `bundle exec jekyll related --dry-run --debug`.
4. Run without dry run against the development table.
5. Inspect the generated YAML and run `bundle exec jekyll build`.

## Release

The version is defined in `lib/jekyll/embeddings-generator/version.rb`. The Rakefile provides gem build and publish tasks. The release workflow creates a GitHub release when a `v*.*.*` tag is pushed. Review `CHANGELOG.md` and `MIGRATE.md` for breaking changes before tagging.

Avoid committing credentials, generated local artifacts, or changes to unrelated user work.
