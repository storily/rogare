# frozen_string_literal: true

require_relative '../lib/dicere'

class Rogare::Commands::Plot
  extend Rogare::Command

  command 'plot', help_includes_command: true
  aliases 'prompt', 'seed', 'event'
  usage '`!% [optional filter keywords]`'
  handle_help

  match_command /(.*)/
  match_empty :execute

  def execute(m, cat, param = '')
    param = param.strip

    if /seed/i.match?(cat)
      param += ' seed'
    elsif /event/i.match?(cat)
      param += ' event'
    elsif /prompt/i.match?(cat)
      param += ' prompt'
    end

    return m.reply Dicere.random.to_s if param.empty?

    if param.to_i.positive?
      item = Dicere.item(param)
      m.reply item.to_s
      m.reply item.to_href
      return
    end

    items = Dicere.search(param)
    items = [Dicere.random] if items.empty?
    m.reply items.sample.to_s
  end
end
