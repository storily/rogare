# frozen_string_literal: true

module Rogare::Data
  class << self
    def novels
      DB[:novels]
    end

    def wars
      DB[:wars]
    end

    def warmembers
      DB[:users_wars]
    end

    def wordcounts
      DB[:wordcounts]
    end

    def goals
      DB[:goals]
    end

    def pga(*things)
      Sequel.pg_array(things)
    end

    def kinds(*knds)
      Name.to_kinds(knds)
    end

    def current_novels(user)
      user.current_novels
    end

    def first_of(month, tz)
      tz_string = tz.current_period.offset.abbreviation
      DateTime.parse("#{Time.new.year}-#{month}-01 00:00:00 #{tz_string}").to_time
    end

    def load_novel(user, id)
      user.load_novel id
    end

    def novel_wordcount_at(id, time)
      Novel[id].wordcount_at(time)
    end

    def novel_wordcount(id)
      novel_wordcount_at(id, Time.now)
    end

    def novel_todaycount(id)
      Novel[id].todaycount
    end

    def set_novel_wordcount(id, wc)
      Novel[id].wordcount = wc
    end

    def existing_wars
      wars.select_all(:wars)
          .select_append(Sequel[:users][:nick].as(:creator_nick))
          .join(:users, id: :creator)
          .where { (ended =~ false) & (cancelled =~ nil) }
          .order_by(Sequel[:wars][:created])
    end

    def current_wars
      existing_wars.where do
        (start + concat(seconds, ' secs').cast(:interval) > now.function)
      end
    end

    def war_members(id, include_creator = false)
      q = User
          .select_all(:users).select_append(Sequel.function(
            :concat,
            '<@',
            Sequel[:users][:discord_id],
            '>'
          ).as(:mid))
          .join(:users_wars, user_id: :id)
          .join(:wars, id: :war_id)
          .where(Sequel[:users_wars][:war_id] => id)

      q = q.exclude(Sequel[:wars][:creator] => Sequel[:users][:id]) unless include_creator
      q
    end

    def current_war(id)
      current_wars.where(Sequel[:wars][:id] => id)
    end

    def war_exists?(id)
      current_war(id).count.positive?
    end

    def goal_format(goal)
      if goal < 1_000
        "#{goal} words goal"
      elsif goal < 10_000
        "#{(goal / 1_000.0).round(1)}k goal"
      else
        "#{(goal / 1_000.0).round}k goal"
      end
    end

    def goal_parser
      GoalTermsParser.new
    end

    def current_goals(novel)
      goals.where do
        (novel_id =~ novel[:id]) &
          (removed =~ nil) &
          ((finish > now.function) | (finish =~ nil))
      end.order_by(:start, :id)
    end

    def current_goal(novel, offset = 0)
      current_goals(novel).offset(offset).first
    end

    def encode_entities(raws)
      raws.gsub(/(_|\*|\`)/, '\\1')
          .gsub('~~', '\~\~')
          .gsub(/\s+/, ' ')
    end

    def datef(date)
      date.strftime('%-d %b %Y')
    end
  end
end
