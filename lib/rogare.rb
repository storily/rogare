
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
          Rogare::Plugins.config(c)
        end
      end
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

    memoize :bot, :config, :nixnotif, :redis
  end

  module Plugins
    def self.to_a
      self.constants.map { |c| self.const_get c } + (@@custom_plugins || [])
    end

    def self.config(c)
      @@custom_configs.each do |fn|
        fn.call(c)
      end
    end

    def self.add_plugin(const, &block)
      @@custom_plugins ||= []
      @@custom_plugins << const
      @@custom_configs ||= []
      @@custom_configs << block
    end
  end

  module Help
    @@helps = {}

    def self.helps
      @@helps
    end

    def myhelp
      @@helps[self.inspect.to_sym] ||= { aliases: [] }
    end

    def myhelp=(val)
      @@helps[self.inspect.to_sym] = val
    end

    def command(c, opts = {})
      opts[:hidden] || false
      myhelp.merge!(opts)
      myhelp[:command] = c
    end

    def aliases(*a)
      myhelp[:aliases] = a
    end

    def usage(message)
      myhelp[:usage] = [message].flatten.compact
    end

    def handle_help
      match_command /((-|--)?(help|usage)|-?\?)\s*$/, method: :help_message
      h = myhelp
      define_method :help_message do |m|
        m.reply "No help message :(" if h[:usage].empty?
        usage = h[:usage].map do |line|
          line.gsub('!%', "!#{h[:command]}")
        end

        usage[0] = "Usage: #{usage[0]}"
        usage.each {|l| m.reply(l) }
      end
    end

    def match_command(pattern = nil, opts = {})
      pattern = pattern.source if pattern.respond_to? :source
      excl = if myhelp[:include_command] then '' else '?:' end
      pat = "(#{excl}#{[myhelp[:command], *myhelp[:aliases]].map {|c| Regexp.escape(c)}.join('|')})"
      pat = "#{pat}\\s+#{pattern}" if pattern
      logs '       matching: ' + pat.inspect
      opts[:group] ||= :commands
      match Regexp.new(pat, Regexp::IGNORECASE), opts
    end

    def match_empty(method, opts = {})
      opts[:method] ||= method
      match_command(nil, opts)
    end
  end
end
