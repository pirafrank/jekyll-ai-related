# frozen_string_literal: true

require_relative "metadata"

module Jekyll
  module EmbeddingsGenerator
    class Data
      include Jekyll::EmbeddingsGenerator

      attr_reader :uid, :most_recent_edit, :embedding, :metadata, :content, :embedding_fingerprint

      def initialize(post, embedding, metadata, embedding_fingerprint = nil)
        config = Jekyll::EmbeddingsGenerator.config
        @uid = post.data[config["uid"]]
        @most_recent_edit = post.data[config["mre"]]
        @embedding = embedding
        @metadata = metadata.to_h
        @content = post.content
        @embedding_fingerprint = embedding_fingerprint
      end

      def to_h
        {
          :uid                   => @uid,
          :most_recent_edit      => @most_recent_edit,
          :embedding             => @embedding,
          :embedding_fingerprint => @embedding_fingerprint,
          :metadata              => @metadata,
          :content               => @content,
        }.compact
      end
    end
  end
end
