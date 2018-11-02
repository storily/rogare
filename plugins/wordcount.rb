class Rogare::Plugins::Wordcount
  include Cinch::Plugin
  extend Rogare::Plugin
  extend Memoist

  command 'wc'
  aliases 'count'
  usage [
    '!%, or: !% nanoname, or: !% nick (to see others\' counts)',
    'To register your nano name against your current nick: !% set nanoname',
    'To set your goal: !% goal <number> (do it after !% set)',
    'To use a goal just for this call: !% @<number> [nick]',
  ]
  handle_help

  @@redis = Rogare.redis(2)

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
    return unless doc.css('error').length == 0

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
    get_counts(m, [m.user.nick], goal: goal)
  end

  def live_counts(m, param = nil)
    if param
      execute(m, param, live: true)
    else
      get_counts(m, [m.user.nick], live: true)
    end
  end

  def all_counts(m)
    names = @@redis.keys('nick:*:nanouser').map do |k|
      @@redis.get(k).downcase
    end.compact.uniq
    return m.reply 'No names set' if names.empty?
    get_counts(m, names)
  end

  def set_username(m, param)
    name = param.strip.split.join("_")
    @@redis.set("nick:#{m.user.nick.downcase}:nanouser", name)
    m.reply "Your username has been set to #{name}."
    own_count(m)
  end

  def set_goal(m, goal)
    user = m.user.nick.downcase
    name = @@redis.get("nick:#{user}:nanouser") || user
    goal.sub! /k$/, '000'
    @@redis.set("nano:#{name}:goal", goal.to_i)
    m.reply "Your goal has been set to #{goal}."
    own_count(m)
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
        names << m.user.nick
      when /^(random|rand|any)$/i
        random_user = true
        names.push(*m.channel.users.keys.shuffle.map {|n| n.nick })
      else
        names << p
      end
    end
    names << m.user.nick if names.empty?
    names.uniq!

    opts[:random] = random_user
    get_counts(m, names, opts)
  end

  def get_counts(m, names, opts = {})
    if opts[:goal]
      opts[:goal].sub! /k$/, '000'
    end

    names.map! do |c|
      @@redis.get("nick:#{c.downcase}:nanouser") || c
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
      day_secs = 60*60*24
      month_secs = day_secs * 30

      nth = (timediff / day_secs).ceil
      goal = (opts[:goal] || @@redis.get("nano:#{name}:goal") || 50_000).to_f
      diff = if opts[:live]
        ((goal / month_secs) * timediff).round
      else
        (goal / 30 * nth).round
      end - count

      "#{Rogare.nixnotif(name.to_s)}: #{count} (#{[
        "#{(100.0 * count / goal).round(1)}%",
        if today then "today: #{today}" end,
        if diff == 0
          "up to date"
        elsif diff > 0
          "#{diff} behind"
        else
          "#{diff.abs} ahead"
        end,
        if goal != 50_000
          if goal < 10_000
            "#{(goal / 1_000).round(1)}k goal"
          else
            "#{(goal / 1_000).round}k goal"
          end
        end
      ].compact.join(', ')})"
    end

    if opts[:random] && counts.compact.length == 0
      m.reply "No users in this channel have novels!"
      return
    end

    m.reply counts.compact.join(', ')
  end
end
