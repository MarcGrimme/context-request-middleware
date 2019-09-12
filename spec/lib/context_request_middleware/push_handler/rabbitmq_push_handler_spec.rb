# frozen_string_literal: true

require 'spec_helper'

require 'context_request_middleware/push_handler/rabbitmq_push_handler'

module ContextRequestMiddleware
  module PushHandler
    RSpec.describe RabbitMQPushHandler do
      let(:bunny_session) { double('bunny_session') }
      let(:bunny_channel) { double('bunny_channel') }
      let(:exchange_name) { 'exchange' }
      let(:exchange) { double('exchange') }

      before do
        expect(Bunny).to receive(:new).with(url, session_params)
                                      .and_return(bunny_session)
        expect(bunny_session).to receive(:start)
        expect(bunny_session).to receive(:create_channel)
          .and_return(bunny_channel)
        expect(bunny_channel).to receive(:confirm_select)
        expect(bunny_channel).to receive(:exchanges)
          .and_return(exchange_name => exchange)
        expect(bunny_channel).to receive(:wait_for_confirms).and_return(true)
        expect(bunny_channel).to receive(:close)
        expect(exchange).to receive(:publish)
      end

      describe 'push a valid hash' do
        context 'with minimum config' do
          let(:poolsize) { 1 }
          let(:url) { nil }
          let(:heartbeat) { nil }
          let(:session_params) do
            { automatically_recover: false, threaded: false,
              heartbeat: heartbeat }
          end
          subject { described_class.new(exchange_name: exchange_name) }
          it { expect(subject.push({})).to be_nil }
        end

        context 'with complete config' do
          let(:url) { 'amqp://guest:guest@vm188.dev.megacorp.com/profitd.qa' }
          let(:poolsize) { 2 }
          let(:heartbeat) { 2 }
          let(:session_params) do
            { automatically_recover: false, threaded: false,
              heartbeat: heartbeat }
          end
          subject do
            described_class.new(
              exchange_name: 'other_exchange',
              rabbit_mq_url: url,
              pool_size: 2,
              heartbeat: heartbeat,
              exchange_type: 'type',
              exchange_options: { opt1: 'opt1' }
            )
          end
          before do
            expect(Bunny::Exchange).to receive(:new)
              .with(bunny_channel, 'type', 'other_exchange', opt1: 'opt1')
              .and_return(exchange)
          end
          it { expect(subject.push({})).to be_nil }
        end
      end
    end
  end
end
