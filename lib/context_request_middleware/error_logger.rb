# frozen_string_literal: true

module ContextRequestMiddleware
  # Logger module to provide logging of errors
  module ErrorLogger
    extend self

    # runs block of code and logs an error if any occurs
    def error_handler
      yield
    rescue StandardError => e
      logger.tagged(ContextRequestMiddleware.logger_tags) do
        logger.error e.message + e.backtrace.join('\n')
      end
    end

    # Returns logger from these options:
    # option 1: Rails.logger, as defined in the host application
    # option 2: new instance of ActiveSupport::TaggedLogging class
    def logger(logger = Logger)
      @logger ||= if defined?(Rails.logger.tagged)
                    # :nocov:
                    Rails.logger
                    # :nocov:
                  else
                    ActiveSupport::TaggedLogging.new(logger)
                  end
    end
  end
end
