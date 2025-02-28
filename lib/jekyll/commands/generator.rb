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
                     "Generate embeddings and find related posts also for those with a future date."
            c.option "drafts",
                     "--drafts",
                     "Generate embeddings and find related posts also for drafts."
            c.option "dryrun",
                     "--dry-run",
                     "Do not update the database, do not write related posts to disk."

            c.action do |_, opts|
              Jekyll.logger.info "\nAI Related plugin starting...\n"
              options = configuration_from_options(opts)

              # Configure logging level
              if options["debug"]
                Jekyll.logger.log_level = :debug
              elsif options["quiet"]
                Jekyll.logger.log_level = :error
              end

              env = ENV["JEKYLL_ENV"]
              env_msg = env ? "in ** #{env} ** environment" : "environment NOT SET"
              Jekyll.logger.info "\nWorking #{env_msg}\n"
              Jekyll.logger.info "\n*** Running in dry-run mode ***\n" if options["dryrun"]

              Jekyll.logger.info "Show drafts? #{options["show_drafts"] ? "Yes" : "No"}"
              Jekyll.logger.info "Include future posts? #{options["future"] ? "Yes" : "No"}"

              Jekyll::EmbeddingsGenerator.run(options)

              # back to default log level
              Jekyll.logger.log_level = :info
              Jekyll.logger.info "\nAI Related plugin finished. Bye!\n"
            end
          end
        end
      end
    end
  end
end
