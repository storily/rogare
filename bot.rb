require './lib/logs'

logs '=====> Bootstrapping'
require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || 'production').to_sym

logs '=====> Loading framework'
require './lib/rogare'

if ENV['NICKSERV_USER'] && ENV['NICKSERV_PASS']
  logs '=====> Loading identify plugin'
  require 'cinch/plugins/identify'
  Rogare::Plugins.add_plugin(Cinch::Plugins::Identify) do |c|
    c.plugins.options[Cinch::Plugins::Identify] = {
      username: ENV['NICKSERV_USER'],
      password: ENV['NICKSERV_PASS'],
      type: :nickserv,
    }
  end
end

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
