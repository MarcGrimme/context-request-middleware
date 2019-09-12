# frozen_string_literal: true

module ContextRequestMiddleware
  module SamplingHandler
    # Simple sampling handler that samples every request.
    class AcceptAll
      def initialize(request)
        @request = request
      end

      def valid?
        true
      end
    end
  end
end
