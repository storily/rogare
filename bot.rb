def logs(msg)
  puts msg
  STDOUT.flush
end

logs '=====> Bootstrapping'
require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || 'production').to_sym

logs '=====> Loading framework'
require_relative 'lib/rogare.rb'

logs '=====> Loading modules'
Dir['./plugins/*.rb'].each do |p|
  logs "     > Loading #{p}"
  require p
end

Thread.new do
  sleep 3
  logs '=====> Loading wordwars from Redis'
  n = Rogare::Plugins::Wordwar.load_existing_wars.each { |t| t.join }.count
  logs "=====> Loaded #{n} wordwars"
end

logs '=====> Starting bot'
Rogare.bot.start
