# frozen_string_literal: true

require "httparty"
require "json"

module Jekyll
  module EmbeddingsGenerator
    module Embeddings
      class << self
        include Jekyll::EmbeddingsGenerator

        def generate_embeddings(text)
          config = Jekyll::EmbeddingsGenerator.config
          api_key = config["openai_api_key"]
          response = HTTParty.post(
            "https://api.openai.com/v1/embeddings",
            :headers => {
              "Authorization" => "Bearer #{api_key}",
              "Content-Type"  => "application/json",
            },
            :body    => {
              :model => "text-embedding-3-small",
              :input => text,
            }.to_json
          )

          raise "OpenAI API error: #{response.parsed_response["error"]["message"]}" unless response.success?

          response.parsed_response["data"][0]["embedding"]
        end
      end
    end
  end
end
