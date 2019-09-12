# frozen_string_literal: true

require 'spec_helper'

module ContextRequestMiddleware
  RSpec.describe PushHandler do
    context 'from_middleware' do
      before do
        expect(ContextRequestMiddleware).to receive(:push_handler)
          .and_return('mock_push_handler')
      end
      it do
        expect(described_class.from_middleware)
          .to be_an_instance_of PushHandler::MockPushHandler
      end
    end
  end
end
