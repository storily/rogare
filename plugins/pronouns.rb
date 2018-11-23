# frozen_string_literal: true

class Rogare::Plugins::Pronouns
  extend Rogare::Plugin

  command 'pronouns'
  aliases 'gender'
  usage '`!%` - You’re a sweetie'
  handle_help

  match_empty :execute
  def execute(m)
    m.reply 'My pronouns are it/they/she, thanks for asking :)'
  end
end
