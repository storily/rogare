require './lib/logs'

logs '=====> Bootstrapping'
require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || 'production').to_sym

logs '=====> Loading framework'
require './lib/rogare'

logs '=====> Loading modules'
Dir['./plugins/*.rb'].each do |p|
  require p
end

logs '=====> Preparing threads'
require 'thwait'
threads = []

threads << Thread.new do
  sleep 3
  logs '=====> Loading wordwars from Redis'
  wars = Rogare::Plugins::Wordwar.load_existing_wars
  logs "=====> Loaded #{wars.count} wordwars, now waiting on timers"
  wars.each { |t| t.join }
end

threads << Thread.new do
  logs '=====> Preparing live debug port'
  binding.remote_pry
end

threads << Thread.new do
  logs '=====> Starting Discord'
  Rogare.discord.run
end

ThreadsWait.all_waits(*threads)
