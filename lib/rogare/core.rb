module Rogare
  class << self
    extend Memoist

    @@boot = Time.now
    def boot
      @@boot
    end

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
      bot
    end

    def config
      c = Hashie::Mash.new
      ENV.each { |k,v| c[k.downcase] = v }
      return c
    end

    def redis(n)
      if ENV['REDIS_URL']
        Redis.new
      else
        Redis.new db: n
      end
    end

    def from_discord_mid(mid)
      id = mid.gsub(/[^\d]/, '').to_i
      du = discord.users[id]
      return unless du
      DiscordUserShim.new(du)
    end

    def nixnotif(nick)
      # If we get a mentionable discord ID, lookup the user and retrieve a nick:
      if discord && nick =~ /<@\d+>/
        du = from_discord_mid(nick)
        nick = du.nick if du
      end

      # Insert a zero-width space as the second character of the nick
      # so that it doesn't notify that user. People using web clients
      # or desktop clients shouldn't see anything, people with terminal
      # clients may see a space, and people with bad clients may see a
      # weird box or invalid char thing.
      nick.sub(/^(.)/, "\\1\u200B")
    end

    def channel_list(opts = {})
      opts[:irc] = true
      opts[:discord] = true

      list = []

      if irc && opts[:irc]
        irc.channel_list do |chan|
          list << chan
        end
      end

      if discord && opts[:discord]
        discord.servers.each do |id, srv|
          srv.channels.each do |chan|
            list << DiscordChannelShim.new(chan)
          end
        end
      end

      list
    end

    # MAY RETURN AN ARRAY (if multiple chans match) so ALWAYS HANDLE THAT
    # unless you're always passing slashed chan names
    def find_channel(name)
      if name.include? '/'
        return unless discord
        sid, cid = name.split('/')

        server = discord.servers[sid.to_i]
        return unless server

        chan = server.channels.find {|c| c.id.to_s == cid }
        return unless chan

        DiscordChannelShim.new chan
      elsif discord
        chans = channel_list(irc: false).select {|c| c.name == name }
        if chans.count == 1
          chans.first
        elsif chans.count > 1
          chans
        end
      elsif irc
        irc.channel_list.find name
      end
    end

    memoize :irc, :discord, :config, :nixnotif, :redis
  end
end
