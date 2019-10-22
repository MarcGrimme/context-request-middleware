# frozen_string_literal: true

module ContextRequestMiddleware
  module Request
    # Class for retrieving the session if set via rack cookie.
    # This requires the session id to be stored in '_session_id'
    # cookie key.
    class CookieSessionIdRetriever
      include ActiveSupport::Configurable

      def initialize(request)
        @request = request
      end

      def call
        Rack::Utils.parse_cookies(@request.env)['_session_id'] ||
          (@request.env['action_dispatch.cookies'] || {})['_session_id']
      end
    end
  end
end
