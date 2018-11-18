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
    'To use a goal just for this call: `!% @<number> [nick]`'
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
  match_command /live(?:\s+(.+))?/, method: :live_counts
  match_command /set\s+(.+)/, method: :set_username
  match_command /goal\s+(\d+k?)/, method: :set_goal
  match_command /@(\d+k?)\s+(.+)/, method: :with_goal
  match_command /@(\d+k?)\s*$/, method: :own_count
  match_command /(.+)/
  match_empty :own_count

  def own_count(m, goal = nil)
    goal = nil if goal == ''
    get_counts(m, [m.user.mid], goal: goal)
  end

  def live_counts(m, param = nil)
    if param
      execute(m, param, live: true)
    else
      get_counts(m, [m.user.mid], live: true)
    end
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

  def with_goal(m, goal, param)
    execute(m, param, goal: goal)
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
      if /^<@\d+>$/.match?(name)
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
    counts = names.map do |name|
      break if opts[:random] && random_found

      count = get_count(name)
      next if opts[:random] && count.nil?
      next "#{name}: user does not exist or has no current novel" if count.nil?

      random_found = true

      today = get_today(name)
      timediff = Time.now - Chronic.parse('1st')
      day_secs = 60 * 60 * 24
      month_secs = day_secs * 30

      nth = (timediff / day_secs).ceil
      goal = opts[:goal]
      unless goal
        user = Rogare::Data.users.where(nano_user: name.to_s).first
        goal = Rogare::Data.ensure_novel(user[:discord_id])[:goal] if user
      end
      goal = 50_000 if goal.nil? || goal == 0.0
      goal = goal.to_f

      goal_today = if opts[:live]
                     ((goal / month_secs) * timediff).round
                   else
                     (goal / 30 * nth).round
                   end

      diff = goal_today - count

      data = {
        name: name.to_s,
        count: count,
        percent: (100.0 * count / goal).round(1),
        today: today,
        diff: diff,
        goal: goal
      }

      if opts[:return]
        data
      else
        format data
      end
    end.compact

    return counts if opts[:return]

    if opts[:random] && counts.empty?
      m.reply 'No users in this channel have novels!'
      return
    end

    m.reply counts.join(', ')
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
      if data[:live].nil?
        nil
      elsif data[:live].zero?
        'up to live'
      elsif data[:live].positive?
        "#{data[:live]} behind live"
      else
        "#{data[:live].abs} ahead live"
      end,
      if data[:goal] != 50_000
        if data[:goal] < 10_000
          "#{(data[:goal] / 1_000).round(1)}k goal"
        else
          "#{(data[:goal] / 1_000).round}k goal"
        end
      end
    ].compact.join(', ')})"
  end
end
