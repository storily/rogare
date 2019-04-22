# frozen_string_literal: true

class Rogare::Commands::Suggest
  extend Rogare::Command

  command 'suggest'
  usage '`!% <something>` (one suggestion per line)'
  handle_help

  match_command /.+/
  match_empty :help_message

  def execute(m, param)
    param.strip.lines.each do |text|
      text.strip!
      next if text.empty?

      Suggestion.create(text: text, user_id: m.user.id)
    end

    m.reply 'Thanks!'
  end
end
