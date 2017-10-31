class Rogare::Plugins::Wordwar
  include Cinch::Plugin

  match /(wordwar|war|ww)\s*(.*)/
  @@usage = [
      'Use: !wordwar in [time before it starts (in minutes)] for [duration]',
      'Or:  !wordwar at [wall time e.g. 12:35] for [duration]',
      'Or even (defaulting to a 20 minute run): !wordwar at/in [time]',
      'And then everyone should: !wordwar join [wordwar ID]',
      'Also say !wordwar alone to get a list of current/scheduled ones.'
  ]

  @@redis = Redis.new db: 3

  def execute(m, cat, param)
    param = param.strip
    if param =~ /^(help|\?|how|what|--help|-h)/
      @@usage.each {|l| m.reply l}
      return
    end

    if param.empty?
      return ex_list_wars(m)
    end

    if param =~ /^join/
      return ex_join_war(m, param)
    end

    if param =~ /^leave/
      return ex_leave_war(m, param)
    end

    time, durstr = param.split('for').map {|p| p.strip}

    time = time.sub(/^at/, '').strip if time.start_with? 'at'
    durstr = "20 minutes" if durstr.nil? || durstr.empty?

    timenow = Time.now

    timeat = Chronic.parse(time)
    timeat = Chronic.parse("in #{time}") if timeat.nil?
    if timeat.nil?
      m.reply "Can't parse time: #{time}"
      return
    end

    if timeat < timenow && time.to_i < 13
      # This is if someone entered 12-hour PM time,
      # and it parsed as AM time, e.g. 9:00.
      timeat += 12 * 60 * 60
    end

    if timeat < timenow
      # If time is still in the past, something is wrong
      m.reply "#{time} is in the past, what???"
      return
    end

    if timeat > timenow + 12 * 60 * 60
      m.reply "Cannot schedule more than 12 hours in the future, sorry"
      return
    end

    duration = ChronicDuration.parse("#{durstr} minutes")
    if duration.nil?
      m.reply "Can't parse duration: #{durstr}"
      return
    end

    k = store_war(m.user.nick, timeat, duration)
    togo, neg = dur_display(timeat, timenow)
    dur, _ = dur_display(timeat + duration, timeat)

    if k.nil? || neg
      m.reply "Got an error, check your times and try again."
      return
    end

    m.reply "Got it! " +
      "Your wordwar will start in #{togo} and last #{dur}. " +
      "Others can join it with: !wordwar join #{k}"
  end

  def ex_list_wars(m)
    wars = all_wars
      .reject {|w| w[:end] < Time.now}
      .sort_by {|w| w[:start]}

    wars.each do |war|
      togo, neg = dur_display war[:start]
      dur, _ = dur_display war[:end], war[:start]
      others = war[:members].reject {|u| u == war[:owner]}

      m.reply [
        "#{war[:id]}: #{nixnotif war[:owner]}'s war",
        if neg
          "started #{togo} ago"
        else
          "starting in #{togo}"
        end,
        "for #{dur}",
        unless others.empty?
          "with #{others.count} others"
        end
      ].compact.join(', ')
    end

    if wars.empty?
      m.reply "No current wordwars"
    end
  end

  def ex_join_war(m, param)
    k = param.sub(/^join/, '').strip.to_i
    return m.reply "You need to specify the wordwar ID" if k == 0

    unless @@redis.exists rk(k, 'start')
      return m.reply "No such wordwar"
    end

    @@redis.sadd rk(k, 'members'), m.user.nick
    m.reply "You're in!"
  end

  def ex_leave_war(m, param)
    k = param.sub(/^leave/, '').strip.to_i
    return m.reply "You need to specify the wordwar ID" if k == 0

    unless @@redis.exists rk(k, 'start')
      return m.reply "No such wordwar"
    end

    @@redis.srem rk(k, 'members'), m.user.nick
    m.reply "You're out."
  end

  def dur_display(time, now = Time.now)
    diff = time - now
    minutes = diff / 60.0
    secs = (minutes - minutes.to_i).abs * 60.0

    neg = false
    if minutes < 0
      minutes = minutes.abs
      neg = true
    end

    [if minutes > 5
      "#{minutes.round}m"
    elsif minutes > 1
      "#{minutes.floor}m #{secs.round}s"
    else
      "#{secs.round}s"
    end, neg]
  end

  def nixnotif(nick)
    # Insert a zero-width space as the second character of the nick
    # so that it doesn't notify that user. People using web clients
    # or desktop clients shouldn't see anything, people with terminal
    # clients may see a space, and people with bad clients may see a
    # weird box or invalid char thing.
    nick.sub(/^(.)/, "\\1\u200B")
  end

  def rk(war, sub = nil)
    ['wordwar', war, sub].compact.join ':'
  end

  def all_wars
    @@redis.keys(rk('*', 'start')).map do |k|
      k.gsub /(^wordwar:|:start$)/, ''
    end.map do |k|
      {
        id: k,
        owner: @@redis.get(rk(k, 'owner')),
        members: @@redis.smembers(rk(k, 'members')),
        start: Chronic.parse(@@redis.get(rk(k, 'start'))),
        end: Chronic.parse(@@redis.get(rk(k, 'end'))),
      }
    end
  end

  def store_war(user, time, duration)
    k = @@redis.incr rk('count')
    ex = ((time + duration + 5) - Time.now).to_i # Expire 5 seconds after it ends
    return if ex < 6 # War is in the past???

    @@redis.multi do
      @@redis.set rk(k, 'owner'), user, ex: ex
      @@redis.sadd rk(k, 'members'), user
      @@redis.expire rk(k, 'members'), ex
      @@redis.set rk(k, 'start'), "#{time}", ex: ex
      @@redis.set rk(k, 'end'), "#{time + duration}", ex: ex
    end
    k
  end
end
