# Migrate

This file is the compatibility entry point for migration guidance. See the complete [migration and rebuild guide](docs/MIGRATIONS.md) for current procedures.

## From 0.1.0 to 0.2.0

The plugin now has a the following new configuration options:

| Option | Type | Description | Default Value |
| --- | --- | --- | --- |
| `precision` | integer | The number of decimal digits to round similarity scores to | `3` |
| `db_table` | string | The name of the table where the embeddings are stored | `page_embeddings` |
| `db_function` | string | The name of the function to calculate similarity scores | `cosine_similarity` |

You need to set these values in your `_config.yml` file if the defaults do not fit you.

If you are upgrading from `v0.1.0`, you need drop the data and re-run the plugin. You can find SQL scripts in the `sql\supabase` folder of this repository. This is due to a change in the handling of the similarity value. More details [here](https://github.com/pirafrank/jekyll-ai-related/blob/main/CHANGELOG.md).

### Environments support

This version also introduced environment-specific table and function names through `JEKYLL_ENV`. See the [environment migration guidance](docs/MIGRATIONS.md#environment-migration) for setup and safety details.
