# frozen_string_literal: true

class Rogare::Commands::Choose
  extend Rogare::Command

  command 'choose'
  usage '`!% <first thing> or <second thing> [or <third thing> and so on]`'
  handle_help

  match_command /(.+)/
  match_empty :help_message

  def execute(m, param)
    xor = /\s+xor\s+/ =~ param

    if !xor && rand < 0.01
      return m.reply [
        'yes', 'both', 'all of the above', 'not super sure, actually', 'Gryffindor!'
      ].sample
    end

    args = param.split(/\s+x?or\s+/i)

    s = Set.new args
    return unless s.length > 1 && (args.length == s.length)

    choice = args.sample
    choice = choice[0..-2] if choice.end_with? '?'

    m.reply choice
  end
end
