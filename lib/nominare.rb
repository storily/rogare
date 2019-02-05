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
      '/random?n=N' => 'Returns N (1 <= N <= 100) names at random.',
      '/search?q=...' => 'Perform a search and return some random names from it.',
      '/details?name=...' => 'Returns details and scoring for a particular name.',
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

  get '/random' do
    n = params['n'].to_i
    n = 5 if n < 1
    n = 100 if n > 100

    Name.fulls(n: n).map { |fl| { first: fl[0], last: fl[1] } }.to_json
  end

  get '/search' do
    query = params['q'] || ''
    args = { kinds: [], full: true, freq: [nil, nil], also: [] }
    args[:n] = NumbersInWords.in_numbers(query.strip)

    words = query.downcase.strip.split(' ')
    words.map! do |word|
      if word.to_i.to_s == word
        word.to_i
      else
        word
      end
    end

    words.each do |word|
      Name.parse_word(args, word)
    end

    args[:n] = 100 if args[:n] > 100
    args[:n] = 5 if args[:n] < 1
    lasts = args[:kinds].include? 'last'

    if args[:full]
      names = Name.fulls(args)
                  .map { |fl| { first: fl[0], last: fl[1] } }
    else
      names = Name.search(args)
      if lasts
        names.map! { |name| { last: name } }
      else
        names.map! { |name| { first: name } }
      end
    end

    names.to_json
  end

  get '/details' do
    name = params['name'] || ''
    name = name.strip.downcase
    halt 400 if name.empty?

    details = {}
    Name.where(name: name).each do |info|
      key = info.surname ? :last : :first
      kinds = info.kinds.gsub(/[\{\}]/, '').split(',')
      kinds -= %w[first last]

      details[key] = {
        name: Name.format(name),
        kinds: kinds,
        sources: info.sources,
        score: info.score
      }
    end

    details.to_json
  end
end
