# frozen_string_literal: true

module ContextRequestMiddleware
  module Context
    # Class for retrieving the session if set via rack cookie.
    # This requires the session and more data to be stored in
    # '_session_id' cookie key.
    class CookieSessionRetriever
      include ActiveSupport::Configurable
      include ContextRequestMiddleware::Cookie

      HTTP_HEADER = 'Set-Cookie'

      attr_accessor :data

      def initialize(request)
        @request = request
        @data = {}
      end

      def call(status, header, body)
        @response = Rack::Response.new(body, status, header)
        if new_context?
          data[:context_id] = session_id
          data[:owner_id] = owner_id
          data[:context_status] = context_status
          data[:context_type] = context_type
          data[:app_id] = ContextRequestMiddleware.app_id
        end
        data
      end

      def new_context?
        new_session_id && new_session_id != request_cookie_session_id
      end

      private

      def owner_id
        from_env(ContextRequestMiddleware.session_owner_id, 'unknown')
      end

      def context_status
        'unknown'
      end

      def context_type
        'session_cookie'
      end

      def session_id
        new_session_id || request_cookie_session_id
      end

      def new_session_id
        new_session = nil
        session_id_header = set_cookie_header.match(/_session_id=([^\;]+)/) \
            if set_cookie_header
        new_session = session_id_header[1] if session_id_header
        new_session
      end

      def request_cookie_session_id
        cookie_session_id(@request)
      end

      def set_cookie_header
        @response.headers.fetch(HTTP_HEADER, nil)
      end

      def from_env(key, default = nil)
        ENV.fetch(key, default)
      end
    end
  end
end
