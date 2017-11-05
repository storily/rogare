require 'set'

class Rogare::Plugins::Say
  include Cinch::Plugin
  extend Rogare::Help

  command 'say'
  usage '!% <channel> <message>'
  handle_help

  match_command /(#+\w+)\s+(.*)/
  match_empty :help_message

  def execute(m, chan, message)
    channel = Rogare.bot.channel_list.find(chan.downcase.strip)

    if channel.nil?
      m.reply "No such channel"
    else
      channel.send message
    end
  end
end
