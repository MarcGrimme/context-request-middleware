# frozen_string_literal: true

module ContextRequestMiddleware
  module Request
    # Class for retrieving the session if set via rack cookie.
    # This requires the session id to be stored in '_session_id'
    # cookie key.
    class Base
      include ActiveSupport::Configurable
      include ContextRequestMiddleware::Cookie

      def initialize(request)
        @request = request
      end

      def call
        session
      end
    end
  end
end
