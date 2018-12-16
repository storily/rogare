# frozen_string_literal: true

require 'rack/protection'

class Nominare < Sinatra::Application
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
