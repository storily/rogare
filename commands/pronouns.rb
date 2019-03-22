# frozen_string_literal: true

class Rogare::Commands::Pronouns
  extend Rogare::Command

  command 'pronouns'
  aliases 'gender'
  usage '`!%` - You’re a sweetie'
  handle_help

  match_empty :execute
  def execute(m)
    m.reply 'My pronouns are she/her it/its, thanks for asking :)'
  end
end
