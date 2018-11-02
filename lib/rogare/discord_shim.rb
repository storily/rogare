class DiscordMessageShim
  def initialize(event, pattern, plug)
    @event = event
    @pattern = pattern[0]
    @opts = pattern[1]
    @plug = plug
  end

  def params
    msg = @event.message.content
    groups = msg.match(@pattern).captures
    if groups.empty?
      [self, param]
    else
      [self, *groups]
    end
  end

  def param
    msg = @event.message.content
    msg.sub(/^\s*!#{@plug[:command]}/i, '')
  end

  def reply(message)
    @event.respond message
  end

  def user
    DiscordUserShim.new @event.message.author
  end

  def channel
    DiscordChannelShim.new
  end
end

class DiscordUserShim
  def initialize(member)
    @member = member
  end

  def discordian?
    true
  end

  def nick
    @member.nick || @member.username
  end
end

class DiscordChannelShim
  def initialize()
  end

  def users
    {}
  end
end
