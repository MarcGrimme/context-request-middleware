# frozen_string_literal: true

require 'spec_helper'

module ContextRequestMiddleware
  module Context
    RSpec.describe CookieSessionRetriever do
      subject { described_class.new(request) }
      let(:user_id) { SecureRandom.uuid }
      let(:sid) { RackSessionCookie.generate_sid }
      let(:header) { { 'Content-Type' => 'text/plain' } }
      let(:env) do
        Rack::MockRequest.env_for('/some/path',
                                  'CONTENT_TYPE' => 'text/plain',
                                  'HTTP_X_REQUEST_START' => Time.now.to_f)
      end
      let(:response) { Rack::Response.new(['OK'], 200, header) }
      let(:request) { Rack::Request.new(env) }

      describe '#call' do
        context 'without cookie' do
          it { expect(subject.call(*response.to_a)).to eq({}) }
        end

        context 'with cookie' do
          before do
            Rack::Utils.set_cookie_header!(header, '_session_id', sid)
          end
          context 'with no user' do
            let(:data) do
              { context_id: sid,
                owner_id: 'unknown',
                context_status: 'unknown',
                context_type: 'session_cookie',
                app_id: 'anonymous' }
            end

            it { expect(subject.call(*response.to_a)).to eq data }
          end

          context 'with user' do
            let(:data) do
              { context_id: sid,
                owner_id: user_id,
                context_status: 'unknown',
                context_type: 'session_cookie',
                app_id: 'anonymous' }
            end
            before do
              ENV['cookie_session.user_id'] = user_id
            end

            it { expect(subject.call(*response.to_a)).to eq data }
          end

          context 'with cookie in req and resp' do
            context 'with different sids' do
              let(:new_sid) { RackSessionCookie.generate_sid }
              before do
                ENV['cookie_session.user_id'] = user_id
                request.env['HTTP_COOKIE'] =
                  Rack::Utils.add_cookie_to_header(nil, '_session_id', new_sid)
              end

              let(:data) do
                { context_id: sid,
                  owner_id: user_id,
                  context_status: 'unknown',
                  context_type: 'session_cookie',
                  app_id: 'anonymous' }
              end

              it { expect(subject.call(*response.to_a)).to eq data }
            end

            context 'with same sid' do
              before do
                request.env['HTTP_COOKIE'] =
                  Rack::Utils.add_cookie_to_header(nil, '_session_id', sid)
              end

              it { expect(subject.call(*response.to_a)).to eq({}) }
            end
          end
        end
      end
    end
  end
end
