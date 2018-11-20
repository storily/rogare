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

    def first_of(month)
      # Assume +1300. In November it will be right, otherwise it will be off but
      # in the right "direction" i.e. there won't be surprised 'but it IS month'
      DateTime.parse("#{Time.new.year}-#{month}-01 00:00:00 +1300").to_time
    end

    def ensure_novel(did)
      user = users.where(discord_id: did).first
      latest_novel = current_novels(user).first

      this_is_november = first_of(11) <= Time.new && Time.new < first_of(12)
      # We only assume and create a novel when it's november. If it's camp time,
      # we don't, and you'll have to tell us to make a new one if you want.

      if this_is_november
        if latest_novel.nil? || latest_novel[:started] < first_of(11)
          # This is nano, start a new novel!
          id = novels.insert(
            user_id: user[:id],
            started: first_of(11),
            type: 'nano'
          )

          return novels.where(id: id).first
        end
      elsif latest_novel.nil?
        # No unfinished novels, start one now
        id = novels.insert(user_id: user[:id])
        return novels.where(id: id).first
      end

      latest_novel
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

    def current_wars
      wars.select(Sequel[:wars]['*']).join(:users, id: :creator).where do
        (ended =~ false) & (cancelled =~ nil) &
          (start + concat(seconds, ' secs').cast(:interval) > now.function)
      end.order_by(Sequel[:wars][:created])
    end

    def war_members(id)
      users.join(:users_wars, user_id: :id).join(:wars, id: :war_id).where do
        (Sequel[:users_wars][:war_id] =~ id) &
          (Sequel[:wars][:creator] !~ Sequel[:users][:id])
      end.select(Sequel[:users]['*'], Sequel.function(
        :concat,
        '<@',
        Sequel[:users][:discord_id],
        '>'
      ).as(:mid))
    end

    def current_war(id)
      current_wars.where(Sequel[:wars][:id] => id)
    end

    def war_exists?(id)
      current_war(id).count.positive?
    end

    memoize :all_kinds
  end
end
