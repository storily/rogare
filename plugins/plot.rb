require_relative '../lib/dicere'

class Rogare::Plugins::Plot
  include Cinch::Plugin
  extend Rogare::Plugin

  command 'plot', help_includes_command: true
  aliases 'prompt', 'seed', 'event'
  usage '!% [optional filter keywords]'
  handle_help

  match_command /(.*)/
  match_empty :execute

  def execute(m, cat, param = '')
    param = param.strip

    if cat =~ /seed/i
      param += ' seed'
    elsif cat =~ /event/i
      param += ' event'
    elsif cat =~ /prompt/i
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
