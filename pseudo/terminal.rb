# frozen_string_literal: true

class Pseudo::Terminal
  def initialize
    Pseudo.bot.hook(:status) { |status| reline(status: status) }
    Pseudo.bot.hook(:game) { |game| reline(game: game) }

    @indic = {}
    @prompt = TTY::Prompt.new(interrupt: :signal)
  end

  def reline(updates = {})
    prefix = {
      game: 'Playing: '
    }

    updates.each { |key, val| @indic[key] = val }
    indics = @indic.to_a.map { |key, val| "[#{prefix[key]}#{val}]" if val }.compact.join ' '

    @prompt.ask "#{indics} >"
  end

  def player!
    Pseudo.bot.send_ready
    reline
  end
end
