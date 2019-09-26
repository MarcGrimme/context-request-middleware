# frozen_string_literal: true

require 'context_request_middleware/context/cookie_session_retriever'

module ContextRequestMiddleware
  # Base module to consolidate the different context extraction logics.
  # Like extracting sessions that have been newly created, apitokens, ..
  module Context
    extend self

    def retriever_for_response(request)
      ContextRequestMiddleware
        .load_class_from_name(
          ContextRequestMiddleware.context_retriever,
          ContextRequestMiddleware::Context.to_s,
          ContextRequestMiddleware.context_retriever_version
        )&.new(request)
    end
  end
end
