# frozen_string_literal: true

module Rogare::Data
  class << self
    def wars
      DB[:wars]
    end

    def warmembers
      DB[:users_wars]
    end

    def pga(*things)
      Sequel.pg_array(things)
    end

    def first_of(month, tz)
      tz_string = tz.current_period.offset.abbreviation
      DateTime.parse("#{Time.new.year}-#{month}-01 00:00:00 #{tz_string}").to_time
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
