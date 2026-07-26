# frozen_string_literal: true

require "minitest/autorun"
require "jekyll-ai-related"

module Jekyll
  module EmbeddingsGenerator
    module TestHelpers
      def self.stub_config(overrides = {})
        @config = {
          "uid" => "slug",
          "mre" => "date",
        }.merge(overrides)
        EmbeddingsGenerator.instance_variable_set(:@config, @config)
      end

      def self.build_post(slug:, content:, date: Time.utc(2025, 1, 1))
        Struct.new(:data, :content, :url).new(
          {
            "slug"  => slug,
            "date"  => date,
            "title" => slug,
          },
          content,
          "/#{slug}/"
        )
      end
    end
  end
end
