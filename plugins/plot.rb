require_relative '../lib/dicere'

class Rogare::Plugins::Plot
  include Cinch::Plugin

  match /(plot|prompt|seed|event)\s*(.*)/
  @@commands = ['plot [optional filter keywords]']

  def execute(m, cat, param)
    param = param.strip
    if param =~ /^(help|\?|how|what|--help|-h)/
      m.reply 'Usage: !' + @@commands.first
      m.reply 'Also see https://cogitare.nz' if rand > 0.9
      return
    end

    if cat =~ /seed/
      param += ' seed'
    elsif cat =~ /event/
      param += ' event'
    elsif cat =~ /prompt/
      param += ' prompt'
    end

    if param.empty?
      return m.reply Dicere.random.to_s
    end

    if param.to_i > 0
      item = Dicere.item(param)
      m.reply item.to_s
      m.reply item.to_href
      return
    end

    items = Dicere.search(param)
    items = [Dicere.random] if items.empty?
    m.reply items.shuffle.first.to_s
  end
end
