class Rogare::Plugins::Help
  include Cinch::Plugin
  extend Rogare::Help
  extend Memoist

  command 'help', hidden: true
  aliases 'list'

  match_command /.*/
  match_empty :execute

  def bot_prefix
    (self.class.prefix || Rogare.bot.config.plugins.prefix).to_s
      .gsub(/(^\(|\))$/, '')
      .gsub('?-mix:', '')
      .gsub(/^\^/, '')
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
      [
        coms.shift,
        "(aliases: #{coms.join(', ')})" unless coms.empty?
      ].compact.join ' '
    end.sort
  end

  def execute(m)
    m.reply "Commands: #{readable_commands.join(', ')}."
    m.reply "Also use `!<command> help` to get help for any command."
  end

  memoize :bot_prefix, :command_list, :readable_commands
end
