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

    def redis(n)
      if ENV['RACK_ENV'] == 'production'
        redis(0)
      else
        Redis.new db: n
      end
    end

    memoize :bot, :config, :mainchan, :redis
  end

  module Plugins
    def self.to_a
      self.constants.map { |c| self.const_get c }
    end
  end
end
