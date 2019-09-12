# frozen_string_literal: true

# Module to provide helper functions on request headers, methods, cookies
require 'context_request_middleware/request/cookie_session_id_retriever'

module ContextRequestMiddleware
  # :nodoc:
  module Request
    extend self

    def retriever_for_request(request)
      ContextRequestMiddleware
        .load_class_from_name(
          ContextRequestMiddleware.request_context_retriever,
          ContextRequestMiddleware::Request.to_s,
          ContextRequestMiddleware.request_context_retriever_version
        )&.new(request)
    end
  end
end
