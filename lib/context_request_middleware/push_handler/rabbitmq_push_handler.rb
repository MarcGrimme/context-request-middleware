# frozen_string_literal: true

require 'bunny'
require 'connection_pool'

module ContextRequestMiddleware
  module PushHandler
    # PushHandler that pusblishes the data given to a RabbitMQ exchange.
    # If the exchange is not existant it will be created. The session is
    # taken from the session_pool.
    class RabbitmqPushHandler < Base
      # :nodoc:
      class ConfirmationFailed < StandardError
        def initialize(channel, nacked, unconfirmed)
          super("Message confirmation on the exchange #{channel} has failed\
(#{nacked}/#{unconfirmed}).")
        end
      end
      # Setup the rublisher with configuring via the config options. The
      # following config options are supported:
      # @rabbit_mq_url url to connect to RabbitMQ
      # @pool_size size of the connection pool to be used. Defaults to 1
      # @session_params a hash definiting the params passed to the session.
      # @heartbeat heartbeat interval used to communicate with
      #    RabbitMQ.
      # @exchange_name name of the exchange defaults to 'fos.context_request'
      # @exchange_type type of the exchange defaults to ''
      # @exchange_options options passed to the exchange if it has to be
      #    created.
      # rubocop:disable Metrics/MethodLength
      def initialize(**config)
        @config = config.dup
        @session_params = config.fetch(:session_params, {})
                                .merge(threaded: false,
                                       automatically_recover: false,
                                       heartbeat: config[:heartbeat])
        pool_size = @session_params.delete(:session_pool) || 1
        @session_params.freeze
        @session_pool = ConnectionPool.new(size: pool_size) do
          Bunny.new(config[:rabbit_mq_url], @session_params)
        end
        config_clean
      end
      # rubocop:enable Metrics/MethodLength

      # Publishes the given data on the exchange. The exchange is created if
      # it does not exist.
      # @data a hash representing the data to be published as json.
      # @options options to be passed to the publish to the exchange.
      def push(data, options)
        @session_pool.with do |session|
          session.start
          channel = session.create_channel
          channel.confirm_select

          exchange = fetch_exchange(session, channel)
          exchange.publish(data.to_json, **options)

          wait_for_confirms(channel)
          channel.close
        end
      end

      private

      def wait_for_confirms(channel)
        return if channel.wait_for_confirms

        raise ConfirmationFailed.new(exchange_name, channel.nacked_set,
                                     channel.unconfirmed_set)
      end

      def config_clean
        @config.delete(:rabbit_mq_url)
        @config.delete(:session_params)
        @config.delete(:heartbeat)
      end

      # return the channel if a channel is already there otherwise create a new
      # exchange with the predefined settings.
      # Can be overwriten by ContextRequestMiddleware.fetch_exchange_callback
      def fetch_exchange(_session, channel)
        channel.exchanges[exchange_name] || bunny_exchange(channel)
      end

      def bunny_exchange(channel)
        Bunny::Exchange.new(channel, exchange_type, exchange_name,
                            exchange_options)
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
