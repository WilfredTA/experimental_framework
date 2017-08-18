require "rack"
require "erb"


class CustomFrame
  def initialize
    @routes={}
  end
  def response(status, headers, body='')
    body =  yield if block_given?
    [status, headers,[body]]
  end

  def template(filename, locals={})
    b = binding
    to_display = locals[:display]
    load_from = File.expand_path("../views/#{filename}.erb", __FILE__)
    content = File.read(load_from)
    ERB.new(content).result(b)
  end

  def route(route_info, status='200', headers={})
    method = route_info[0]
    path = route_info[1]
    body = nil
    @routes.each do |route, proc|
     body =  proc.call if (route[0] == method && route[1] == path)
    end

    [status, headers,[body]]
  end

  def add_route(method, path, &block)
    @routes[[method, path]] = block
  end
end


class App < CustomFrame

  def initialize
    super
  end
  def call(env)
    add_route("get", "/") do
      template "home", display: "Hello World!"
    end

    add_route("get","/something") do
      template "home", display: "something"
    end
    
    route_info = yield
    route(route_info)
  end
end

class Router
  def initialize(app)
    @app = app
  end

  def call(env)
    req_method = env['REQUEST_METHOD'].downcase
    path = env['REQUEST_PATH'].downcase
    @app.call(env) { [req_method, path]}
  end
end


