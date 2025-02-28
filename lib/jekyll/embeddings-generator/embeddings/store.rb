# frozen_string_literal: true

require "httparty"
require "json"

module Jekyll
  module EmbeddingsGenerator
    module Store
      class << self
        include Jekyll::EmbeddingsGenerator

        def store_embedding(data) # rubocop:disable Metrics/AbcSize
          config = Jekyll::EmbeddingsGenerator.config
          supabase_url = config["supabase_url"]
          supabase_key = config["supabase_key"]

          # First check if record exists and its edit date
          existing = HTTParty.get(
            "#{supabase_url}/rest/v1/page_embeddings",
            :headers => {
              "apikey"          => supabase_key,
              "Authorization"   => "Bearer #{supabase_key}",
              "Content-Type"    => "application/json",
              "Accept-Encoding" => "identity", # this to avoid supabase returning gzipped content
            },
            :query   => {
              "uid"    => "eq.#{data.uid}",
              "select" => "uid, most_recent_edit",
            }
          )

          Jekyll.logger.debug "response headers: #{existing.headers}"
          Jekyll.logger.debug "response body: #{existing.body}"

          raise "Supabase API error: #{existing.code} - #{existing.body}" unless existing.success?

          existing_record = existing.parsed_response&.first
          mre = data.most_recent_edit
          should_update = existing_record.nil? || Time.parse(existing_record["most_recent_edit"]) < mre

          return false unless should_update

          update_embedding(data)
        end

        def find_related(post)
          config = Jekyll::EmbeddingsGenerator.config
          post_uid = post.data[config["uid"]]
          embedding = query_embeddings(post_uid)
          find_related_posts(embedding, post_uid)
        end

        private

        def update_embedding(data)
          config = Jekyll::EmbeddingsGenerator.config
          supabase_url = config["supabase_url"]
          supabase_key = config["supabase_key"]

          response = HTTParty.post(
            "#{supabase_url}/rest/v1/page_embeddings",
            :headers => {
              "apikey"        => supabase_key,
              "Authorization" => "Bearer #{supabase_key}",
              "Content-Type"  => "application/json",
              "Prefer"        => "resolution=merge-duplicates", # upsert behavior
            },
            :query   => {
              "on_conflict" => "uid", # important: this MUST be declared as unique on database
            },
            :body    => {
              :uid              => data.uid,
              :most_recent_edit => data.most_recent_edit,
              :embedding        => data.embedding,
              :metadata         => data.metadata,
              :content          => data.content,
            }.to_json
          )

          return if response.success?

          raise "Supabase API error: #{response.code} - #{response.body}"
        end

        def query_embeddings(post_uid)
          config = Jekyll::EmbeddingsGenerator.config
          supabase_url = config["supabase_url"]
          supabase_key = config["supabase_key"]
          response = HTTParty.get(
            "#{supabase_url}/rest/v1/page_embeddings",
            headers: {
              "apikey"          => supabase_key,
              "Authorization"   => "Bearer #{supabase_key}",
              "Content-Type"    => "application/json",
              "Accept-Encoding" => "identity", # this to avoid supabase returning gzipped content
            },
            query: {
              "uid" => "eq.#{post_uid}",
            }
          )
          Jekyll.logger.debug "response.parsed_response: #{response.parsed_response}"
          raise "Supabase API error: #{response.code} - #{response.body}" unless response.success?

          response.parsed_response.first&.dig("embedding")
        end

        def find_related_posts(embedding, post_uid)
          config = Jekyll::EmbeddingsGenerator.config
          supabase_url = config["supabase_url"]
          supabase_key = config["supabase_key"]
          score_threshold = config["score_threshold"]
          limit = config["limit"] || 3
          # Query using cosine similarity
          # Note: this MUST be a stored procedure on Supabase, and order of
          #       columns in 'select' statament must match the order of the
          #       columns defined in the stored procedure.
          query = %(
                    select
                      metadata->>'title' as title,
                      uid as uid,
                      most_recent_edit,
                      metadata->>'url' as url,
                      metadata->>'date' as date,
                      1 - (embedding <=> '#{embedding}') as similarity
                    from page_embeddings
                    where uid != '#{post_uid}'
                    and 1 - (embedding <=> '#{embedding}') > '#{score_threshold}'
                    order by embedding <=> '#{embedding}'
                    limit '#{limit}';
                  )
          response = HTTParty.post(
            "#{supabase_url}/rest/v1/rpc/related_posts",
            headers: {
              "apikey"          => supabase_key,
              "Authorization"   => "Bearer #{supabase_key}",
              "Content-Type"    => "application/json",
              "Accept-Encoding" => "identity", # this to avoid supabase returning gzipped content
              "Prefer"          => "return=minimal",
            },
            body: {
              query:,
            }.to_json
          )
          raise "Supabase API error: #{response.code} - #{response.body}" unless response.success?

          response.parsed_response
        end
      end
    end
  end
end
