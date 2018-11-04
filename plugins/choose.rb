# frozen_string_literal: true

class Rogare::Plugins::Choose
  extend Rogare::Plugin

  command 'choose'
  usage '!% <first thing> or <second thing> [or <third thing> and so on]'
  handle_help

  match_command /(.+)/
  match_empty :help_message

  def execute(m, param)
    args = param.split.map { |x| x.casecmp('or').zero? ? x.downcase : x }.join(' ').split(' or ')

    s = Set.new args
    if s.length > 1 && (args.length == s.length)
      choice = args.sample
      choice = choice[0..-2] if choice.end_with? '?'

      m.reply choice
      return
    end
  end
end
