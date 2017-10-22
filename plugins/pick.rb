class Rogare::Plugins::Pick
  include Cinch::Plugin

  match /(pick|choose)(.*)/
  @@commands = ['pick']

  def execute(m, _, param)
    param = param.strip
    if param =~ /^(help|\?|how|what|--help|-h)/
      m.reply 'Usage: !' + @@commands.first
      return
    end

    m.reply 'Not implemented'
  end
end
