module Rogare
  class << self
    extend Memoist

    def prefix
      '!'
    end

    def irc
      return unless ENV['IRC_SERVER'] && ENV['IRC_CHANNELS']

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
          Rogare::Plugins.config(c)
        end
      end
    end

    def discord
      return unless ENV['DISCORD_TOKEN']

      bot = Discordrb::Bot.new token: ENV['DISCORD_TOKEN']
      puts "This bot's discord invite URL is #{bot.invite_url}."
      bot.message(content: 'Ping!') do |event|
        event.respond 'Pong!'
      end
      bot
    end

    def config
      c = Hashie::Mash.new
      ENV.each { |k,v| c[k.downcase] = v }
      return c
    end

    def redis(n)
      if ENV['RACK_ENV'] == 'production'
        Redis.new
      else
        Redis.new db: n
      end
    end

    def nixnotif(nick)
      # Insert a zero-width space as the second character of the nick
      # so that it doesn't notify that user. People using web clients
      # or desktop clients shouldn't see anything, people with terminal
      # clients may see a space, and people with bad clients may see a
      # weird box or invalid char thing.
      nick.sub(/^(.)/, "\\1\u200B")
    end

    memoize :irc, :discord, :config, :nixnotif, :redis
  end
end
