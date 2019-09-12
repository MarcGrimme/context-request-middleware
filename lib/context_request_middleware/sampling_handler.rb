# frozen_string_literal: true

module ContextRequestMiddleware
  # :nodoc:
  module SamplingHandler
    extend self

    def from_request(request)
      ContextRequestMiddleware
        .load_class_from_name(ContextRequestMiddleware.sampling_handler,
                              ContextRequestMiddleware::SamplingHandler.to_s,
                              ContextRequestMiddleware.sampling_handler_version)
      &.new(request)
    end
  end
end
