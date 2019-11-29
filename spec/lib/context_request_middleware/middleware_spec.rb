# frozen_string_literal: true

require 'spec_helper'

module ContextRequestMiddleware
  RSpec.describe Middleware do
    subject { described_class.new(app) }

    describe '#call' do
      let(:push_handler_name) { 'mock_push_handler' }
      let(:push_handler) { instance_double('PushHandler') }
      let(:request_options) do
        {
          message_id: '79b0824a-3a8c-452f-abd7-fc4e94f80acf',
          type: 'request'
        }
      end
      let(:context_options) do
        {
          message_id: '79b0824a-3a8c-452f-abd7-fc4e94f80acf',
          type: 'context'
        }
      end

      before do
        ENV['cookie_session.user_id'] = nil
        Timecop.freeze
        allow(ContextRequestMiddleware).to receive(:push_handler)
          .and_return(push_handler_name)
        allow(ContextRequestMiddleware::PushHandler)
          .to receive(:from_middleware).and_return(push_handler)
        allow(SecureRandom).to receive(:uuid)
          .and_return('79b0824a-3a8c-452f-abd7-fc4e94f80acf')
      end

      context 'with empty context' do
        let(:app) { MockRackApp.new }
        let(:env) do
          Rack::MockRequest.env_for('/some/path',
                                    'CONTENT_TYPE' => 'text/plain',
                                    'HTTP_X_REQUEST_START' => Time.now.to_f)
        end
        let(:request_data) do
          {
            host: 'example.org',
            request_context: nil,
            request_id: nil,
            request_method: 'GET',
            request_path: '/some/path',
            request_params: {},
            request_start_time: Time.now.to_f,
            request_status: 200,
            source: ''
          }
        end
        it do
          expect(push_handler).to receive(:push)
            .with(request_data, **request_options).and_return(nil)
          subject.call(env)
        end
      end

      context 'with context and params' do
        let(:sid) { RackSessionCookie.generate_sid }
        let(:app) { MockRackAppWithSession.new(sid) }
        let(:env) do
          Rack::MockRequest
            .env_for('/some/path',
                     'CONTENT_TYPE' => 'text/plain',
                     'HTTP_X_REQUEST_START' => Time.now.to_f,
                     :params => { 'param1' => 'param1' })
        end
        let(:request_data) do
          {
            host: 'example.org',
            request_context: sid,
            request_id: nil,
            request_method: 'GET',
            request_path: '/some/path',
            request_params: { 'param1' => 'param1' },
            request_start_time: Time.now.to_f,
            request_status: 200,
            source: ''
          }
        end
        let(:context_data) do
          {
            context_id: sid,
            owner_id: 'unknown',
            context_status: 'unknown',
            context_type: 'session_cookie',
            app_id: 'anonymous'
          }
        end
        it do
          expect(push_handler).to receive(:push)
            .with(request_data, request_options).and_return(nil)
          expect(push_handler).to receive(:push)
            .with(context_data, context_options).and_return(nil)
          subject.call(env)
        end
      end

      context 'with missing HTTP_X_REQUEST_START header' do
        let(:app) { MockRackApp.new }
        let(:env) do
          Rack::MockRequest.env_for('/some/path',
                                    'CONTENT_TYPE' => 'text/plain')
        end

        context 'and undefined Time.current method' do
          let(:request_data) do
            {
              host: 'example.org',
              request_context: nil,
              request_id: nil,
              request_method: 'GET',
              request_path: '/some/path',
              request_params: {},
              request_start_time: Time.now.to_f,
              request_status: 200,
              source: ''
            }
          end

          it do
            expect(push_handler).to receive(:push)
              .with(request_data, **request_options).and_return(nil)
            subject.call(env)
          end
        end

        context 'and available Time.current method' do
          let(:current_time) { Time.at(1_574_782_410.9173372) }
          let(:request_data) do
            {
              host: 'example.org',
              request_context: nil,
              request_id: nil,
              request_method: 'GET',
              request_path: '/some/path',
              request_params: {},
              request_start_time: current_time.to_f,
              request_status: 200,
              source: ''
            }
          end

          before do
            allow(Time).to receive(:current)
              .and_return(current_time)
          end

          it do
            expect(push_handler).to receive(:push)
              .with(request_data, **request_options).and_return(nil)
            subject.call(env)
          end
        end
      end
    end

    context 'with no sample-handler' do
      let(:sid) { RackSessionCookie.generate_sid }
      let(:app) { MockRackAppWithSession.new(sid) }
      let(:env) do
        Rack::MockRequest
          .env_for('/some/path', 'CONTENT_TYPE' => 'text/plain',
                                 'HTTP_X_REQUEST_START' => Time.now.to_f)
      end
      let(:request_data) do
        {
          app_id: 'anonymous',
          host: 'example.org',
          request_context: sid,
          request_id: nil,
          request_method: 'GET',
          request_path: '/some/path',
          request_params: {},
          request_start_time: Time.now.to_f,
          request_status: 200,
          source: ''
        }
      end
      before do
        allow(ContextRequestMiddleware).to receive(:sampling_handler)
          .and_return(nil)
      end
      it do
        expect(subject.call(env))
          .to match [200, a_hash_including('Content-Type' => 'text/plain'),
                     ['OK']]
      end
    end

    after do
      Timecop.return
    end
  end
end
