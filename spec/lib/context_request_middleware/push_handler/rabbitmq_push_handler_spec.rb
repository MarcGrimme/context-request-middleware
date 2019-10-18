# frozen_string_literal: true

require 'spec_helper'

module ContextRequestMiddleware
  module PushHandler
    RSpec.describe RabbitmqPushHandler do
      let(:bunny_session) { double('bunny_session') }
      let(:bunny_channel) { double('bunny_channel') }
      let(:exchange_name) { 'exchange' }
      let(:exchange) { double('exchange') }
      let(:confirmed) { true }

      before do
        expect(exchange).to receive(:publish)
      end

      describe '#push' do
        before do
          expect(Bunny).to receive(:new).with(url, session_params)
                                        .and_return(bunny_session)
          expect(bunny_session).to receive(:start)
          expect(bunny_session).to receive(:create_channel)
            .and_return(bunny_channel)
          expect(bunny_channel).to receive(:confirm_select)
          expect(bunny_channel).to receive(:exchanges)
            .and_return(exchange_name => exchange)
          expect(bunny_channel).to receive(:wait_for_confirms)
            .and_return(confirmed)
          allow(bunny_channel).to receive(:close)
        end
        context 'with minimum config' do
          let(:poolsize) { 1 }
          let(:url) { nil }
          let(:heartbeat) { nil }
          let(:session_params) do
            { automatically_recover: false, threaded: false,
              heartbeat: heartbeat }
          end
          subject { described_class.new(exchange_name: exchange_name) }
          it { expect(subject.push({}, {})).to be_nil }
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
          it { expect(subject.push({}, {})).to be_nil }
        end

        context 'with network error' do
          let(:poolsize) { 1 }
          let(:url) { nil }
          let(:heartbeat) { nil }
          let(:session_params) do
            { automatically_recover: false, threaded: false,
              heartbeat: heartbeat }
          end
          let(:confirmed) { false }
          subject { described_class.new(exchange_name: exchange_name) }
          before do
            expect(bunny_channel).to receive(:nacked_set).and_return(10)
            expect(bunny_channel).to receive(:unconfirmed_set).and_return(10)
          end
          it do
            expect { subject.push({}, {}) }
              .to raise_error(described_class::ConfirmationFailed,
                              'Message confirmation on the exchange exchange'\
                              ' has failed(10/10).')
          end
        end
      end
    end
  end
end
