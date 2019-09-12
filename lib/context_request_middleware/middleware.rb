# frozen_string_literal: true

module ContextRequestMiddleware
  # :nodoc:
  class Middleware
    def initialize(app)
      @app = app
      @data = {}
    end

    def call(env)
      request = Rack::Request.new(env)
      request(request) if valid_sample?(request)
      status, header, body = @app.call(env)
      if valid_sample?(request)
        response(status, header, body)
        push context(status, header, body, request)
        push @data
      end
      [status, header, body]
    end

    private

    def request(request)
      request_data(request)
      others_data(request)
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
      @data[:app_id] = ContextRequestMiddleware.app_id
      @data[:source] = source(request)
      @data[:host] = request.host
    end

    def response(status, _headers, _response)
      @data[:request_status] = status
    end

    def push(data)
      (@push_handler ||= PushHandler.from_middleware)&.push(data)
    end

    def valid_sample?(request)
      handler = SamplingHandler.from_request(request)
      if handler
        handler.valid?
      else
        false
      end
    end

    # checks if this request changed the context
    def context(status, header, body, request)
      response = Rack::Response.new(body, status, header)
      context_retriever(response, request)&.call
    end

    # retrieves the context of the current request
    def request_context(request)
      @request_context ||= Request.retriever_for_request(request)&.call
    end

    def context_retriever(request, response)
      @context_retriever ||=
        Context.retriever_for_response(response, request)
    end

    def request_start_time(request)
      ContextRequestMiddleware.select_request_headers(
        ContextRequestMiddleware.request_start_time_headers,
        request
      )
    end

    def source(request)
      (ContextRequestMiddleware.remote_ip_headers &&
       ContextRequestMiddleware
        .select_request_headers(ContextRequestMiddleware.remote_ip_headers,
                                request)) ||
        request.get_header('action_dispatch.remote_ip') ||
        request.get_header('HTTP_X_FORWARDED_HOST')
    end
  end
end
