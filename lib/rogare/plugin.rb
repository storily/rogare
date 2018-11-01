module Rogare::Plugin
  @@mine = {}

  def self.extended(base)
    logs "     > Loading #{base}"
    base.define_method :initialize do |bot, type = :irc|
      super bot if type == :irc
    end
  end

  def self.allmine
    @@mine
  end

  def my
    @@mine[self.inspect.to_sym] ||= {
      aliases: [],
      patterns: [],
    }
  end

  def my=(val)
    @@mine[self.inspect.to_sym] = val
  end

  def command(c, opts = {})
    opts[:hidden] || false
    my.merge!(opts)
    my[:command] = c
  end

  def aliases(*a)
    my[:aliases] = a
  end

  def usage(message)
    my[:usage] = [message].flatten.compact
  end

  def handle_help
    match_command /((-|--)?(help|usage)|-?\?)\s*$/, method: :help_message
    h = my
    define_method :help_message do |m|
      m.reply "No help message :(" if h[:usage].empty?
      usage = h[:usage].map do |line|
        line.gsub('!%', "!#{h[:command]}")
      end

      usage[0] = "Usage: #{usage[0]}"
      usage.each {|l| m.reply(l) }
    end
  end

  def match_message(pattern, opts = {})
    match(pattern, opts) if Rogare.irc

    # We don't have the cinch framework to do work for us here, so to watch for
    # multiple patterns there's two approaches. This one is to compile a single
    # pattern as they come in, and then re-match the event in priority order.
    # To compile the pattern, we remove the existing handler, add the new pattern
    # to the common pattern, re-add a handler. It's a bit messy but keeps from
    # adding boilerplate to the plugins / removing dynamism.

    if Rogare.discord
      opts[:method] ||= :execute

      my[:patterns] << [/!#{pattern}/, opts]
      my[:common_pattern] = Regexp.union my[:patterns].map{|pat| pat[0]}

      Rogare.discord.remove_handler my[:discord_handler] if my[:discord_handler]
      my[:discord_handler] = Rogare.discord.message(contains: my[:common_pattern]) do |event|
        pattern = my[:patterns].find {|pat| pat[0] =~ event.message.content}
        plug = new nil, :discord

        params = DiscordMessageShim.new(event, pattern, my).params
        meth = pattern[1][:method]
        arty = plug.method(meth).arity
        params = params.first(arty) if arty > 0
        plug.send meth, *params
      end
    end
  end

  def match_command(pattern = nil, opts = {})
    pattern = pattern.source if pattern.respond_to? :source
    excl = if my[:help_includes_command] then '' else '?:' end
    pat = "(#{excl}#{[my[:command], *my[:aliases]].map {|c| Regexp.escape(c)}.join('|')})"
    pat = "#{pat}\\s+#{pattern}" if pattern
    logs '       matching: ' + pat.inspect
    opts[:group] ||= :commands
    match_message Regexp.new(pat, Regexp::IGNORECASE), opts
  end

  def match_empty(method, opts = {})
    opts[:method] ||= method
    match_command(nil, opts)
  end
end