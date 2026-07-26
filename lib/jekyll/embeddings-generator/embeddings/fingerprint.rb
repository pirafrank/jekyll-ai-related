# frozen_string_literal: true

require "digest"

module Jekyll
  module EmbeddingsGenerator
    module Embeddings
      EMBEDDING_MODEL = "text-embedding-3-small"

      class << self
        def fingerprint(content)
          payload = "#{EMBEDDING_MODEL}\0#{content}"
          Digest::SHA256.hexdigest(payload)
        end
      end
    end
  end
end
