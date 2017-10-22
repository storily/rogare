require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || 'production').to_sym

module Rogare
  class << self
    extend Memoist

    def bot
      Cinch::Bot.new do
        configure do |c|
          c.channels = ENV['IRC_CHANNELS'].split
          c.nick = ENV['IRC_NICK']
          c.password = ENV['IRC_PASSWORD'] if ENV.include? 'IRC_PASSWORD'
          c.port = ENV['IRC_PORT'].to_i
          c.realname = ENV['IRC_REALNAME']
          c.server = ENV['IRC_SERVER']
          c.ssl.use = ENV['IRC_SSL'].to_i >= 1 if ENV.include? 'IRC_SSL'
          c.ssl.verify = ENV['IRC_SSL'].to_i >= 2 if ENV.include? 'IRC_SSL'
          c.user = ENV['IRC_USER'] if ENV.include? 'IRC_USER'
          c.plugins.plugins = Rogare::Plugins.to_a
        end
      end
    end

    def config
      c = Hashie::Mash.new
      ENV.each { |k,v| c[k.downcase] = v }
      return c
    end

    def mainchan
      Rogare.bot.channel_list.find ENV['IRC_CHANNELS'].split.first
    end

    def root
      __dir__
    end

    def template(file)
      Tilt.new(root + '/templates/' + file + '.hbs')
    end

    memoize :bot, :config, :mainchan, :root, :template
  end

  module Plugins
    def self.to_a
      self.constants.map { |c| self.const_get c }
    end
  end
end

Dir['./plugins/*.rb'].each { |p| require p }
Rogare.bot.start
