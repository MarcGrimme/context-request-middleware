# frozen_string_literal: true

require 'rack/session/abstract/id'

module RackSessionCookie
  def set_cookie_in_response(response, req)
    options = req.session_options
    cookie = {}
    cookie[:value] = req.session[:id]
    cookie[:expires] = Time.now
    cookie[:expires] = Time.now
    response.set_cookie(options[:key], cookie)
  end

  def generate_session(req, sid)
    session_was = req.get_header Rack::RACK_SESSION
    session = req.session
    req.set_header Rack::RACK_SESSION, session
    req.set_header Rack::RACK_SESSION_OPTIONS,
                   Rack::Session::Abstract::Persisted::DEFAULT_OPTIONS.dup
    session.merge! session_was if session_was
    session[:id] = sid
    session
  end

  def self.generate_sid(_secure = false, sid_bits = 128)
    format("%0#{sid_bits / 4}x", Kernel.rand(2**sid_bits - 1))
  end
end
