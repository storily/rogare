# frozen_string_literal: true

require 'rack/protection'

class Nominare < Sinatra::Application
  use Rack::Protection, except: %i[session_hijacking remote_token]

  get '/' do
    'Hello world!'
  end
end
