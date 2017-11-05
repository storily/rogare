class Rogare::Plugins::Choose
  include Cinch::Plugin
  extend Rogare::Help

  command 'choose'
  aliases 'pick'
  usage '!% <first thing> or <second thing> [or <third thing> and so on]'
  handle_help

  match_command /(.+)/
  match_empty :help_message

  def execute(m, param)
    args = param.split.map{|x| x.downcase == 'or' ? x.downcase : x}.join(' ').split(' or ')

    s = Set.new args
    if s.length > 1 && (args.length == s.length)
      choice = args.sample
      if choice.end_with? '?'
        choice = choice[0..-2]
      end

      m.reply choice
      return
    end
  end
end
