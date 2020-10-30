# frozen_string_literal: true

class Rogare::Commands::Help
  extend Rogare::Command
  extend Memoist

  command 'help', hidden: true
  aliases 'list'

  match_command /.*/
  match_empty :execute

  def bot_prefix
    Rogare
      .prefix
      .to_s
      .gsub(/(
          ^\(
        | \)$
        | \^
        | \?-mix:
      )/x, '')
  end

  def command_list
    Rogare::Commands.constants.map do |cmd|
      command = Rogare::Commands.const_get cmd
      one = Rogare::Command.allmine[command.inspect.to_sym]
      next if one.nil?
      next if one[:hidden]

      [one[:command], one[:aliases]].flatten
    end.compact
  end

  def readable_commands
    command_list.map do |coms|
      coms.map! { |c| "`#{bot_prefix}#{c}`" }
      [
        coms.shift,
        ("(aliases: #{coms.join(', ')})" unless coms.empty?)
      ].compact.join ' '
    end.sort
  end

  def execute(m)
    m.reply "Legacy:\n#{readable_commands.join("\n")}."
  end

  memoize :bot_prefix, :command_list, :readable_commands
end
