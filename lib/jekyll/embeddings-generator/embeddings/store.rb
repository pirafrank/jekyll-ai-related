# frozen_string_literal: true

require "httparty"
require "json"

module Jekyll
  module EmbeddingsGenerator
    module Store
      RECORD_SELECT = "uid,most_recent_edit,embedding_fingerprint,embedding"

      class << self
        include Jekyll::EmbeddingsGenerator

        def fetch_record(uid)
          config = Jekyll::EmbeddingsGenerator.config
          response = HTTParty.get(
            "#{config["supabase_url"]}/rest/v1/#{config["db_table"]}",
            :headers => supabase_headers(config),
            :query   => {
              "uid"    => "eq.#{uid}",
              "select" => RECORD_SELECT,
            }
          )

          Jekyll.logger.debug "response headers: #{response.headers}"
          Jekyll.logger.debug "response body: #{response.body}"

          raise "Supabase API error: #{response.code} - #{response.body}" unless response.success?

          response.parsed_response&.first
        end

        def cache_hit?(existing_record, fingerprint)
          return false if existing_record.nil?
          return false if existing_record["embedding_fingerprint"].nil?
          return false if existing_record["embedding"].nil?

          existing_record["embedding_fingerprint"] == fingerprint
        end

        def should_upsert?(data, existing_record)
          return true if existing_record.nil?

          fingerprint_changed = data.embedding_fingerprint != existing_record["embedding_fingerprint"]
          metadata_newer = Time.parse(existing_record["most_recent_edit"].to_s) < data.most_recent_edit

          fingerprint_changed || metadata_newer
        end

        def upsert_if_needed(data, existing_record = nil)
          existing_record ||= fetch_record(data.uid)
          should_update = should_upsert?(data, existing_record)

          Jekyll.logger.debug "Embeddings Generator:", "Should update? #{should_update ? "Yes" : "No"}"
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

        def supabase_headers(config)
          supabase_key = config["supabase_key"]
          {
            "apikey"          => supabase_key,
            "Authorization"   => "Bearer #{supabase_key}",
            "Content-Type"    => "application/json",
            "Accept-Encoding" => "identity",
          }
        end

        def update_embedding(data) # rubocop:disable Metrics/AbcSize
          config = Jekyll::EmbeddingsGenerator.config
          if config["dryrun"]
            Jekyll.logger.info "Related posts:",
                               "Dry run enabled, skipping database update. If this is the first run, please disable dry run."
            return
          end

          Jekyll.logger.info "Embeddings Generator:", "Updating database for post: #{data.metadata[:title]}"

          response = HTTParty.post(
            "#{config["supabase_url"]}/rest/v1/#{config["db_table"]}",
            :headers => supabase_headers(config).merge(
              "Prefer" => "resolution=merge-duplicates"
            ),
            :query   => {
              "on_conflict" => "uid",
            },
            :body    => {
              :uid                   => data.uid,
              :most_recent_edit      => data.most_recent_edit,
              :embedding             => data.embedding,
              :embedding_fingerprint => data.embedding_fingerprint,
              :metadata              => data.metadata,
              :content               => data.content,
            }.to_json
          )

          return if response.success?

          raise "Supabase API error: #{response.code} - #{response.body}"
        end

        def query_embeddings(post_uid)
          config = Jekyll::EmbeddingsGenerator.config
          response = HTTParty.get(
            "#{config["supabase_url"]}/rest/v1/#{config["db_table"]}",
            headers: supabase_headers(config),
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
          table = config["db_table"]
          db_function = config["db_function"]
          score_threshold = config["score_threshold"]
          limit = config["limit"] || 3
          precision = config["precision"] || 3

          query = %(
                    select
                      metadata->>'title' as title,
                      uid as uid,
                      most_recent_edit,
                      metadata->>'url' as url,
                      metadata->>'date' as date,
                      TRUNC((1 - (embedding <=> '#{embedding}'))::numeric, #{precision}) as similarity
                    from #{table}
                    where uid != '#{post_uid}'
                    and 1 - (embedding <=> '#{embedding}') > '#{score_threshold}'
                    order by embedding <=> '#{embedding}'
                    limit '#{limit}';
                  )
          response = HTTParty.post(
            "#{supabase_url}/rest/v1/rpc/#{db_function}",
            headers: supabase_headers(config).merge(
              "Prefer" => "return=minimal"
            ),
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
