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
    DiscordChannelShim.new @event.channel
  end
end

class DiscordUserShim
  def initialize(member)
    @member = member
  end

  def discordian?
    true
  end

  def id
    @member.id
  end

  # Mentionable ID
  def mid
    "<@#{id}>"
  end

  def nick
    n = nil
    n ||= @member.nick if @member.is_a? Discordrb::Member
    n ||= @member.username if @member.is_a? Discordrb::User
    n || '?'
  end
end

class DiscordChannelShim
  def initialize(chan)
    @chan = chan
  end

  def send(msg)
    @chan.send msg, type == :voice
  end

  def users
    case type
    when :public
      @chan.server.members.map {|u| DiscordUserShim.new u}
    else
      []
    end
  end

  # Practically, channels other than public aren't supported
  def type
    case @chan.type
    when 0
      :public
    when 1
      :private
    when 2
      :voice
    when 3
      :group
    end
  end

  def name
    @chan.name
  end

  def to_s
    @chan.server.id.to_s + '/' + @chan.id.to_s
  end
end
