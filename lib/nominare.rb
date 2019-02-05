# frozen_string_literal: true

require 'rack/protection'

class Nominare < Sinatra::Application
  register Sinatra::Cors

  set :allow_origin, 'http://localhost:8000 https://cogitare.nz https://dicere.cogitare.nz'
  set :allow_methods, 'GET,HEAD'
  set :allow_headers, 'content-type,if-modified-since'
  set :expose_headers, 'location,link'

  use Rack::Protection, except: %i[session_hijacking remote_token]

  before do
    content_type :json
  end

  get '/' do
    { endpoints: {
      '/kinds.png' => 'Map of rough regions described by the kinds values. ' \
        'Hand-made and may not reflect current availability.',
      '/stats' => 'Totals and subtotals about the *scored* dataset ' \
        '(stats from the raw data not available).'
    } }.to_json
  end

  get '/kinds.png' do
    content_type :png
    send_file File.expand_path('kinds.png')
  end

  get '/stats' do
    Name.stats.to_json
  end
end
