# frozen_string_literal: true

require_relative "commands/generator"
require_relative "embeddings-generator/init"
require_relative "embeddings-generator/version"
require_relative "embeddings-generator/embeddings/fingerprint"
require_relative "embeddings-generator/embeddings/generate"
require_relative "embeddings-generator/embeddings/store"
require_relative "embeddings-generator/models/data"
require_relative "embeddings-generator/models/metadata"

module Jekyll
  module EmbeddingsGenerator
    class Error < StandardError; end
    class << self
      attr_reader :config, :site

      def run(options)
        @config = Configuration.init(options)
        @site = Configuration.build(options)
        extract_content
        write_related_posts
      end

      private

      def extract_content
        Jekyll.logger.info "Embeddings Generator:", "Starting to process markdown files..."
        @site.posts.docs.each { |post| process_post(post) }
        Jekyll.logger.info "Embeddings Generator:", "Finished processing markdown files."
      end

      def process_post(post)
        Jekyll.logger.info "Embeddings Generator:", "Processing post: #{post.data["title"]}"
        content = post.content
        metadata = Jekyll::EmbeddingsGenerator::Metadata.new(post)
        uid = post.data[@config["uid"]]
        fingerprint = Jekyll::EmbeddingsGenerator::Embeddings.fingerprint(content)

        existing = Jekyll::EmbeddingsGenerator::Store.fetch_record(uid)
        embedding = resolve_embedding(post, content, existing, fingerprint)

        data = Jekyll::EmbeddingsGenerator::Data.new(post, embedding, metadata, fingerprint)
        Jekyll::EmbeddingsGenerator::Store.upsert_if_needed(data, existing)
      end

      def resolve_embedding(post, content, existing, fingerprint)
        if Jekyll::EmbeddingsGenerator::Store.cache_hit?(existing, fingerprint)
          Jekyll.logger.info "Embeddings Generator:", "Reusing cached embedding for: #{post.data["title"]}"
          existing["embedding"]
        else
          Jekyll.logger.info "Embeddings Generator:", "Generating embedding for: #{post.data["title"]}"
          Jekyll::EmbeddingsGenerator::Embeddings.generate_embeddings(content)
        end
      end

      def write_related_posts
        # Query vector database and find related posts per each post
        @site.posts.docs.each do |post|
          # Find related posts
          related_posts = Jekyll::EmbeddingsGenerator::Store.find_related(post)
          write_to_file(related_posts, post)

          # Log related posts for debugging
          Jekyll.logger.info "Related posts:", "Found #{related_posts.length} related posts for #{post.data[@config["uid"]]}"
        rescue StandardError => e
          Jekyll.logger.error "Related posts:", "Error processing #{post.data["title"]}: #{e.message}"
        end
        Jekyll.logger.info "Related posts:", "Finished writing markdown files."
      end

      def write_to_file(data, post)
        if @config["dryrun"]
          Jekyll.logger.info "Related posts:", "Dry run enabled, skipping writing to file."
          return
        end
        return if data.empty?

        # Create directory if it doesn't exist
        subdir = @config["path"]
        target_dir = File.join(@site.source, "_data", subdir)
        FileUtils.mkdir_p(target_dir)
        # Write related posts to file, overwriting if exists
        safe_uid = safe_filename(post.data[@config["uid"]].to_s)
        filename = File.join(target_dir, "#{safe_uid}.yml")
        File.write(filename, data.to_yaml, mode: "w")
      end

      def safe_filename(filename)
        filename.downcase.gsub(%r![^a-z0-9\-_]!, "-")
      end
    end
  end
end
