require 'rack'

module Hatchet
  class CustomFrame
    def initialize
      @routes={}
      @error_response = []
      @not_found = ['404', {}, ["The page you have requested cannot be found"]]
    end
  

  # Stores the return value of loading an erb template in a local variable use_template and 
  # then loads use_template  within a second layout template. View templates
  # access the locals via 'locals[:key]' syntax in the template itself.
    def erb(filename, locals={}, layout=nil)
      b = binding
      use_template =  template(filename, locals)
      locals = locals
      if layout
        layout =  File.expand_path("../views/#{layout}.erb",__FILE__)
        content = File.read(layout)
        ERB.new(content).result(b)
      else
        use_template
      end
    end


  # Stores variables to display in a local variable to_display and loads them within an erb template
    def template(filename, locals={})
      b = binding
      to_display = locals
      load_from = File.expand_path("../views/#{filename}.erb", __FILE__)
      content = File.read(load_from)
      ERB.new(content).result(b)
    end

  # Checks if Http request matches a route in the @routes array 
  # and returns a response with the body specified 
  # in the matched route. Returns a not found message
  # if no routes in @routes matches request.

  # The below method also expects that you only pass in env if the app is middleware. 
  # The app must not pass in env to `route`, because the app is at the end of the middleware
  # chain, and must return @not_found if the @routes hash does not contain the requested route.
  # 
  # If the @routes hash doesn't include the requested route and env evaluates to true,
  # the next app down the middleware chain is called.
  # If the @routes hash doesn't include the requested route and env is nil,
  # The else clause executes
  # This means that the middleware chain will stop executing down the chain.
  # 
  # So, pass env to `route` if you want an app lower down in the middleware chain to execute
  # if the requested route is not found. My suggestion is to pass env to every middleware that you `use`
  # in config.ru and do NOT pass it to the app that you `run` in config.ru. 


    def route(route_info, env=nil)
      if ((!@routes.keys.include?(route_info)) && env)
          @app.call(env)
      else
        http_method = route_info[0]
        path = route_info[1]
    
        @routes.each do |route, response|
          if (route[0] == http_method && route[1] == path)
            response[2][0] = response[2][0].call
            return response
          end
        end

        @not_found
      end
    end

  # Add a route to the @routes array. Redirect route if redirects hash contains a
  # location key and a value.

    def add_route(http_method, path, redirects={}, &block)
      response = Rack::Response.new  
      response.body = block

      if redirects[:location]
        response.headers["Location"] = redirects[:location]
        response.status = '302'
      end

      @routes[[http_method, path]] = [response.status, response.headers, [response.body]]
    end

  # Gets the http method and path from the env and returns, 
  # a convenient array containing those values. Since routes are stored 
  # in @routes and defined by a http request method and request path, 
  # this provides a convenient way to match the clients request against a route in @routes
    def get_requested_route(env)
      request = Rack::Request.new(env)
    
      http_method = request.request_method.downcase
      path = request.path_info

      [http_method, path]
    end

  # Returns the error response
    def error
       @error_response
    end

  # Stores the return value of the passed in block as the body of the error response. 
  # Returns an array containing the status, headers, and the return value of the block.
    def set_error(status)
      error_response = Rack::Response.new
      error_response.status = status
      @error_response = error_response.finish {yield}
    end


  # Allows you to specify your own not found Rack response
    def not_found
      @not_found = yield
    end

  end 
end

