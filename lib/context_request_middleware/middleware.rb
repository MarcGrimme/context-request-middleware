# frozen_string_literal: true

module ContextRequestMiddleware
  # :nodoc:
  class Middleware
    def initialize(app)
      @app = app
      @data = {}
    end

    def call(env)
      request = ContextRequestMiddleware.request_class.new(env)
      request(request) if valid_sample?(request)
      status, header, body = @app.call(env)
      if valid_sample?(request)
        response(status, header, body)
        @context = context(status, header, body, request)
        push
      end
      [status, header, body]
    end

    private

    def request(request)
      request_data(request)
      others_data(request)
      @data
    end

    def request_data(request)
      @data[:request_id] = ContextRequestMiddleware.select_request_headers(
        ContextRequestMiddleware.request_id_headers, request
      )
      @data[:request_context] = request_context(request)
      @data[:request_start_time] = request_start_time(request)
      @data[:request_method] = request.request_method
      @data[:request_params] = request.params
      @data[:request_path] = request.path
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

      @push_handler ||= PushHandler.from_middleware
      return unless @push_handler

      @push_handler.push(@data, push_options(@data, 'request'))
      return unless @context
      return unless @context.any?

      @push_handler.push(@context, push_options(@data, 'context'))
      nil
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
      ) || Time.current
    end

    def source(request)
      (ContextRequestMiddleware.remote_ip_headers &&
       ContextRequestMiddleware
        .select_request_headers(ContextRequestMiddleware.remote_ip_headers,
                                request)) ||
        request.get_header('action_dispatch.remote_ip').to_s ||
        request.get_header('HTTP_X_FORWARDED_HOST').to_s
    end
  end
end
