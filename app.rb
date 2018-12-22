# frozen_string_literal: true

require './cli'

logs '=====> Loading commands'
Dir['./commands/*.rb'].each do |p|
  name = Pathname.new(p).basename('.rb').to_s
  if ENV['COMMANDS_WHITELIST']
    next unless ENV['COMMANDS_WHITELIST'].split(',').include? name
  end

  require p
end

logs '=====> Preparing threads'
require 'thwait'
threads = []

if ENV['RACK_ENV'] == 'production' || ENV['DEV_LOAD_WARS']
  threads << Thread.new do
    sleep 3
    logs '=====> Loading wordwars from Postgres'
    wars = War.start_timers_for_existing
    logs "=====> Loaded #{wars.count} wordwars, now waiting on timers"
    wars.each(&:join)
  end
end

if ENV['RACK_ENV'] == 'production'
  threads << Thread.new do
    logs '=====> Preparing live debug port'
    binding.remote_pry
  end
end

threads << Thread.new do
  logs '=====> Starting Discord'
  Rogare.discord.run
end

threads << Thread.new do
  logs '=====> Starting Nominare'
  require './lib/nominare'
  Nominare.run!
end

ThreadsWait.all_waits(*threads)
