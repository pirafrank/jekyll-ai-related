-- Add embedding_fingerprint to existing page_embeddings tables.
-- Run once per table (including environment-suffixed tables such as page_embeddings_production).

alter table page_embeddings
add column if not exists embedding_fingerprint text;

-- Existing rows keep a null fingerprint and are re-embedded on the next non-dry run.
