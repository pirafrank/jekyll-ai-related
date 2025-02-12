# frozen_string_literal: true

module Jekyll
  module Commands
    class EmbeddingsGenerator < Command
      class << self
        def init_with_program(prog)
          prog.command(:related) do |c|
            c.description "Generate embeddings for each post and find related posts."
            c.syntax "embeddings [options]"

            c.option "debug",
                     "--debug",
                     "Most verbose. Set log level to Debug."
            c.option "quiet",
                     "--quiet",
                     "Do not print Info logs. Set log level to Error."
            c.option "future",
                     "--future",
                     "Get embeds and fine related posts also for those with a future date."
            c.option "drafts",
                     "--drafts",
                     "Get embeds and find related posts also for drafts."

            c.action do |_, opts|
              Jekyll.logger.info "AI Related plugin starting..."
              options = configuration_from_options(opts)
              Jekyll::EmbeddingsGenerator.run(options)
            end
          end
        end
      end
    end
  end
end
