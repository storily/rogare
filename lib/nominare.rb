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
    queries = Rogare::Data.all_kinds.map do |kind|
      Rogare::Data.names.where(
        Sequel.pg_array(:kinds).contains(Rogare::Data.kinds(kind))
      ).select { count('*') }.as(kind)
    end

    queries << Rogare::Data.names.select { count('*') }.as(:total)
    queries << Rogare::Data.names.where(surname: false).select { count('*') }.as(:firsts)
    queries << Rogare::Data.names.where(surname: true).select { count('*') }.as(:lasts)

    stats = Rogare.sql.select { queries }.first
    total = stats.delete :total
    firsts = stats.delete :firsts
    lasts = stats.delete :lasts

    {
      total: total,
      firsts: firsts,
      lasts: lasts,
      kinds: stats
    }.to_json
  end
end
