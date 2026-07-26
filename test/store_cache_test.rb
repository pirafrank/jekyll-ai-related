# frozen_string_literal: true

require_relative "test_helper"

class StoreCacheTest < Minitest::Test
  def setup
    Jekyll::EmbeddingsGenerator::TestHelpers.stub_config
  end

  def test_cache_hit_when_fingerprint_and_embedding_match
    fingerprint = Jekyll::EmbeddingsGenerator::Embeddings.fingerprint("unchanged")
    existing = {
      "embedding_fingerprint" => fingerprint,
      "embedding"             => [0.1, 0.2],
    }

    assert Jekyll::EmbeddingsGenerator::Store.cache_hit?(existing, fingerprint)
  end

  def test_cache_miss_for_legacy_rows_without_fingerprint
    existing = {
      "embedding_fingerprint" => nil,
      "embedding"             => [0.1, 0.2],
    }
    fingerprint = Jekyll::EmbeddingsGenerator::Embeddings.fingerprint("unchanged")

    refute Jekyll::EmbeddingsGenerator::Store.cache_hit?(existing, fingerprint)
  end

  def test_cache_miss_when_content_changed
    existing = {
      "embedding_fingerprint" => Jekyll::EmbeddingsGenerator::Embeddings.fingerprint("old"),
      "embedding"             => [0.1, 0.2],
    }
    fingerprint = Jekyll::EmbeddingsGenerator::Embeddings.fingerprint("new")

    refute Jekyll::EmbeddingsGenerator::Store.cache_hit?(existing, fingerprint)
  end

  def test_should_upsert_for_new_posts
    data = build_data("new-post", "content", Time.utc(2025, 1, 2))

    assert Jekyll::EmbeddingsGenerator::Store.should_upsert?(data, nil)
  end

  def test_should_not_upsert_for_unchanged_posts
    content = "unchanged"
    fingerprint = Jekyll::EmbeddingsGenerator::Embeddings.fingerprint(content)
    timestamp = Time.utc(2025, 1, 2)
    data = build_data("unchanged-post", content, timestamp)
    existing = {
      "embedding_fingerprint" => fingerprint,
      "most_recent_edit"      => timestamp.iso8601,
    }

    refute Jekyll::EmbeddingsGenerator::Store.should_upsert?(data, existing)
  end

  def test_should_upsert_for_metadata_only_changes
    content = "unchanged"
    fingerprint = Jekyll::EmbeddingsGenerator::Embeddings.fingerprint(content)
    data = build_data("metadata-post", content, Time.utc(2025, 2, 1))
    existing = {
      "embedding_fingerprint" => fingerprint,
      "most_recent_edit"      => Time.utc(2025, 1, 1).iso8601,
    }

    assert Jekyll::EmbeddingsGenerator::Store.should_upsert?(data, existing)
  end

  def test_should_upsert_when_fingerprint_changes
    data = build_data("edited-post", "new content", Time.utc(2025, 1, 1))
    existing = {
      "embedding_fingerprint" => Jekyll::EmbeddingsGenerator::Embeddings.fingerprint("old content"),
      "most_recent_edit"      => Time.utc(2025, 1, 1).iso8601,
    }

    assert Jekyll::EmbeddingsGenerator::Store.should_upsert?(data, existing)
  end

  private

  def build_data(slug, content, date)
    post = Jekyll::EmbeddingsGenerator::TestHelpers.build_post(
      slug:,
      content:,
      date:
    )
    fingerprint = Jekyll::EmbeddingsGenerator::Embeddings.fingerprint(content)
    metadata = Jekyll::EmbeddingsGenerator::Metadata.new(post)

    Jekyll::EmbeddingsGenerator::Data.new(post, [0.1], metadata, fingerprint)
  end
end
