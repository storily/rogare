require 'graphql/client'
require 'graphql/client/http'

class Rogare::Plugins::Plot
  include Cinch::Plugin
  extend Memoist

  match /(plot|prompt)(.*)/
  @@commands = ['plot (or !prompt) [optional keywords to filter plots/prompts]']

  def execute(m, _, param)
    param = param.strip
    if param =~ /^(help|\?|how|what|--help|-h)/
      m.reply 'Usage: !' + @@commands.first
      m.reply 'Also see https://cogitare.nz' if rand > 0.9
      return
    end

    m.reply 'Not implemented'
  end
end
