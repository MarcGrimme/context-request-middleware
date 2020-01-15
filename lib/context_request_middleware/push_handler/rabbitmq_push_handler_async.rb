# frozen_string_literal: true

require 'rabbitmq_client'
require 'context_request_middleware/push_handler/base'

module ContextRequestMiddleware
  module PushHandler
    # PushHandler that publishes the data given to a RabbitMQ exchange.
    # If the exchange is not existent it will be created. The session is
    # taken from the session_pool.
    class RabbitmqPushHandlerAsync < Base
      # Setup the publisher with configuring via the config options. The
      # following config options are supported:
      # @rabbitmq_url url to connect to RabbitMQ
      # @pool_size size of the connection pool to be used. Defaults to 1
      # @session_params a hash defining the params passed to the session.
      # @heartbeat_publisher heartbeat interval used to communicate with
      #    RabbitMQ.
      # @exchange_name name of the exchange defaults to 'fos.context_request'
      # @exchange_type type of the exchange defaults to ''
      # @exchange_options options passed to the exchange if it has to be
      #    created.
      def initialize(**config)
        @config = config.dup
        exchange = RabbitmqClient::ExchangeRegistry.new
        exchange.add(exchange_name, exchange_type, exchange_options)
        @config[:exchange_registry] = exchange
        @publisher = RabbitmqClient::Publisher.new(@config)
        config_clean
      end

      # Publishes the given data on the exchange.
      # @data a hash representing the data to be published.
      # @options options to be passed to the publish to the exchange.
      def push(data, options)
        @publisher.publish(data.dup,
                           options.dup.merge(exchange_name: exchange_name))
      end

      private

      def config_clean
        @config.delete(:rabbitmq_url)
        @config.delete(:session_params)
        @config.delete(:heartbeat)
      end

      def exchange_name
        @exchange_name ||= @config.fetch(:exchange_name, 'fos.context_request')
      end

      def exchange_type
        @config.fetch(:exchange_type, 'topic')
      end

      def exchange_options
        @config.fetch(:exchange_options, {})
      end
    end
  end
end
