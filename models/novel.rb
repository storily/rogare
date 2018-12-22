# frozen_string_literal: true

class Novel < Sequel::Model
  plugin :timestamps, create: :created, update: :updated, update_on_create: true

  many_to_one :user
  one_to_many :goals
  one_to_many :wordcounts

  def wordcount_at(time)
    wc = wordcounts_dataset
         .where { as_at < time }
         .reverse(:as_at)
         .select(:words)
         .first
    wc ? wc[:words] : 0
  end

  def todaycount
    count = Preparation::Todaycount[id: id]
    (count && count[:words]) || 0
  end

  def wordcount
    wordcount_at Time.now
  end

  def wordcount=(wc)
    add_wordcount Wordcount.new(words: wc)
  end

  def past_goals
    tz = user.tz
    goals_dataset.where do
      # always exclude removed
      (removed =~ nil) & (
        # either it's in the past
        (timezone(tz, now.function) >
          (timezone(tz, finish) + Sequel.lit("interval '1 day'"))) |
        # or it's already got a child
        (Goal.where(parent_id: id).exists)
      )
    end.order_by(:start, :id)
  end

  def current_goals
    tz = user.tz
    goals_dataset
    .exclude { Goal.where(parent_id: id).exists } # exclude when it's got a child
    .where do
      # always exclude removed
      (removed =~ nil) &
        # either it never finishes
        ((finish =~ nil) | (
          # or it's still current
          timezone(tz, now.function) <
          (timezone(tz, finish) + Sequel.lit("interval '1 day'"))
        ))
    end
    .order_by(:start, :id)
  end

  def current_goal(offset = 0)
    current_goals.offset(offset).first
  end
end
