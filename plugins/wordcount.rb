class Rogare::Plugins::Nano
  include Cinch::Plugin
  extend Rogare::Help
  extend Memoist

  command 'count'
  aliases 'wc'
  usage [
    '!% nick [nick...], or: !% nanoname',
    'To register your nano name against your current nick: !% set nanoname',
    'To set your goal: !% goal <number> (do it after !% set)',
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
  match_command /set\s+(.+)/, method: :set_username
  match_command /goal\s+(\d+)/, method: :set_goal
  match_command /(.+)/
  match_empty :own_count

  def own_count(m)
    get_counts(m, [m.user.nick])
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
    @@redis.set("nano:#{name}:goal", goal.to_i)
    m.reply "Your goal has been set to #{goal}."
    own_count(m)
  end

  def execute(m, param = '')
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

    get_counts(m, names, random_user)
  end

  def get_counts(m, names, random = false)
    names.map! do |c|
      @@redis.get("nick:#{c.downcase}:nanouser") || c
    end

    # `random_found` exists so that we don't check every single user in the
    # channel for a valid NaNoWriMo wordcount before choosing a random one
    # to display, instead we only request word counts up until the first one
    # that has a valid count.
    random_found = false
    counts = names.map do |name|
      break if random && random_found

      count = get_count(name)
      next if random && count.nil?
      next "#{name}: user does not exist or has no current novel" if count.nil?
      random_found = true

      today = get_today(name)
      nth = ((Time.now - Chronic.parse('1st november 00:00')) / (60*60*24)).ceil
      goal = (@@redis.get("nano:#{name}:goal") || 50_000).to_i
      daygoal = (goal / 30.0 * nth).round
      diff = daygoal - count

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

    if random && counts.compact.length == 0
      m.reply "No users in this channel have novels!"
      return
    end

    m.reply counts.compact.join(', ')
  end
end
