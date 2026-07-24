# Security

## Secrets

The plugin reads credentials from:

- `OPENAI_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_KEY`

Use environment variables or a secret manager. Never place keys in `_config.yml`, source files, generated YAML, commit history, or debug output. Rotate a key immediately if it is exposed.

## Supabase permissions

Grant the configured key only the operations required by the workflow: read and upsert the selected embedding table and execute the similarity function. Use separate projects or tables for development and production.

The plugin sends the Supabase key as both `apikey` and bearer `Authorization` headers. Treat it as a credential, regardless of whether the project calls it an anon or service key.

## Dynamic SQL function

The bundled `cosine_similarity` function is `SECURITY DEFINER` and executes a query string passed by the plugin. This is powerful and must not be exposed as a general-purpose SQL endpoint to untrusted callers. Review:

- who owns the function;
- who has `EXECUTE` permission;
- the function `search_path` and referenced objects;
- whether the endpoint is reachable with a low-privilege public key;
- whether a safer fixed query or parameterized function is appropriate for your deployment.

Table and function names are also assembled into request URLs and SQL. Keep them controlled by trusted configuration.

## Content privacy

The full `post.content` is sent to OpenAI and stored in Supabase alongside its embedding. Do not process confidential content unless your data-processing requirements, provider agreements, retention settings, and access controls permit it.

## Logs and generated data

Debug logs may include HTTP response bodies and configuration details. Restrict log access and avoid debug mode in shared production logs. Generated YAML contains post metadata and URLs and should be handled according to the site's content classification.

