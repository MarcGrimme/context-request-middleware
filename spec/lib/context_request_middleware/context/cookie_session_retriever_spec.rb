# frozen_string_literal: true

require 'spec_helper'
require 'context_request_middleware/context.rb'

module ContextRequestMiddleware
  module Context
    RSpec.describe CookieSessionRetriever do
      subject { described_class.new(response, request) }
      let(:env) do
        Rack::MockRequest.env_for('/some/path',
                                  'CONTENT_TYPE' => 'text/plain',
                                  'HTTP_X_REQUEST_START' => Time.now.to_f)
      end
      let(:request) { Rack::Request.new(env) }

      describe '#call' do
        context 'without cookie' do
          let(:response) do
            Rack::MockResponse
              .new(200, { 'Content-Type' => 'text/plain' }, ['OK'])
          end
          it { expect(subject.call).to eq({}) }
        end

        context 'with cookie' do
          let(:response) do
            sid = RackSessionCookie.generate_sid
            generate_session(request, sid)
            response = Rack::MockResponse
                       .new(200, { 'Content-Type' => 'text/plain' }, ['OK'])
            set_cookie_in_response(response, request)
            response
          end
          let(:data) do
            { context_id: request.session[:id],
              owner_id: '123',
              context_status: 'unknown',
              context_type: 'session_cookie' }
          end

          it do
            expect(subject.call).to eq data
          end
        end
      end
    end
  end
end
