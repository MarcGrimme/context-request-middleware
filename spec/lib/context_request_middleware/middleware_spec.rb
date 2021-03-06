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
      let(:parameter_filter_list) do
        [
          /pass/,
          'password',
          :secret,
          'private.key',
          ->(k, v) do v.reverse! if /reversed/i.match?(k) end
        ]
      end

      before do
        Thread.current['cookie_session.user_id'] = nil
        Timecop.freeze
        allow(ContextRequestMiddleware).to receive(:push_handler)
          .and_return(push_handler_name)
        allow(ContextRequestMiddleware).to receive(:logger_tags)
          .and_return('TEST_TAG')
        allow(ContextRequestMiddleware::PushHandler)
          .to receive(:from_middleware).and_return(push_handler)
        allow(SecureRandom).to receive(:uuid)
          .and_return('79b0824a-3a8c-452f-abd7-fc4e94f80acf')
        allow(ContextRequestMiddleware).to receive(:parameter_filter_list)
          .and_return(parameter_filter_list)
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
                     :params => { 'param1' => 'param1',
                                  'password' => '123456',
                                  'key' => 'some_value',
                                  'private' => { 'key' => 'abc' },
                                  'reversed' => '123456' })
        end
        let(:request_data) do
          {
            host: 'example.org',
            request_context: sid,
            request_id: nil,
            request_method: 'GET',
            request_path: '/some/path',
            request_params: { 'param1' => 'param1',
                              'password' => '[FILTERED]',
                              'key' => 'some_value',
                              'private' => { 'key' => '[FILTERED]' },
                              'reversed' => '654321' },
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

        before do
          RequestStore.delete('cookie_session.user_id')
        end

        it do
          expect(push_handler).to receive(:push)
            .with(context_data, context_options).and_return(nil)
          expect(push_handler).to receive(:push)
            .with(request_data, request_options).and_return(nil)
          subject.call(env)
        end

        it do
          output = StringIO.new
          Logger = Logger.new(output)
          allow(push_handler).to receive(:push).and_raise(StandardError)
          expect { subject.call(env) }.to_not raise_error
          expect(output.string).to include '[TEST_TAG]'
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
          allow(push_handler).to receive(:push)
            .and_return(nil)
        end
        it do
          expect(subject.call(env))
            .to match [200, a_hash_including('Content-Type' => 'text/plain'),
                       ['OK']]
        end
      end

      context 'thread safe' do
        let(:app) { MockRackApp.new }
        let(:env) do
          Rack::MockRequest
            .env_for('/some/path', 'CONTENT_TYPE' => 'text/plain')
        end

        before do
          allow(subject).to receive(:_call)
            .and_call_original
          allow(push_handler).to receive(:push)
            .and_return(nil)
        end

        it do
          # assert that _call is called
          # on a duped instance rather than the original.
          expect(subject).not_to have_received(:_call)
          expect_any_instance_of(Middleware).to receive(:_call)
          subject.call(env)
        end
      end
    end

    after do
      Timecop.return
    end
  end
end
