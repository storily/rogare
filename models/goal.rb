# frozen_string_literal: true

class Goal < Sequel::Model
  plugin :timestamps, create: :created, update: :updated, update_on_create: true

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

  def repeat_if_needed!
    DB.transaction(isolation: :serializable) do
      return if removed
      return unless repeat
      return unless over?

      copy = to_hash.dup
      %i[id created updated].each { |k| copy.delete k }
      copy[:start] = finish.succ
      copy[:finish] += (finish - start).days

      follow = Goal.create(copy)
      self.repeat = false
      save
      follow
    end
  end

  def self.need_repeating
    where { repeat & (removed =~ nil) }.all.select(&:over?)
  end
end
