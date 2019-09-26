# frozen_string_literal: true

require 'spec_helper'
require 'context_request_middleware/request.rb'

module ContextRequestMiddleware
  module Request
    RSpec.describe CookieSessionIdRetriever do
      describe '#call' do
        subject(:retreiver) { described_class.new(request) }

        let(:sid) { RackSessionCookie.generate_sid }
        let(:env) do
          Rack::MockRequest
            .env_for('/some/path', 'CONTENT_TYPE' => 'text/plain')
        end
        let(:request) { Rack::Request.new(env) }
        context 'with cookie' do
          before do
            request.env['HTTP_COOKIE'] =
              Rack::Utils.add_cookie_to_header(nil, '_session_id', sid)
          end
          it do
            expect(subject.call).to eq sid
          end
        end
        context 'without cookie' do
          it do
            expect(subject.call).to be_nil
          end
        end
      end
    end
  end
end
