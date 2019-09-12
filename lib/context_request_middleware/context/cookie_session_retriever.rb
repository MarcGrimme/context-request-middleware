# frozen_string_literal: true

module ContextRequestMiddleware
  module Context
    # Class for retrieving the session if set via rack cookie.
    # This requires the session and more data to be stored in
    # '_session_id' cookie key.
    class CookieSessionRetriever
      include ActiveSupport::Configurable

      attr_accessor :data

      def initialize(response, request)
        @response = response
        @request = request
        @data = {}
      end

      def call
        if session_id
          data[:context_id] = session_id
          data[:owner_id] = owner_id
          data[:context_status] = context_status
          data[:context_type] = context_type
        end
        data
      end

      private

      def owner_id
        '123'
      end

      def context_status
        'unknown'
      end

      def context_type
        'session_cookie'
      end

      def session_id
        @cookie.match(/#{cookie_key}=([^\;]*)/)[1] if cookie_key && cookie
      end

      def cookie
        @cookie ||= @response.get_header(Rack::SET_COOKIE)
      end

      def cookie_key
        @cookie_key ||= @request.session_options &&
                        @request.session_options[:key]
      end
    end
  end
end
