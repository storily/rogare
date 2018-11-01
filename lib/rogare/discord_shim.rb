class DiscordMessageShim
  def initialize(event, pattern, plug)
    @event = event
    @pattern = pattern[0]
    @opts = pattern[1]
    @plug = plug
  end

  def params
    msg = @event.message.content
    param = msg.sub(/^!#{@plug[:command]}/i, '')
    groups = msg.match(@pattern).captures
    [self, param, *groups]
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
