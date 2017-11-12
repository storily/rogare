class Rogare::Plugins::Pick
  include Cinch::Plugin
  extend Rogare::Help

  command 'pick'
  usage '!% <start> <end> - Picks a number between start and end'
  handle_help

  match_command /(\d+)\s+(\d+)/
  match_empty :help_message

  def execute(m, n1, n2)
    n1 = n1.strip.to_i
    n2 = n2.strip.to_i

    m.reply (n1..n2).to_a.sample
  end
end
