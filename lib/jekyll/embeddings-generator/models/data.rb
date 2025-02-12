# frozen_string_literal: true

require_relative "metadata"

module Jekyll
  module EmbeddingsGenerator
    class Data
      include Jekyll::EmbeddingsGenerator

      attr_reader :uid, :most_recent_edit, :embedding, :metadata, :content

      def initialize(post, embedding, metadata)
        config = Jekyll::EmbeddingsGenerator.config
        @uid = post.data[config["uid"]]
        @most_recent_edit = post.data[config["mre"]]
        @embedding = embedding
        @metadata = metadata.to_h
        @content = post.content
      end

      def to_h
        {
          :uid              => @uid,
          :most_recent_edit => @most_recent_edit,
          :embedding        => @embedding,
          :metadata         => @metadata,
          :content          => @content,
        }.compact
      end
    end
  end
end
