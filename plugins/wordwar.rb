class Rogare::Plugins::Wordwar
  include Cinch::Plugin

  match /(wordwar|war|ww)(.*)/
  @@usage = [
    'Use: !wordwar in [time before it starts (in minutes)] for [duration]',
    'Or:  !wordwar at [wall time e.g. 12:35 (NZ)] for [duration]',
    'Or even (defaulting to a 20 minute run): !wordwar at/in [time]',
    'And then everyone should: !wordwar join [username / wordwar ID]',
  ]

  def execute(m, _, param)
    param = param.strip
    if param =~ /^(help|\?|how|what|--help|-h)/
      @@usage.each {|l| m.reply l }
      return
    end

    m.reply 'Not implemented'
  end
end
