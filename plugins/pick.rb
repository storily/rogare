class Rogare::Plugins::Pick
  extend Rogare::Plugin

  command 'pick'
  usage '!% <start> <end> - Picks a number/letter between start and end'
  handle_help

  match_command /(\d+|[a-z])\s+(\d+|[a-z])/
  match_empty :help_message

  def execute(m, n1, n2)
    n1, n2 = [n1, n2].map{|c| c.strip.upcase}.sort
    m.reply (n1..n2).to_a.sample
  end
end
