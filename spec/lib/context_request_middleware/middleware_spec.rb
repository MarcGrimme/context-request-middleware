# frozen_string_literal: true

require 'spec_helper'
require 'context_request_middleware/request'
require 'context_request_middleware/context'

module ContextRequestMiddleware
  RSpec.describe Middleware do
    subject { described_class.new(app) }

    describe '#call' do
      let(:push_handler_name) { 'mock_push_handler' }
      let(:push_handler) { instance_double('PushHandler') }

      before do
        Timecop.freeze
        allow(ContextRequestMiddleware).to receive(:push_handler)
          .and_return(push_handler_name)
        allow(ContextRequestMiddleware::PushHandler)
          .to receive(:from_middleware).and_return(push_handler)
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
            app_id: 'anonymous',
            host: 'example.org',
            request_context: nil,
            request_id: nil,
            request_method: 'GET',
            request_path: '/some/path',
            request_params: {},
            request_start_time: Time.now.to_f,
            request_status: 200,
            source: nil
          }
        end
        it do
          expect(push_handler).to receive(:push)
            .with(request_data).and_return(nil)
          expect(push_handler).to receive(:push).with({}).and_return(nil)
          subject.call(env)
        end
      end

      context 'with rack-session context and params' do
        let(:sid) { RackSessionCookie.generate_sid }
        let(:app) { MockRackAppWithSession.new(sid) }
        let(:env) do
          Rack::MockRequest
            .env_for('/some/path',
                     'CONTENT_TYPE' => 'text/plain',
                     'HTTP_X_REQUEST_START' => Time.now.to_f,
                     'rack.request.cookie_hash' =>
                        { '_session_id' => '9bc829f0119b1f1647359ece68dc7b28' },
                     :params => { 'param1' => 'param1' })
        end
        let(:request_data) do
          {
            app_id: 'anonymous',
            host: 'example.org',
            request_context: '9bc829f0119b1f1647359ece68dc7b28',
            request_id: nil,
            request_method: 'GET',
            request_path: '/some/path',
            request_params: { 'param1' => 'param1' },
            request_start_time: Time.now.to_f,
            request_status: 200,
            source: nil
          }
        end
        let(:context_data) do
          {
            context_id: sid,
            context_status: 'unknown',
            context_type: 'session_cookie',
            owner_id: '123'
          }
        end
        it do
          expect(push_handler).to receive(:push)
            .with(request_data).and_return(nil)
          expect(push_handler).to receive(:push)
            .with(context_data).and_return(nil)
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
          request_context: '9bc829f0119b1f1647359ece68dc7b28',
          request_id: nil,
          request_method: 'GET',
          request_path: '/some/path',
          request_params: {},
          request_start_time: Time.now.to_f,
          request_status: 200,
          source: nil
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
