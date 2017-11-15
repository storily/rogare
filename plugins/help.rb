class Rogare::Plugins::Help
  include Cinch::Plugin
  extend Rogare::Help
  extend Memoist

  command 'help', hidden: true
  aliases 'list'

  match_command /(.*)/
  match_empty :execute

  def bot_prefix
    prefix = (self.class.prefix || Rogare.bot.config.plugins.prefix).to_s
    prefix = prefix[1..-2] if (prefix.index("(") == 0) && (prefix.index(")") == prefix.length - 1)
    prefix.gsub! "?-mix:", ""
    prefix = prefix[1..-1] if prefix[0] == "^"

    prefix
  end

  def command_list
    Rogare::Plugins.to_a.map do |plugin|
      help = Rogare::Help.helps[plugin.inspect.to_sym]
      next if help.nil?
      next if help[:hidden]
      [help[:command], help[:aliases]].flatten
    end.compact
  end

  def readable_commands
    command_list.map do |coms|
      coms.map! {|c| "#{bot_prefix}#{c}" }
      out = "#{coms.shift}"
      out += " (aliases: #{coms.join(', ')})" unless coms.empty?
      out
    end.sort
  end

  def execute(m)
    m.reply "Commands: #{readable_commands.join(', ')}"
  end

  memoize :bot_prefix, :command_list, :readable_commands
end
