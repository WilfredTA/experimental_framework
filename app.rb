require "rack"
require "erb"
require "./framework"

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

