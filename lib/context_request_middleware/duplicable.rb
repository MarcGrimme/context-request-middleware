# frozen_string_literal: true

module ContextRequestMiddleware
  # Duplicable module used by ParameterFilter module
  module Duplicable
    def self.check?(object)
      return false if object.is_a?(Method) || object.is_a?(UnboundMethod)

      true
    end
  end
end
