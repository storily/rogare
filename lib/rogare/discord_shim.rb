# frozen_string_literal: true

class DiscordMessageShim
  extend Memoist

  def initialize(event, pattern, plug)
    @event = event
    @pattern = pattern[0]
    @opts = pattern[1]
    @plug = plug
  end

  def inner
    @event
  end

  def message
    @event.message.content
  end

  def params
    groups = message.match(@pattern).captures
    if groups.empty?
      [self, param]
    else
      [self, *groups]
    end
  end

  def param
    message.sub(/^\s*#{Rogare.prefix}#{@plug[:command]}/i, '')
  end

  def reply(message)
    @event.respond message
  end

  def debugly(*things)
    @event.respond things.map { |thing| "`#{thing.inspect}`" }.join("\n")
  end

  def user
    Rogare.user_cache.getset(@event.message.author.id) do
      User.create_from_discord(@event.message.author)
    end
  end

  def channel
    DiscordChannelShim.new @event.channel
  end

  memoize :user, :channel
end

class DiscordChannelShim
  def initialize(chan)
    @chan = chan
  end

  def inner
    @chan
  end

  def send(msg)
    return if @chan.voice?

    @chan.send msg
  end

  def users
    case type
    when :public
      @chan.server.members.map { |u| User.from_discord u }
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
    if @chan.server
      @chan.server.id.to_s
    else
      'PM'
    end + '/' + @chan.id.to_s
  end

  def pretty
    "#{server.name.downcase.tr(' ', '~')}/#{name}"
  end

  def server
    @chan.server
  end
end
