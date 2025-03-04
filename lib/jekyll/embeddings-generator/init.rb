# frozen_string_literal: true

module Jekyll
  module EmbeddingsGenerator
    class Configuration
      include Jekyll::EmbeddingsGenerator

      @config = {}

      def self.init(opts) # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
        jk_config = Jekyll.configuration({})["jekyll-ai-related"] || {}
        config = {}
        config["uid"] = jk_config["post_unique_field"] || "slug"
        config["mre"] = jk_config["post_updated_field"] || "date"
        config["path"] = jk_config["output_path"] || "related_posts"
        config["drafts"] = jk_config["include_drafts"] || opts["drafts"] || false
        config["future"] = jk_config["include_future"] || opts["future"] || false
        config["dryrun"] = opts["dryrun"] || false
        config["limit"] = jk_config["related_posts_limit"] || 3
        config["score_threshold"] = jk_config["related_posts_score_threshold"] || 0.5
        config["precision"] = jk_config["precision"] || 3
        config["openai_api_key"] = ENV["OPENAI_API_KEY"]
        config["supabase_url"] = ENV["SUPABASE_URL"]
        config["supabase_key"] = ENV["SUPABASE_KEY"]
        config["db_table"] = jk_config["db_table"] || "page_embeddings"
        config["db_function"] = jk_config["db_function"] || "cosine_similarity"

        # use different table and stored procedure names for each environemnt, if set
        env = ENV["JEKYLL_ENV"] ? "_#{ENV["JEKYLL_ENV"]}" : ""
        config["db_table"] = "#{config["db_table"]}#{env}"
        config["db_function"] = "#{config["db_function"]}#{env}"

        Jekyll.logger.debug "Configuration:", config

        @config = config
        validate
        config
      end

      def self.build(options)
        options["show_drafts"] = @config["drafts"]
        options["future"] = @config["future"]
        site = Jekyll::Site.new(options)
        site.reset
        site.read
        # call the 'generate' method on all plugins inheriting from Jekyll::Generator.
        # This allows to generate the site's content, including any additional data
        # you may have added to the post objects via a custom plugin (which by default
        # lives in the _plugins dir of you Jekyll installation).
        site.generate
        site
      end

      def self.validate
        raise "Missing OpenAI API key" unless @config["openai_api_key"]
        raise "Missing Supabase URL" unless @config["supabase_url"]
        raise "Missing Supabase key" unless @config["supabase_key"]
      end
    end
  end
end
