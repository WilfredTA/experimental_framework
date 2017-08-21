require "rack"
require "erb"
require "./framework"


# This simple app shows examples of how to use the 
# following features of the framework:
# 1. Setting routes
# 2. Rendering templates
# 3. Setting redirects
# 4. Rendering a template within a layout
# 5. Grabbing the route being requested
# 6. Comparing the requested route against the set routes
#   and executing the matching route

# Any app built with this framework should have a call method, 
# within which the following is done in the order listed below:
# First, routes are added
# Second, logic is added to routes, as are view templates
# Third, grab the requested route with 'get_requested_route(env)'
# Fourth, pass the requested route into the 'route' method

# The framework makes the following assumptions:
# That you are using ERB as your templating engine
# That your templates are stored in a directory called 'views'
# That you are using routes to generate responses

class App < CustomFrame

  def initialize
    super
  end
  
  def call(env)
    add_route("get", "/") do
      erb("home",{display: "Hello"}, "layout")
    end

    add_route("get","/something", {location: '/'}) do

      erb "home", {display: "something"},"layout"
    end


    
    route_info = get_requested_route(env)
    route(route_info)
  end
end

