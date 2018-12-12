# frozen_string_literal: true

module Rogare::Data
  class << self
    extend Memoist

    def users
      Rogare.sql[:users]
    end

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

    def user_from_discord(discu)
      users.where(discord_id: discu.id).first
    end

    # returns date user was last previously seen
    def user_seen(discu)
      nick = discu.nick || discu.username
      discordian = user_from_discord(discu)

      return new_user(discu)[:last_seen] unless discordian
      return discordian[:last_seen] unless Time.now - discordian[:last_seen] > 60 || discordian[:nick] != nick

      users.where(id: discordian[:id]).update(
        last_seen: Sequel.function(:now),
        nick: nick
      )

      Time.now
    end

    def new_user(discu, extra = {})
      defaults = {
        discord_id: discu.id,
        nick: discu.nick || discu.username,
        first_seen: Sequel.function(:now),
        last_seen: Sequel.function(:now)
      }

      id = users.insert(defaults.merge(extra))
      users.where(id: id).first
    end

    def get_nano_user(discu)
      user = user_from_discord discu
      (user && user[:nano_user]) || discu.nick || discu.username
    end

    def set_nano_user(discu, name)
      user = user_from_discord(discu)
      if user
        users.where(id: user[:id]).update(nano_user: name)
      else
        new_user(discu, nano_user: name)
      end
    end

    def all_nano_users
      users
        .distinct
        .select(:nano_user)
        .where { nano_user !~ nil }
        .map { |u| u[:nano_user] }
    end

    def current_novels(user)
      novels
        .where do
          (user_id =~ user[:id]) &
            (started <= Sequel.function(:now)) &
            (finished =~ false)
        end
        .reverse(:started)
    end

    def first_of(month, tz)
      tz_string = tz.current_period.offset.abbreviation
      DateTime.parse("#{Time.new.year}-#{month}-01 00:00:00 #{tz_string}").to_time
    end

    def ensure_novel(did)
      user = users.where(discord_id: did).first
      latest_novel = current_novels(user).first
      tz = TZInfo::Timezone.get(user[:tz] || Rogare.tz)

      this_is_november = first_of(11, tz) <= Time.new && Time.new < first_of(12, tz)
      # We only assume and create a novel when it's november. If it's camp time,
      # we don't, and you'll have to tell us to make a new one if you want.

      if this_is_november
        appropriate_start = first_of(11, tz) - 2.weeks
        if latest_novel.nil? || latest_novel[:started] < appropriate_start
          # This is nano, start a new novel!
          id = novels.insert(
            user_id: user[:id],
            started: first_of(11, tz),
            type: 'nano'
          )

          goals.insert(
            novel_id: id,
            words: 50_000,
            start: first_of(11, tz),
            finish: first_of(12, tz)
          )

          return novels.where(id: id).first
        end
      end

      latest_novel
    end

    def load_novel(user, id)
      if id.nil? || id.empty?
        Rogare::Data.current_novels(user).first
      else
        Rogare::Data.novels.where(user_id: user[:id], id: id.to_i).first
      end
    end

    def novel_wordcount(id)
      wc = wordcounts.where(novel_id: id).reverse(:as_at).select(:words).first
      wc ? wc[:words] : 0
    end

    def novel_todaycount_stmt
      novel_tz = Rogare.sql[:novel_tz].select(:tz).limit(1)
      novel_tz_cte = users
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
      wordcounts.insert(novel_id: id, words: wc)
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
      q = users
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
