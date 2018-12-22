# frozen_string_literal: true

class Goal < Sequel::Model
  many_to_one :novel

  def tz_start
    novel.user.date_in_tz(start)
  end

  def tz_finish
    return unless finish
    novel.user.date_in_tz(finish).end_of_day
  end

  def over?
    return unless tz_finish
    Time.now >= tz_finish
  end

  def wordcount
    novel.wordcount_at(tz_finish || Time.now) - novel.wordcount_at(tz_start)
  end

  def done?
    wordcount >= words
  end

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
