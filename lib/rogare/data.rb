# frozen_string_literal: true

module Rogare::Data
  class << self
    extend Memoist

    def novels
      Rogare.sql[:novels]
    end

    def names
      Rogare.sql[:names_scored]
    end

    def wars
      Rogare.sql[:wars]
    end

    def warmembers
      Rogare.sql[:users_wars]
    end

    def wordcounts
      Rogare.sql[:wordcounts]
    end

    def goals
      Rogare.sql[:goals]
    end

    def pga(*things)
      Sequel.pg_array(things)
    end

    def kinds(*knds)
      Sequel[pga(*knds)].cast(:'name_kind[]')
    end

    def enum_values(type)
      Rogare.sql.select do
        unnest.function(
          enum_range.function(Sequel[nil].cast(type))
        ).cast(:text).as(:value)
      end
    end

    def all_kinds
      Rogare.sql[:enum]
            .with(:enum, enum_values(:name_kind))
            .where do
              (Sequel.function(:left, value, 1) !~ '-') &
                (value !~ %w[first last])
            end
            .select_map(:value)
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

    def novel_todaycount_stmt
      novel_tz = Rogare.sql[:novel_tz].select(:tz).limit(1)
      novel_tz_cte = User
                     .join(:novels, user_id: :id)
                     .where(Sequel[:novels][:id] => :$id)
                     .select(Sequel[:tz].cast(:text))

      today = Rogare.sql[:today].select(:today).limit(1)
      today_cte = Rogare.sql[:novel_tz].select do
        date_trunc('day', timezone(:tz, now.function)).as(:today)
      end

      before = Rogare.sql[:before_today].select(:words).limit(1)
      before_today_cte = wordcounts
                         .where { (novel_id =~ :$id) & (timezone(novel_tz, as_at) < today) }
                         .reverse(:as_at)
                         .select(:words)
                         .limit(1)

      during_today_cte = wordcounts
                         .where { (novel_id =~ :$id) & (timezone(novel_tz, as_at) >= today) }
                         .reverse(:as_at)
                         .select(:words)
                         .limit(1)

      Rogare.sql[:during_today]
            .with(:novel_tz, novel_tz_cte)
            .with(:today, today_cte)
            .with(:before_today, before_today_cte)
            .with(:during_today, during_today_cte)
            .select { (words - before).as(:words) }
            .prepare(:first, :novel_todaycount)
    end

    def novel_todaycount(id)
      count = novel_todaycount_stmt.call(id: id)
      (count && count[:words]) || 0
    end

    def set_novel_wordcount(id, wc)
      Novel[id].wordcount = wc
    end

    def name_query(args)
      last = args[:kinds].include? 'last'
      args[:kinds] -= %w[last male female enby] if last

      query = names.select(:name).order { random.function }.where(surname: last).limit(args[:n])
      query = query.where { score >= args[:freq][0] } if args[:freq][0]
      query = query.where { score <= args[:freq][1] } if args[:freq][1]

      unless args[:kinds].empty?
        castkinds = kinds(*args[:kinds].uniq)
        query = query.where(Sequel[:kinds].pg_array.contains(castkinds))
      end

      # TODO: use args[:also] to do further filtering with fallback to non-also if there's too few results

      query
    end

    def name_search(args)
      name_query(args).all.map { |name| ucname name[:name] }
    end

    def ucname(name)
      name.split(/(?<![[:alnum:]])/).map do |part|
        (part[0..-2].capitalize + part[-1])
          .gsub(/^(Ma?c|V[ao]n)(\w+)/) { |_s| "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}" }
          .gsub(/^O([bcdfghklmnrst]\w+)/) { |_s| "O’#{Regexp.last_match(1).capitalize}" }
          .gsub(/^O’Mac(\w+)/) { |_s| "O’Mac#{Regexp.last_match(1).capitalize}" }
      end.join
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

    def name_stats
      queries = Rogare::Data.all_kinds.map do |kind|
        Rogare::Data.names.where(
          Sequel.pg_array(:kinds).contains(Rogare::Data.kinds(kind))
        ).select { count('*') }.as(kind)
      end

      queries << Rogare::Data.names.select { count('*') }.as(:total)
      queries << Rogare::Data.names.where(surname: false).select { count('*') }.as(:firsts)
      queries << Rogare::Data.names.where(surname: true).select { count('*') }.as(:lasts)

      stats = Rogare.sql.select { queries }.first
      total = stats.delete :total
      firsts = stats.delete :firsts
      lasts = stats.delete :lasts

      {
        total: total,
        firsts: firsts,
        lasts: lasts,
        kinds: stats
      }
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

    def goal_parser_impl
      require './lib/goalterms/classes'

      if ENV['RACK_ENV'] == 'production'
        require './lib/goalterms/grammar.rb'
      else
        Treetop.load 'lib/goalterms/grammar.treetop'
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

    memoize :all_kinds, :goal_parser_impl, :novel_todaycount_stmt
  end
end
