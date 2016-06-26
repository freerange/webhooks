class ForceJsonContentTypeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    env['CONTENT_TYPE'] = 'application/json'
    @app.call(env)
  end
end
