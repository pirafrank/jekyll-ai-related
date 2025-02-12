# frozen_string_literal: true

module Jekyll
  module EmbeddingsGenerator
    class Metadata
      attr_reader :title, :subtitle, :description, :date, :slug, :uid,
                  :url, :categories, :tags, :updates, :last_edit

      def initialize(post) # rubocop:disable Metrics/AbcSize
        @title = post.data["title"]
        @subtitle = post.data["subtitle"]
        @description = post.data["description"]
        @date = post.data["date"]
        @slug = post.data["slug"]
        @uid = post.data["uid"]
        @url = post.url
        @categories = post.data["categories"]
        @tags = post.data["tags"]
        @updates = post.data["updates"]
        @last_edit = post.data["most_recent_edit"]
      end

      def to_h
        {
          :title       => @title,
          :subtitle    => @subtitle,
          :description => @description,
          :date        => @date,
          :slug        => @slug,
          :uid         => @uid,
          :url         => @url,
          :categories  => @categories,
          :tags        => @tags,
          :updates     => @updates,
          :last_edit   => @last_edit,
        }.compact
      end
    end
  end
end
