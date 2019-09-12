# frozen_string_literal: true

class MockRackApp
  def initialize; end

  def call(_env)
    [200, { 'Content-Type' => 'text/plain' }, ['OK']]
  end
end

class MockRackAppWithSession
  include RackSessionCookie
  def initialize(sid)
    @sid = sid
  end

  def call(env)
    req = Rack::Request.new(env)
    res = Rack::Response.new(['OK'], 200, 'Content-Type' => 'text/plain')
    generate_session(req, @sid)

    set_cookie_in_response(res, req)
    res.finish
    [res.status, res.header, res.body]
  end
end
