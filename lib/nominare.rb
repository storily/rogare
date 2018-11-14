require 'rack/protection'

class Nominare < Sinatra::Application
  use Rack::Protection, except: [:session_hijacking, :remote_token]

  get '/' do
    'Hello world!'
  end
end
