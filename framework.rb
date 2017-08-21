
require 'yaml'
require 'rack'


class CustomFrame
  def initialize
    @routes={}
    @error_response = []
    @not_found = ['404', {}, ["The page you have requested cannot be found"]]
  end
  

  # Stores the return value of loading an erb template in a local variable use_template and 
  # then loads use_template  within a second layout template
  def erb(filename, locals={}, layout=nil)
    b = binding
    use_template =  template(filename, locals)
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
    to_display = locals[:display]
    load_from = File.expand_path("../views/#{filename}.erb", __FILE__)
    content = File.read(load_from)
    ERB.new(content).result(b)
  end

  # Checks if Http request matches a route in the @routes array 
  # and returns a response with the body specified 
  # in the matched route. Returns  an error message 
  # if no routes in @routes matches request.

  # The below code always returns @not_found if @not_found is places after an 'else' clause:
    # if (route[0] == http_method && route[1] == path)
      # return response
    # else
      # return @not_found
    # end
# Always returns @not_found

  def route(route_info)

    http_method = route_info[0]
    path = route_info[1]
    
    @routes.each do |route, response|
      if (route[0] == http_method && route[1] == path)
        return response
      end
    end

    @not_found
  end

  # Add a route to the @routes array. Redirect route if redirects hash contains a
  # location key and a value.

  def add_route(http_method, path, redirects={}, &block)
    response = Rack::Response.new  
    response.body = block.call

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
