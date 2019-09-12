# frozen_string_literal: true

module ContextRequestMiddleware
  module Request
    # Class for retrieving the session if set via rack cookie.
    # This requires the session id to be stored in '_session_id'
    # cookie key.
    class CookieSessionIdRetriever
      include ActiveSupport::Configurable

      # Set the cookie session id that set's the cookie session.
      # @default '_session_id'
      config_accessor(:cookie_session_id_key, instance_accessor: false) do
        '_session_id'
      end

      def initialize(request)
        @request = request
      end

      def call
        @request.cookies[CookieSessionIdRetriever.cookie_session_id_key]
      end
    end
  end
end
