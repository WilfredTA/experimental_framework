class CustomFrame
  def initialize
    @routes={}
    @error_response = []
  end
  
  def response(status, headers, body='')
    body =  yield if block_given?
    [status, headers,[body]]
  end
  
  # Stores the return value of loading an erb template in a local variable use_template and then loads use_template  within a second layout template
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


  # Stores variables to display in a local variae to_display and loads them within an erb template
  def template(filename, locals={})
    b = binding
    to_display = locals[:display]
    load_from = File.expand_path("../views/#{filename}.erb", __FILE__)
    content = File.read(load_from)
    ERB.new(content).result(b)
  end

  # Checks if Http request matches a route in the @routes array and returns a reaponse with the body specified in the matched route. Returns  an error message ir no routes in @routes matches request.
  def route(route_info, status='200', headers={}\
)
    method = route_info[0]
    path = route_info[1]
    body = nil
    @routes.each do |route, proc|
     body =  proc.call if (route[0] == method &&\
 route[1] == path)
    end
    return  error unless body

    [status, headers,[body]]
  end

  # Add a route to the @routes array
  def add_route(method, path, &block)
    @routes[[method, path]] = block
  end

  # Returns the error response
  def error
     @error_response
  end

  # Stores the return value of the passed in block as the body of the error response. Returns an array containing the status, headers, and the return value of the block.
  def set_error(status, headers={})
    error_response =  yield if block_given?
    @error_response = [status, headers,[error_response]]
  end
end
