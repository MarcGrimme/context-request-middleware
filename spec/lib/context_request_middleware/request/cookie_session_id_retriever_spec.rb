# frozen_string_literal: true

require 'spec_helper'
require 'context_request_middleware/request.rb'

module ContextRequestMiddleware
  module Request
    RSpec.describe CookieSessionIdRetriever do
      describe '#call' do
        it do
          env = Rack::MockRequest
                .env_for('/some/path', 'CONTENT_TYPE' => 'text/plain',
                                       'HTTP_X_REQUEST_START' => Time.now.to_f,
                                       'rack.request.cookie_hash' =>
                       { '_session_id' => '9bc829f0119b1f1647359ece68dc7b28' })
          subject = described_class.new(Rack::Request.new(env))
          expect(subject.call).to eq '9bc829f0119b1f1647359ece68dc7b28'
        end

        it do
          env = Rack::MockRequest
                .env_for('/some/path', 'CONTENT_TYPE' => 'text/plain',
                                       'HTTP_X_REQUEST_START' => Time.now.to_f)
          subject = described_class.new(Rack::Request.new(env))
          expect(subject.call).to be_nil
        end
      end
    end
  end
end
