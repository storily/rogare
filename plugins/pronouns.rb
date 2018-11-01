class Rogare::Plugins::Pronouns
  include Cinch::Plugin
  extend Rogare::Plugin

  command 'pronouns', hidden: true
  usage '!% - You\'re a sweetie'
  handle_help

  match_empty :execute
  def execute(m)
    m.reply "My pronouns are it/they/she, thanks for asking :)"
  end
end
