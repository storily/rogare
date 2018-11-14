# frozen_string_literal: true

require './lib/logs'

logs '=====> Bootstrapping'
require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || 'production').to_sym

logs '=====> Loading framework'
require './lib/rogare'

logs '=====> Connecting to database'
Rogare.sql

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
  wars.each(&:join)
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
