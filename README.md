# Jekyll AI Related

[![Gem Version](https://badge.fury.io/rb/jekyll-ai-related.svg)](https://badge.fury.io/rb/jekyll-ai-related)

A [Jekyll](https://jekyllrb.com/) [command](https://jekyllrb.com/docs/plugins/commands/) plugin to generate list of related posts using AI.

The plugin uses uses OpenAI API to generate embeddings from posts content, and stores them on Supabase vector database. A query on Supabase provides a similarity score between the post and all other posts on the site. The plugin then selects the most similar posts to generate the list of related posts.

To avoid unnecessary API calls or slowing down the website generation, the plugin stores the list of related posts in the site's `_data` folder. This way you can `jekyll build` without calling the plugin or making API calls, while still having the list of related posts available as site data.

## Getting started

1. Setup Supabase
2. Install the plugin
3. Configure the plugin
4. Run the plugin

## Requirements

- OpenAI account and API key
- Supabase account and API key
- Supabase URL of the project where the DB is located

### Supabase setup

Use the `create.sql` script in the `sql\supabase` folder of this repo to create the required table and functions on your Supabase project. You can run the script in the SQL editor of the Supabase dashboard.

You can always revert the changes by running the `drop.sql` script.

## Installation

1. Add the plugin to you Jekyll site's `Gemfile` in the `:jekyll_plugins` group:

```Gemfile
gem 'jekyll-ai-related', git: 'https://github.com/pirafrank/jekyll-ai-related', branch: 'main'
```

2. Run `bundle install`

### Update

```sh
bundle update jekyll-ai-related
```

## Configuration

Sample configuration to add to your `_config.yml`:

```yaml
jekyll-ai-related:
  post_unique_field: slug
  post_updated_field: date
  output_path: related_posts
  include_drafts: false
  include_future: false
  related_posts_limit: 3
  related_posts_score_threshold: 0.5
```

Configuration is optional. The plugin will use the default values if not provided.

### Configuration options

| Option | Type | Description | Default Value |
| --- | --- | --- | --- |
| `post_unique_field` | string | A field that uniquely identifies a post | `slug` |
| `post_updated_field` | string | A field that indicates when the post was last updated | `date` |
| `output_path` | string | The subdir inside `_data` where related posts will be stored | `related_posts` |
| `include_drafts` | boolean | Whether to include drafts in the list of related posts | `false` |
| `include_future` | boolean | Whether to include future posts in the list of related posts | `false` |
| `related_posts_limit` | integer | The maximum number of related posts to extract per post | `3` |
| `related_posts_score_threshold` | float | The minimum similarity score to consider a post related | `0.5` |

**Note**: `related_posts_limit` and `related_posts_score_threshold` are used to filter the list of related posts. The plugin will return the top `related_posts_limit` posts with a similarity score greater than `related_posts_score_threshold`. A post may have 0 or more than `related_posts_limit` related posts, but only the top `related_posts_limit` will be returned, if any.

### Advanced configuration

You can customize the unique and updated fields, for example if you have a plugin that generates a unique ID for each post, or if you have a custom field that indicates when the post was last updated.

Check the [post-metadata.rb](https://github.com/pirafrank/fpiracom/blob/8cc17a5801a73f7c8cbad4cbee099db18389b187/_plugins/post-metadata.rb) plugin of mine for an example. You can download and place it in your `_plugins` folder. It will add metadata to each `post` object and makes it accessible anywhere the `post` object is.

If you do so, you could use the following configuration:

```yaml
jekyll-ai-related:
  post_unique_field: uid
  post_updated_field: most_recent_edit
```

## Usage

To run, the plugin needs the OpenAI and Supabase API keys, and Supabase URL. The plugin expects them as environment variables.

```sh
export OPENAI_API_KEY="your_openai_api_key"
export SUPABASE_URL="your_supabase_url"
export SUPABASE_KEY="your_supabase_api_key"
```

Never write API keys in your code or configuration files you commit.

Then you can run the plugin with:

```txt
bundle exec jekyll related
```

## Development

Clone and run `bundle install` to get started.

Code lives in `lib/jekyll` directory. `lib/jekyll/commands/generator.rb` is the entry point of the plugin, as per Jekyll documentation. More details [here](https://jekyllrb.com/docs/plugins/commands/).

## Contributing

[Bug reports](https://github.com/pirafrank/jekyll-ai-related/issues) and [pull requests](https://github.com/pirafrank/jekyll-ai-related/pulls) are welcome on GitHub.

## Code of Conduct

Everyone interacting in the project's codebase, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/pirafrank/jekyll-ai-related/blob/main/CODE_OF_CONDUCT.md).

## Guarantee

This plugin is provided as is, without any guarantee. Use at your own risk.

## Disclaimer

This plugin uses OpenAI API and Supabase, and you are responsible for complying with their respective terms of service. This plugin is not affiliated with OpenAI or Supabase.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
