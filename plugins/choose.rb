# frozen_string_literal: true

class Rogare::Plugins::Choose
  extend Rogare::Plugin

  command 'choose'
  usage '!% <first thing> or <second thing> [or <third thing> and so on]'
  handle_help

  match_command /(.+)/
  match_empty :help_message

  def execute(m, param)
    if rand < 0.01
      return m.reply [
        'yes', 'both', 'all of the above', 'not super sure, actually', 'Gryffindor!',
        'I’m sorry, the die I threw flew off the table, ask me again once I’ve retrieved it.'
      ].sample
    end

    args = param.split.map { |x| x.casecmp('or').zero? ? x.downcase : x }.join(' ').split(' or ')

    s = Set.new args
    return unless s.length > 1 && (args.length == s.length)

    choice = args.sample
    choice = choice[0..-2] if choice.end_with? '?'

    m.reply choice
  end
end
