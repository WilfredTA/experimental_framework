class CustomFrame
  def initialize
    @routes={}
    @error_response = []
  end
  def response(status, headers, body='')
    body =  yield if block_given?
    [status, headers,[body]]
  end

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


  
  def template(filename, locals={})
    b = binding
    to_display = locals[:display]
    load_from = File.expand_path("../views/#{filename}.erb", __FILE__)
    content = File.read(load_from)
    ERB.new(content).result(b)
  end

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

  def add_route(method, path, &block)
    @routes[[method, path]] = block
  end

  def error
     @error_response
  end

  def set_error(status, headers={})
    error_response =  yield if block_given?
    @error_response = [status, headers,[error_response]]
  end
end
