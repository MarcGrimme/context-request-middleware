# frozen_string_literal: true

require 'spec_helper'

module ContextRequestMiddleware
  module PushHandler
    RSpec.describe RabbitmqPushHandlerAsync do
      let(:exchange_name) { 'exchange' }
      let(:confirmed) { true }
      let(:publisher) { double('RabbitmqClient::Publisher') }

      describe '#push' do
        before do
          allow(RabbitmqClient::Publisher).to receive(:new)
            .and_return(publisher)
          allow(publisher).to receive(:publish)
            .and_return(:confirmed)
        end
        context 'with minimum config' do
          subject { described_class.new(exchange_name: exchange_name) }
          it { expect(subject.push({}, {})).to eq(:confirmed) }
        end
      end
    end
  end
end
