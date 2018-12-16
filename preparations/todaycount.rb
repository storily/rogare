# frozen_string_literal: true

class Preparation::Todaycount
  def self.prepare
    novel_tz = DB[:novel_tz].select(:tz).limit(1)
    novel_tz_cte = User
                   .join(:novels, user_id: :id)
                   .where(Sequel[:novels][:id] => :$id)
                   .select(Sequel[:tz].cast(:text))

    today = DB[:today].select(:today).limit(1)
    today_cte = DB[:novel_tz].select do
      date_trunc('day', timezone(:tz, now.function)).as(:today)
    end

    before = DB[:before_today].select(:words).limit(1)
    before_today_cte = DB[:wordcounts]
                       .where { (novel_id =~ :$id) & (timezone(novel_tz, as_at) < today) }
                       .reverse(:as_at)
                       .select(:words)
                       .limit(1)

    during_today_cte = DB[:wordcounts]
                       .where { (novel_id =~ :$id) & (timezone(novel_tz, as_at) >= today) }
                       .reverse(:as_at)
                       .select(:words)
                       .limit(1)

    DB[:during_today]
      .with(:novel_tz, novel_tz_cte)
      .with(:today, today_cte)
      .with(:before_today, before_today_cte)
      .with(:during_today, during_today_cte)
      .select { (words - before).as(:words) }
      .prepare(:first, :novel_todaycount)
  end

  def self.init
    call(id: 1)
  end
end
