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

    def discord
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
      if nick =~ /<@\d+>/
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

    def channel_list
      list = []

      discord.servers.each do |id, srv|
        srv.channels.each do |chan|
          list << DiscordChannelShim.new(chan)
        end
      end

      list
    end

    # MAY RETURN AN ARRAY (if multiple chans match) so ALWAYS HANDLE THAT
    # unless you're always passing slashed chan names
    # Note that non-ID slashed names can be collided.
    def find_channel(name)
      if name.include? '/'
        sid, cid = name.split('/')

        server = discord.servers[sid.to_i]
        server ||= (discord.servers.find {|i, s| s.name.downcase.gsub(' ', '~') == sid.downcase } || [])[1]
        return unless server

        chan = server.channels.find {|c| c.id.to_s == cid || c.name == cid }
        return unless chan

        DiscordChannelShim.new chan
      else
        chans = channel_list.select {|c| c.name == name }
        if chans.count == 1
          chans.first
        elsif chans.count > 1
          chans
        end
      end
    end

    memoize :discord, :config, :nixnotif, :redis
  end
end
