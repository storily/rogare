class Rogare::Plugins::Help
  include Cinch::Plugin
  extend Memoist

  match /(help|list)/
  @@commands = ['help']

  def bot_prefix
    prefix = (self.class.prefix || Rogare.bot.config.plugins.prefix).to_s
    prefix = prefix[1..-2] if (prefix.index("(") == 0) && (prefix.index(")") == prefix.length - 1)
    prefix.gsub! "?-mix:", ""
    prefix = prefix[1..-1] if prefix[0] == "^"

    prefix
  end

  def command_list
    commands = []

    Rogare.bot.plugins.each do |plugin|
      plugin.handlers.each do |handler|
        next if self.class.matchers.map{|p| p.pattern == handler.pattern.pattern}.any?

        pattern = handler.pattern.pattern.to_s[1..-2]
        pattern.gsub! "?-mix:", ""
        pattern.gsub! "(.*)", ""
        pattern = pattern[1..-2] if (pattern.index("(") == 0) && (pattern.index(")") == pattern.length - 1)

        commands.push pattern.split("|")
      end
    end

    commands
  end

  def readable_commands
    command_list.map do |commandlist|
      prefixed = commandlist.map do |command|
        "#{bot_prefix}#{command}"
      end

      out = prefixed[0]
      out = "#{out} (aliases: #{prefixed[1..-1].join(', ')})" if prefixed.length > 1
      out
    end
  end

  def execute(m)
    m.reply "Commands: #{readable_commands.join(', ')}"
    m.reply 'Also see https://cogitare.nz for prompts' if rand > 0.95
  end

  memoize :bot_prefix, :command_list, :readable_commands
end
