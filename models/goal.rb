# frozen_string_literal: true

class Goal < Sequel::Model
  many_to_one :novel

  def format_words
    if words < 1_000
      "#{words} words goal"
    elsif words < 10_000
      "#{(words / 1_000.0).round(1)}k goal"
    else
      "#{(words / 1_000.0).round}k goal"
    end
  end
end
