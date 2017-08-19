require "rack"
require "erb"
require "./framework"

class App < CustomFrame

  def initialize
    super
  end
  
  def call(env)
    add_route("get", "/") do
      erb("home",{display: "Hello"}, "layout")
    end

    add_route("get","/something") do
      erb "home", {display: "something"},"layout"
    end

    set_error('404') do
      "Hi. This is custom error from app.rb"
    end
    
    route_info = yield
    route(route_info)
  end
end

