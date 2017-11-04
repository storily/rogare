require 'set'

class Rogare::Plugins::Choose
  include Cinch::Plugin

  match /choose\s*(.*)/i
  @@commands = ['choose <first thing> or <second thing> [or <third thing> and so on]']

  def execute(m, param)
    args = param.split.map{|x| x.downcase == 'or' ? x.downcase : x}.join(' ').split(' or ')

    if args.length == 1 && args.first =~ /^(help|\?|how|what|--help|-h)/i
      m.reply 'Usage: !' + @@commands.first
      return
    end

    s = args.to_set
    if s.length > 1 && (args.length == s.length)
      choice = args.sample
      if choice.end_with? '?'
        choice = choice[0..-2]
      end

      m.reply choice
      return
    end

    m.reply 'Usage: !' + @@commands.first
  end
end
