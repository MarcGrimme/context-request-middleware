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

  def call(_env)
    res = Rack::Response.new(['OK'], 200, 'Content-Type' => 'text/plain')

    Rack::Utils.set_cookie_header!(res.header, '_session_id', @sid) if @sid
    res.finish
    [res.status, res.header, res.body]
  end
end
