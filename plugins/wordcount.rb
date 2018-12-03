# frozen_string_literal: true

class Rogare::Plugins::Wordcount
  extend Rogare::Plugin
  extend Memoist

  command 'wc'
  aliases 'count'
  usage [
    '`!%`, or: `!% <nanoname>`, or: `!% <@nick>` (to see others’ counts)',
    'To register your nano name against your current nick: `!% set <nanoname>`',
    'To set your goal: `!% goal <number>` (do it after `!% set`)',
    'To use a goal just for this call: `!% @<number> [nick]`',
    'To set your timezone: `!% tz <e.g. Pacific/Auckland>`'
  ]
  handle_help

  def get_today(name)
    res = Typhoeus.get "https://nanowrimo.org/participants/#{name}/stats"
    return unless res.code == 200

    doc = Nokogiri::HTML res.body
    doc.at_css('#novel_stats .stat:nth-child(2) .value').content.gsub(/[,\s]/, '').to_i
  end

  def get_count(name)
    res = Typhoeus.get "https://nanowrimo.org/wordcount_api/wc/#{name}"
    return unless res.code == 200

    doc = Nokogiri::XML(res.body)
    return unless doc.css('error').empty?

    doc.at_css('user_wordcount').content.to_i
  end

  match_command /all\s*/, method: :all_counts
  match_command /tz\s+(.+)/, method: :set_timezone
  match_command /set\s+(.+)/, method: :set_username
  match_command /goal\s+(\d+k?)/, method: :set_goal
  match_command /(.+)/
  match_empty :own_count

  def live_count_no_more(m)
    m.reply 'Included in the normal commands now'
  end

  def own_count(m)
    get_counts(m, [m.user.mid])
  end

  def all_counts(m)
    names = Rogare::Data.all_nano_users
    return m.reply 'No names set' if names.empty?

    get_counts(m, names)
  end

  def set_username(m, param)
    name = param.strip.split.join('-')

    Rogare::Data.set_nano_user(m.user, name)
    m.reply "Your username has been set to #{name}."
    own_count(m)
  end

  def set_goal(m, goal)
    goal.sub! /k$/, '000'

    novel = Rogare::Data.current_novels(Rogare::Data.user_from_discord(m.user)).first
    Rogare::Data.novels.where(id: novel[:id]).update(goal: goal.to_i)

    m.reply "Your goal has been set to #{goal}."
    own_count(m, goal.to_i)
  end

  def set_timezone(m, tz)
    tz.strip!

    begin
      TZInfo::Timezone.get(tz)
    rescue StandardError => e
      logs "Invalid timezone: #{e}"
      return m.reply 'That’s not a valid timezone.'
    end

    user = m.user.to_db
    Rogare::Data.users.where(id: user[:id]).update(tz: tz)
    m.reply "Your timezone has been set to #{tz}."
  end

  def execute(m, param = '', opts = {})
    names = []
    random_user = false

    param.strip.split.each do |p|
      p = p.downcase.to_sym
      case p
      when /^(me|self|myself|i)$/i
        names << m.user.mid
      when /^(random|rand|any)$/i
        random_user = true
        names.push(*m.channel.users.shuffle.map(&:mid))
      else
        names << p
      end
    end
    names << m.user.mid if names.empty?
    names.uniq!

    opts[:random] = random_user
    get_counts(m, names, opts)
  end

  def get_counts(m, names, opts = {})
    opts[:goal]&.sub! /k$/, '000'

    names.map! do |name|
      # Exact match from @mention / mid
      if /^<@!?\d+>$/.match?(name)
        du = Rogare.from_discord_mid(name)
        next Rogare::Data.get_nano_user(du.inner) if du
      end

      # Case-insensitive match from nick
      from_nick = Rogare::Data.users.where { nick =~ /^#{name}$/i }.first
      next from_nick[:nano_user] if from_nick && from_nick[:nano_user]

      # Otherwise just assume nano name == given name
      name
    end

    # `random_found` exists so that we don't check every single user in the
    # channel for a valid NaNoWriMo wordcount before choosing a random one
    # to display, instead we only request word counts up until the first one
    # that has a valid count.
    random_found = false
    counts = names.compact.map do |name|
      break if opts[:random] && random_found

      user = Rogare::Data.users.where(nano_user: name.to_s).first
      tz = TZInfo::Timezone.get(user[:tz] || Rogare.tz)
      now = tz.local_to_utc(tz.now)
      timediff = now - Rogare::Data.first_of(now.month, tz)

      if user
        novel = Rogare::Data.ensure_novel(user[:discord_id])
        unless novel
          m.reply "#{name} has no current novel"
          next
        end
      end

      day_secs = 60 * 60 * 24
      month_days = Date.new(now.year, now.month, -1).day
      month_secs = day_secs * month_days

      nth = (timediff / day_secs).ceil
      goal = opts[:goal]
      goal = nil if opts[:goal].to_i.zero?
      goal = novel[:goal] if user && !goal
      goal = 50_000 if goal.nil? || goal == 0.0
      goal = goal.to_f

      goal_live = ((goal / month_secs) * timediff).round
      goal_today = (goal / 30 * nth).round

      if user[:id] == 10 # tamgar sets their count in their nick
        count = user[:nick].split(/[\[\]]/).last.to_i
      else
        count = get_count(name)
        next if opts[:random] && count.nil?
        next { name: name, count: nil } if count.nil?
      end

      random_found = true

      diff_live = goal_live - count
      diff_today = goal_today - count

      {
        name: name.to_s,
        count: count,
        percent: (100.0 * count / goal).round(1),
        today: get_today(name),
        diff: diff_today,
        live: diff_live,
        goal: goal
      }
    end

    return counts if opts[:return]

    if opts[:random] && counts.empty?
      m.reply 'No users in this channel have novels!'
      return
    end

    if counts.count == 1
      present_one m, counts.first
    else
      m.reply counts.map { |c| format c }.join(', ')
    end
  end

  def format(data)
    "#{Rogare.nixnotif(data[:name])}: #{data[:count]} (#{[
      "#{data[:percent]}%",
      ("today: #{data[:today]}" if data[:today]),
      if data[:diff].zero?
        'up to date'
      elsif data[:diff].positive?
        "#{data[:diff]} behind"
      else
        "#{data[:diff].abs} ahead"
      end,
      if data[:live].zero?
        'up to live'
      elsif data[:live].positive?
        "#{data[:live]} behind live"
      else
        "#{data[:live].abs} ahead live"
      end,
      (Rogare::Data.goal_format data[:goal] if data[:goal] != 50_000)
    ].compact.join(', ')})"
  end

  def present_one(m, data)
    logs data.inspect

    return m.reply "#{data[:name]}: user does not exist or has no current novel" if data[:count].nil?

    if data[:count] > 100_000 && rand > 0.5
      m.reply "Content Warning: #{%w[Astonishing Wondrous Beffudling Shocking Monstrous].sample} Wordcount"
      sleep 1
    end

    m.reply format data
  end
end
