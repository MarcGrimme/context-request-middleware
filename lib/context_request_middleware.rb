# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'rack'
require 'securerandom'

require 'context_request_middleware/railtie' if defined?(Rails)
require 'context_request_middleware/sampling_handler'
require 'context_request_middleware/middleware'
require 'context_request_middleware/cookie'
require 'context_request_middleware/request'
require 'context_request_middleware/context'
require 'context_request_middleware/push_handler'
require 'context_request_middleware/sampling_handler/accept_all'

# :nodoc:
module ContextRequestMiddleware
  include ActiveSupport::Configurable

  # For older Rack Versions there is no method 'get_header' this
  # Request class will provide that logic.
  # :nocov:
  config_accessor(:request_class, instance_accessor: false) do
    if Rack.release[0].to_i < 2
      # :nodoc:
      class RackRequest < Rack::Request
        def get_header(name)
          @env[name]
        end
      end
      RackRequest
    else
      Rack::Request
    end
  end
  # :nocov:

  # Array to specify the headers supported to hold the request_id.
  # Defaults to the X_REQUEST_ID header.
  # @default ['HTTP_X_REQUEST_ID']
  config_accessor(:request_id_headers, instance_accessor: false) do
    ['HTTP_X_REQUEST_ID', 'action_dispatch.request_id']
  end

  # Array to specify the headers supported to hold the start time of the
  # request.
  # @default ['HTTP_X_REQUEST_START', 'HTTP_X_QUEUE_START']
  config_accessor(:request_start_time_headers, instance_accessor: false) do
    %w[HTTP_X_REQUEST_START HTTP_X_QUEUE_START]
  end

  # If remote IP is carried in an unsupported headers it can be specified here.
  # Expects an Array. For one item this means one item Array.
  # @default nil which means the X_REQUEST_HOST and rails specifics are
  # supported
  config_accessor(:remote_ip_headers, instance_accessor: false)

  # Application id given to the application using the middleware.
  # @default 'anonymous'
  config_accessor(:app_id, instance_accessor: false) do
    'anonymous'
  end

  # small case '_' or '.' delimited classname to point to the session id
  # retriever.
  # To be found under the namespace ContextRequestMiddleware::Request
  # @default 'cookie_session_id_retriever' which resolves to
  #      ContextRequestMiddleware::Request::SessionIdRetriever.
  config_accessor(:request_context_retriever, instance_accessor: false) do
    'cookie_session_id_retriever'
  end
  # version for request_retriever.
  # @default nil as no version yet set
  config_accessor(:request_context_retriever_version, instance_accessor: false)

  # Classname (small case) on how to extract the context if a new one is
  # created. Basically this means detect if a new context was created or
  # not. For example is the session still valid or not.
  # To be found under the namespace ContextRequestMiddleware::Context
  # @default 'cookie_session_id_retriever'
  config_accessor(:context_retriever, instance_accessor: false) do
    'cookie_session_retriever'
  end
  config_accessor(:context_retriever_version, instance_accessor: false)

  # Extract the user id from Main application
  # Set in Main App ENV['cookie_session.user_id'] = current_user.id
  # usually done in application_controller
  # so it can be applied to the context
  # @default cookie_session.user_id
  config_accessor(:session_owner_id, instance_accessor: false) do
    'cookie_session.user_id'
  end

  # Classname (small case) on how to push the data stored from the current
  # request.
  # @default rabbitmq_push_handler which means it pushes to RabbitMQ
  config_accessor(:push_handler, instance_accessor: false) do
    'rabbitmq_push_handler'
  end
  config_accessor(:push_handler_version, instance_accessor: false)

  # Configuration to configure the push_handler if required.
  # @default: {}
  config_accessor(:push_handler_config, instance_accessor: false) { {} }

  # Classname (small case) on how to detect if this request should be
  # sampled.
  # @default accept_all which means all requests will be sampled.
  config_accessor(:sampling_handler, instance_accessor: false) do
    'accept_all'
  end
  config_accessor(:sampling_handler_version, instance_accessor: false)

  # retrieves a class that is loaded from the root_pathname and
  # suffixed with both name and version.
  # @root_pathname: the root path to be prefixed.
  #       For example ContextRequestMiddleware::Request as string.
  # @name: the name of the class in small case seperated with . or _.
  #       For example session_id_retriever will yield to SessionIdretriever.
  # @version: if version is given it will be suffixed to the path.
  #       For example version=1 will yield {root_path}::V1.
  # @return a class if found otherwise nil.
  def self.load_class_from_name(name, root_path_name, version = nil)
    version = "V#{version}" if version
    [root_path_name, version, name.tr('.', '_').camelize].compact.join('::')
                                                         .constantize
  rescue NameError
    nil
  end

  #
  # Returns the first header found from the given array of headers in the
  # given request.
  # @headres an array of headers to be looking for. Headers are specified full
  #   as in the environment with HTTP_ prefixed and capital letters ...
  # @request the Rack::Request holding the request (headers) as Hash.
  def self.select_request_headers(headers, request)
    value = nil
    headers.each do |header|
      value = request.get_header(header)
      break if value
    end
    value
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))
