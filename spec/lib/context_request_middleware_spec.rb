# frozen_string_literal: true

require 'spec_helper'

module TestLc
  module TestLc
    module V1
      class TestLc
      end
    end
    class TestLc
    end
  end
end

RSpec.describe ContextRequestMiddleware do
  describe '#load_class_from_name' do
    it do
      expect(ContextRequestMiddleware
        .load_class_from_name('unknown', 'Path::Path'))
        .to be_nil
    end

    it do
      expect(ContextRequestMiddleware
        .load_class_from_name('test_lc1', 'TestLc::TestLc'))
        .to be_nil
    end

    it do
      expect(ContextRequestMiddleware
        .load_class_from_name('test_lc', 'TestLc::TestLc'))
        .to eq(TestLc::TestLc::TestLc)
    end

    it do
      expect(ContextRequestMiddleware
        .load_class_from_name('test_lc', 'TestLc::TestLc', 1))
        .to eq(TestLc::TestLc::V1::TestLc)
    end
  end

  describe '#select_request_headers' do
    let(:env) do
      Rack::MockRequest.env_for('/some/path', 'CONTENT_TYPE' => 'text/plain')
    end
    let(:headers) { ['HTTP_X_REQUEST_ID'] }
    let(:uuid) { '0fe9525b-27ed-49e3-be42-15c54c3cf8ef' }

    it do
      expect(ContextRequestMiddleware
        .select_request_headers(headers, Rack::Request.new(env))).to be_nil
    end

    it do
      headers = %w[HTTP_X_REQUEST1_ID HTTP_X_REQUEST_ID]
      env['HTTP_X_REQUEST_ID'] = uuid
      expect(ContextRequestMiddleware
        .select_request_headers(headers, Rack::Request.new(env)))
        .to eq uuid
    end

    it do
      headers = %w[HTTP_X_REQUEST_ID HTTP_X_REQUEST1_ID]
      env['HTTP_X_REQUEST_ID'] = uuid
      expect(ContextRequestMiddleware
        .select_request_headers(headers, Rack::Request.new(env)))
        .to eq uuid
    end

    it do
      headers = %w[HTTP_X_REQUEST_ID HTTP_X_REQUEST1_ID]
      env['HTTP_X_REQUEST1_ID'] = '371c4a54-1777-44da-aada-ce1883ac8e3e'
      env['HTTP_X_REQUEST_ID'] = uuid
      expect(ContextRequestMiddleware
        .select_request_headers(headers, Rack::Request.new(env)))
        .to eq uuid
    end
  end
end
