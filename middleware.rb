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
