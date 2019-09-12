# frozen_string_literal: true

module ContextRequestMiddleware
  module PushHandler
    class MockPushHandler < ContextRequestMiddleware::PushHandler::Base
      def initialize(**_keys); end
    end
  end
end
