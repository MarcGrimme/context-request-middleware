# frozen_string_literal: true

module ContextRequestMiddleware
  module SamplingHandler
    # Simple sampling handler that samples every request.
    class AcceptAll
      def valid?(_request)
        true
      end
    end
  end
end
