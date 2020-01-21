# frozen_string_literal: true

require 'context_request_middleware/push_handler/rabbitmq_push_handler'
require 'context_request_middleware/push_handler/rabbitmq_push_handler_async'

module ContextRequestMiddleware
  # :nodoc:
  module PushHandler
    extend self

    def initialize(**_config); end

    def from_middleware
      ContextRequestMiddleware
        .load_class_from_name(ContextRequestMiddleware.push_handler,
                              ContextRequestMiddleware::PushHandler.to_s,
                              ContextRequestMiddleware.push_handler_version)
      &.new(**ContextRequestMiddleware.push_handler_config)
    end
  end
end
