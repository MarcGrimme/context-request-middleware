# frozen_string_literal: true

module ContextRequestMiddleware
  # :nodoc:
  # rubocop:disable Metrics/ClassLength
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @push_handler ||= PushHandler.from_middleware
      dup._call(env)
    end

    # rubocop:disable Metrics/MethodLength
    def _call(env)
      @data = {}
      request = ContextRequestMiddleware.request_class.new(env)
      request(request)
      status, header, body = @app.call(env)
      ContextRequestMiddleware::ErrorLogger.error_handler do
        response(status, header, body)
        @context = context(status, header, body, request)
        push_context
        push if valid_sample?(request)
      end
      env_cleanup(request)
      [status, header, body]
    end
    # rubocop:enable Metrics/MethodLength

    private

    def request(request)
      request_data(request)
      others_data(request)
      @data
    end

    def request_data(request)
      @data[:request_id] = request_id(request)
      @data[:request_context] = request_context(request)
      @data[:request_start_time] = request_start_time(request)
      @data[:request_method] = request.request_method
      @data[:request_params] = filter_params(request.params)
      @data[:request_path] = request.path
    end

    def filter_params(params)
      return params if ContextRequestMiddleware.parameter_filter_list.empty?

      filter = ContextRequestMiddleware.parameter_filter_class.new(
        ContextRequestMiddleware.parameter_filter_list,
        mask: ContextRequestMiddleware.parameter_filter_mask
      )
      filter.filter(params)
    end

    def others_data(request)
      @data[:source] = source(request)
      @data[:host] = request.host
    end

    def response(status, _headers, _response)
      @data[:request_status] = status
    end

    # checks if this request changed the context
    def context(status, header, body, request)
      @context = context_retriever(request)&.call(status, header, body)
      @data[:request_context] = @context[:context_id] \
        if @context && @context[:context_id]
      @context
    end

    # retrieves the context of the current request
    def request_context(request)
      @request_context ||= Request.retriever_for_request(request)&.call
    end

    def context_retriever(request)
      @context_retriever ||=
        Context.retriever_for_response(request)
    end

    def push
      return unless @data
      return unless @data.any?
      return unless @push_handler

      @push_handler.push(@data, push_options(@data, 'request'))

      nil
    end

    def push_context
      return unless @context_retriever.new_context?
      return unless @context
      return unless @context.any?
      return unless @push_handler

      @push_handler.push(@context, push_options(@data, 'context'))
    end

    def push_options(_data, type)
      {
        type: type,
        message_id: SecureRandom.uuid
      }
    end

    def valid_sample?(request)
      @sample_handler ||= SamplingHandler.from_request
      if @sample_handler
        @sample_handler.valid?(request)
      else
        false
      end
    end

    def request_start_time(request)
      ContextRequestMiddleware.select_request_headers(
        ContextRequestMiddleware.request_start_time_headers,
        request
      ) || (defined?(Time.current) ? Time.current : Time.now).to_f
    end

    def source(request)
      (ContextRequestMiddleware.remote_ip_headers &&
       ContextRequestMiddleware
        .select_request_headers(ContextRequestMiddleware.remote_ip_headers,
                                request)) ||
        request.get_header('action_dispatch.remote_ip').to_s ||
        request.get_header('HTTP_X_FORWARDED_HOST').to_s
    end

    def request_id(request)
      @request_id ||= ContextRequestMiddleware.select_request_headers(
        ContextRequestMiddleware.request_id_headers, request
      )
    end

    def env_cleanup(request)
      env_delete(ContextRequestMiddleware.session_owner_id, request)
      env_delete(ContextRequestMiddleware.context_status, request)
    end

    def env_delete(key, request)
      ENV.delete(key + '.' + request_id(request).to_s)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
