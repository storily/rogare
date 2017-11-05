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

    memoize :bot, :config, :redis
  end

  module Plugins
    def self.to_a
      self.constants.map { |c| self.const_get c }
    end
  end

  module Help
    @@helps = {}

    def self.extended(mod)
      @@helpname = mod.inspect.to_sym
      @@helps[@@helpname] = { aliases: [] }
      @@help = @@helps[@@helpname]
    end

    def self.helps
      @@helps
    end

    def command(c, opts = {})
      opts[:hidden] || false
      @@help.merge!(opts)
      @@help[:command] = c
    end

    def aliases(*a)
      @@help[:aliases] += a
    end

    def usage(message)
      @@help[:usage] = [message].flatten.compact
    end

    def handle_help
      match_command /(help|\?|how|what|--help|-h)/, method: :help_message
      define_method :help_message do |m|
        m.reply "No help message :(" if @@help[:usage].empty?
        usage = @@help[:usage].map do |line|
          line.gsub('!%', "!#{@@help[:command]}")
        end

        usage[0] = "Usage: #{usage[0]}"
        usage.each {|l| m.reply(l) }
      end
    end

    def match_command(pattern = nil, opts = {})
      pattern = pattern.source if pattern.respond_to? :source
      excl = if @@help[:include_command] then '' else '?:' end
      pat = "(#{excl}#{[@@help[:command], *@@help[:aliases]].map {|c| Regexp.escape(c)}.join('|')})"
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
