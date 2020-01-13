# frozen_string_literal: true
# rubocop:disable all

require 'context_request_middleware/duplicable'

module ContextRequestMiddleware
  # ParameterFilter module to filter the contents of provided parameters.
  # Used when the version of ActiveSupport doesn't have this class
  class ParameterFilter
    FILTERED = "[FILTERED]" # :nodoc:

    # Create instance with given filters. Supported type of filters are +String+, +Regexp+, and +Proc+.
    # Other types of filters are treated as +String+ using +to_s+.
    # For +Proc+ filters, key, value, and optional original hash is passed to block arguments.
    #
    # ==== Options
    #
    # * <tt>:mask</tt> - A replaced object when filtered. Defaults to +"[FILTERED]"+
    def initialize(filters = [], mask: FILTERED)
      @filters = filters
      @mask = mask
    end

    # Mask value of +params+ if key matches one of filters.
    def filter(params)
      compiled_filter.call(params)
    end

    # Returns filtered value for given key. For +Proc+ filters, third block argument is not populated.
    # :nocov:
    def filter_param(key, value)
      @filters.empty? ? value : compiled_filter.value_for_key(key, value)
    end
    # :nocov:

    private

    def compiled_filter
      @compiled_filter ||= CompiledFilter.compile(@filters, mask: @mask)
    end

    class CompiledFilter # :nodoc:
      def self.compile(filters, mask:)
        return lambda { |params| params.dup } if filters.empty?

        strings, regexps, blocks = [], [], []

        filters.each do |item|
          case item
            when Proc
              blocks << item
            when Regexp
              regexps << item
            else
              strings << Regexp.escape(item.to_s)
          end
        end

        deep_regexps = regexps.dup
        deep_regexps.keep_if { |r| r.to_s.include?("\\.") }
        regexps.delete_if { |r| r.to_s.include?("\\.") }

        deep_strings = strings.dup
        deep_strings.keep_if { |s| s.include?("\\.") }
        strings.delete_if { |s| s.include?("\\.") }

        regexps << Regexp.new(strings.join("|"), true) unless strings.empty?
        deep_regexps << Regexp.new(deep_strings.join("|"), true) unless deep_strings.empty?

        new regexps, deep_regexps, blocks, mask: mask
      end

      attr_reader :regexps, :deep_regexps, :blocks

      def initialize(regexps, deep_regexps, blocks, mask:)
        @regexps = regexps
        @deep_regexps = deep_regexps.any? ? deep_regexps : nil
        @blocks = blocks
        @mask = mask
      end

      def call(params, parents = [], original_params = params)
        filtered_params = params.class.new

        params.each do |key, value|
          filtered_params[key] = value_for_key(key, value, parents, original_params)
        end

        filtered_params
      end

      def value_for_key(key, value, parents = [], original_params = nil)
        parents.push(key) if deep_regexps
        if regexps.any? { |r| r.match?(key) }
          value = @mask
        elsif deep_regexps && (joined = parents.join(".")) && deep_regexps.any? { |r| r.match?(joined) }
          value = @mask
        elsif value.is_a?(Hash)
          value = call(value, parents, original_params)
        elsif value.is_a?(Array)
          # :nocov:
          # If we don't pop the current parent it will be duplicated as we
          # process each array value.
          parents.pop if deep_regexps
          value = value.map { |v| value_for_key(key, v, parents, original_params) }
          # Restore the parent stack after processing the array.
          parents.push(key) if deep_regexps
          # :nocov:
        elsif blocks.any?
          key = key.dup if Duplicable.check?(key)
          value = value.dup if Duplicable.check?(value)
          blocks.each { |b| b.arity == 2 ? b.call(key, value) : b.call(key, value, original_params) }
        end
        parents.pop if deep_regexps
        value
      end
    end
  end
end
# rubocop:enable all
