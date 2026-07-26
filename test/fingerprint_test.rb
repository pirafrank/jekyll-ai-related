# frozen_string_literal: true

require_relative "test_helper"

class FingerprintTest < Minitest::Test
  def test_same_model_and_content_produce_same_fingerprint
    first = Jekyll::EmbeddingsGenerator::Embeddings.fingerprint("same content")
    second = Jekyll::EmbeddingsGenerator::Embeddings.fingerprint("same content")

    assert_equal first, second
  end

  def test_different_content_produces_different_fingerprint
    first = Jekyll::EmbeddingsGenerator::Embeddings.fingerprint("first content")
    second = Jekyll::EmbeddingsGenerator::Embeddings.fingerprint("second content")

    refute_equal first, second
  end

  def test_fingerprint_uses_embedding_model_constant
    content = "cache key payload"
    expected = Digest::SHA256.hexdigest(
      "#{Jekyll::EmbeddingsGenerator::Embeddings::EMBEDDING_MODEL}\0#{content}"
    )

    assert_equal expected, Jekyll::EmbeddingsGenerator::Embeddings.fingerprint(content)
  end
end
