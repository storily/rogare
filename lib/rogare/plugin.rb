# frozen_string_literal: true

module Rogare::Plugin
  @@mine = {}

  def self.extended(base)
    logs "     > Loading #{base}"
  end

  def self.allmine
    @@mine
  end

  def my
    @@mine[inspect.to_sym] ||= {
      aliases: [],
      patterns: []
    }
  end

  def my=(val)
    @@mine[inspect.to_sym] = val
  end

  def command(comm, opts = {})
    opts[:hidden] || false
    my.merge!(opts)
    my[:command] = comm
  end

  def aliases(*aliases)
    my[:aliases] = aliases
  end

  def usage(message)
    my[:usage] = [message].flatten.compact
  end

  def before_handler(&block)
    my[:before_handler] = block
  end

  def handle_help
    match_command /((-|--)?(help|usage)|-?\?)\s*$/, method: :help_message
    h = my # Not useless! Will break if you remove
    define_method :help_message do |m|
      m.reply 'No help message :(' if h[:usage].empty?
      usage = h[:usage].map do |line|
        line.gsub('!%', "!#{h[:command]}")
      end

      usage[0] = "Usage: #{usage[0]}"
      m.reply usage.join("\n")
    end
  end

  def match_message(pattern, opts = {})
    # We don't have the cinch framework to do work for us anymore, so to watch
    # multiple patterns there's two approaches. This one is to compile a single
    # pattern as they come in, and then re-match the event in priority order.
    # To compile the pattern, we remove the existing handler, add the new pattern
    # to the common pattern, re-add a handler. It's a bit messy but keeps from
    # adding boilerplate to the plugins / removing dynamism.

    opts[:method] ||= :execute

    logs '       matching: ' + pattern.inspect
    my[:patterns] << [/^\s*!#{pattern}/, opts]
    my[:common_pattern] = Regexp.union(my[:patterns].map { |pat| pat[0] })

    Rogare.discord.remove_handler my[:discord_handler] if my[:discord_handler]
    my[:discord_handler] = Rogare.discord.message(contains: my[:common_pattern]) do |event|
      logs "---> Discord message: ‘#{event.message.content}’ from #{event.author.username} (#{event.author.id})"
      logs "---> Handling by #{self}"

      pattern = my[:patterns].find { |pat| pat[0] =~ event.message.content }
      logs "---> Detected pattern: #{pattern[0]} (#{pattern[1]})"

      plug = new
      params = DiscordMessageShim.new(event, pattern, my).params
      meth = pattern[1][:method]

      if my[:before_handler]
        logs 'Running before_handler'
        if my[:before_handler].call(meth, *params) == :stop
          logs 'before_handler says to stop'
          next
        end
      end

      arty = plug.method(meth).arity
      params = params.first(arty) if arty.positive?
      plug.send meth, *params
    end
  end

  def match_command(pattern = nil, opts = {})
    pattern = pattern.source if pattern.respond_to? :source
    excl = my[:help_includes_command] ? '' : '?:'
    pat = "(#{excl}#{[my[:command], *my[:aliases]].map { |c| Regexp.escape(c) }.join('|')})"
    pat = "#{pat}\\s+#{pattern}" if pattern
    match_message Regexp.new(pat, Regexp::IGNORECASE), opts
  end

  def match_empty(method, opts = {})
    opts[:method] ||= method
    match_command(nil, opts)
  end
end
