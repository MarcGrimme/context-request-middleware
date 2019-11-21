# frozen_string_literal: true

module ContextRequestMiddleware
  # Cookie module to consist the compatibility with
  # rack version 1.x & 2.0
  module Cookie
    HTTP_COOKIE = 'HTTP_COOKIE' if Rack.release < '2.0.0'

    # :nocov:
    def cookie_session_id(request)
      if Rack.release < '2.0.0'
        parse_cookies(request.env)['_session_id'] ||
          (request.env['action_dispatch.cookies'] || {})['_session_id']
      else
        Rack::Utils.parse_cookies(request.env)['_session_id'] ||
          (request.env['action_dispatch.cookies'] || {})['_session_id']
      end
    end

    # :nocov:
    if Rack.release < '2.0.0'
      # :nocov:
      def parse_cookies(env)
        parse_cookies_header env[HTTP_COOKIE]
      end

      def parse_cookies_header(header)
        # rubocop:disable Metrics/LineLength, Style/RescueModifier, Style/CaseEquality
        cookies = Rack::Utils.parse_query(header, ';,') { |s| unescape(s) rescue s }
        cookies.each_with_object({}) { |(k, v), hash| hash[k] = Array === v ? v.first : v }
        # rubocop:enable Metrics/LineLength, Style/RescueModifier, Style/CaseEquality
      end
      # :nocov:
    end
  end
end
