require './lib/logs'

logs '=====> Bootstrapping'
require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || 'production').to_sym

logs '=====> Loading framework'
require './lib/rogare'

logs '=====> Loading modules'
Dir['./plugins/*.rb'].each do |p|
  logs "     > Loading #{p}"
  require p
end

Thread.new do
  sleep 3
  logs '=====> Loading wordwars from Redis'
  wars = Rogare::Plugins::Wordwar.load_existing_wars
  logs "=====> Loaded #{wars.count} wordwars, now waiting on timers"
  wars.each { |t| t.join }
end

Thread.new do
  binding.remote_pry
end

logs '=====> Starting bot'
Rogare.bot.start
