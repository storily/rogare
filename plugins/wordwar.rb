# frozen_string_literal: true

class Rogare::Plugins::Wordwar
  extend Rogare::Plugin

  command 'wordwar'
  aliases 'war', 'ww'
  usage [
    '!% in [time before it starts (in minutes)] for [duration]',
    'Or: !% at [wall time e.g. 12:35] for [duration]',
    'Or even (defaulting to a 15 minute run): !% at/in [time]',
    'And then everyone should: !% join [wordwar ID]',
    'Also say !% alone to get a list of current/scheduled ones',
    'To get some details about a war: !% info [ID] or !% members [ID].'
  ]
  handle_help

  @@redis = Rogare.redis(3)

  match_command /join(.*)/, method: :ex_join_war
  match_command /leave(.*)/, method: :ex_leave_war
  match_command /cancel(.*)/, method: :ex_cancel_war
  match_command /info(.*)/, method: :ex_war_info
  match_command /members(.*)/, method: :ex_war_members
  match_command /(.+)/
  match_empty :ex_list_wars

  def execute(m, param)
    param.sub!(/#.+$/, '')
    time, durstr = param.strip.split(/for/i).map(&:strip)

    time = time.sub(/^at/i, '').strip if time.downcase.start_with? 'at'
    durstr = '15 minutes' if durstr.nil? || durstr.empty?

    timenow = Time.now

    timeat = Chronic.parse(time)
    timeat = Chronic.parse("in #{time}") if timeat.nil?
    timeat = Chronic.parse("in #{time} minutes") if timeat.nil?
    timeat = Chronic.parse("#{time} minutes") if timeat.nil?
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

    if timeat > timenow + 36 * 60 * 60
      m.reply 'Cannot schedule more than 36 hours in the future, sorry'
      return
    end

    duration = ChronicDuration.parse("#{durstr} minutes")
    if duration.nil?
      m.reply "Can't parse duration: #{durstr}"
      return
    end

    k = self.class.store_war(m, timeat, duration)
    togo, neg = dur_display(timeat, timenow)
    dur, = dur_display(timeat + duration, timeat)

    if k.nil? || neg
      m.reply 'Got an error, check your times and try again.'
      return
    end

    m.reply 'Got it! ' \
            "Your new wordwar will start in #{togo} and last #{dur}. " \
            "Others can join it with: !wordwar join #{k}"

    self.class.set_war_timer(k, timeat, duration).join
  end

  def rk(*args)
    self.class.rk(*args)
  end

  def dur_display(*args)
    self.class.dur_display(*args)
  end

  def all_wars(*args)
    self.class.all_wars(*args)
  end

  def war_info(*args)
    self.class.war_info(*args)
  end

  def say_war_info(m, war)
    togo, neg = dur_display war[:start]
    others = war[:members].reject { |u| u == war[:owner] }

    m.reply [
      "#{war[:id]}: #{Rogare.nixnotif war[:owner]}'s war",

      if neg
        "started #{togo} ago"
      else
        "starting in #{togo}"
      end,

      if neg
        "#{dur_display(Time.now, war[:end]).first} left"
      else
        "for #{dur_display(war[:end], war[:start]).first}"
      end,

      ("with #{others.count} others" unless others.empty?),

      ("in #{war[:channels].join(', ')}" unless war[:channels].count <= 1 && war[:channels].include?(m.channel.to_s))
    ].compact.join(', ')
  end

  def ex_list_wars(m)
    wars = all_wars
           .reject { |w| w[:end] < Time.now }
           .sort_by { |w| w[:start] }

    if rand < 0.9 && (Time.now < Time.at(1_541_847_600))
      # War 60 is a special long-running war. We want it to still be there,
      # but not to advertise its presence all the time, unless we're close!
      wars.reject! { |w| w[:id].to_s == '60' }
    end

    wars.each do |war|
      say_war_info m, war
    end

    m.reply 'No current wordwars' if wars.empty?
  end

  def ex_war_info(m, param)
    k = param.strip.to_i
    return m.reply 'You need to specify the wordwar ID' if k.zero?

    return m.reply 'No such wordwar' unless @@redis.exists rk(k, 'start')

    say_war_info m, war_info(k)
  end

  def ex_war_members(m, param)
    k = param.strip.to_i
    return m.reply 'You need to specify the wordwar ID' if k.zero?

    return m.reply 'No such wordwar' unless @@redis.exists rk(k, 'start')

    war = war_info(k)
    others = war[:members].reject { |u| u == war[:owner] }
    others = if others.empty?
               'no one else :('
             else
               others.map { |u| Rogare.nixnotif u }.join(', ')
             end

    m.reply "#{war[:id]}: #{Rogare.nixnotif war[:owner]}'s war, with: #{others}"
  end

  def ex_join_war(m, param)
    k = param.strip.to_i
    return m.reply 'You need to specify the wordwar ID' if k.zero?

    return m.reply 'No such wordwar' unless @@redis.exists rk(k, 'start')

    @@redis.sadd rk(k, 'channels'), m.channel.to_s
    @@redis.sadd rk(k, 'members'), m.user.mid
    m.reply "You're in!"
  end

  def ex_leave_war(m, param)
    k = param.strip.to_i
    return m.reply 'You need to specify the wordwar ID' if k.zero?

    return m.reply 'No such wordwar' unless @@redis.exists rk(k, 'start')

    @@redis.srem rk(k, 'members'), m.user.mid
    m.reply "You're out."
  end

  def ex_cancel_war(m, param)
    k = param.strip.to_i
    return m.reply 'You need to specify the wordwar ID' if k.zero?

    return m.reply 'No such wordwar' unless @@redis.exists rk(k, 'start')

    self.class.erase_war k
    m.reply "Wordwar #{k} deleted."
  end

  class << self
    def set_war_timer(id, start, duration)
      Thread.new do
        reply = lambda do |msg|
          war_info(id)[:channels].each do |cname|
            chan = Rogare.find_channel cname

            if chan.nil?
              logs "=====> Error: no such channel: #{cname}"
              next
            elsif chan.is_a? Array
              logs "=====> Error: multiple channels match: #{cname} -> #{chan.inspect}"
              # Don't spam, don't send to all chans that match - assume error
              next
            end

            chan.send msg
          end
        end

        starting = lambda { |time, &block|
          war = war_info(id)
          members = war[:members].join(', ')
          extra = ' ' + block.call(war) unless block.nil?
          reply.call "Wordwar #{id} is starting #{time}! #{members}#{extra}"
        }

        ending = lambda {
          members = war_info(id)[:members].join(', ')
          reply.call "Wordwar #{id} has ended! #{members}"
        }

        to_start = start - Time.now
        if to_start.positive?
          # We're before the start of the war

          if to_start > 35
            # If we're at least 35 seconds before the start, we have
            # time to send a reminder. Otherwise, skip sending it.
            sleep to_start - 30
            starting.call('in 30 seconds') { '— Be ready: tell us your starting wordcount.' }
            sleep 30
          else
            # In any case, we sleep until the beginning
            sleep to_start
          end

          starting.call('now') { |war| "(for #{dur_display(war[:end], war[:start]).first})" }
          start_war id
          sleep duration
          ending.call
          erase_war id
        else
          # We're AFTER the start of the war. Probably because the
          # bot restarted while a war was running.

          to_end = (start + duration) - Time.now
          if to_end.negative?
            # We're after the END of the war, but before Redis expired
            # the keys, and also the keys were not erased manually, so
            # it must be that the war ended as the bot was restarting!
            # Oh no. That means we're probably a bit late.
            ending.call
            erase_war id
          else
            unless @@redis.exists rk(id, 'started')
              # The war is not marked as started but it is started, so
              # the bot probably restarted at the exact moment the war
              # was supposed to start. That means we're probably late.
              starting.call 'just now'
              start_war id
            end

            sleep to_end
            ending.call
            erase_war id
          end
        end
      end
    end

    def start_war(id)
      @@redis.set rk(id, 'started'), '1'
    end

    def erase_war(id)
      @@redis.keys(rk(id, '*')).each do |k|
        @@redis.rename k, "archive:#{k}"
      end
    end

    def dur_display(time, now = Time.now)
      diff = time - now
      minutes = diff / 60.0
      secs = (minutes - minutes.to_i).abs * 60.0

      neg = false
      if minutes.negative?
        minutes = minutes.abs
        neg = true
      end

      [if minutes >= 5
         "#{minutes.round}m"
       elsif minutes >= 1
         "#{minutes.floor}m #{secs.round}s"
       else
         "#{secs.round}s"
       end, neg]
    end

    def rk(war, sub = nil)
      ['wordwar', war, sub].compact.join ':'
    end

    def all_wars
      @@redis.keys(rk('*', 'start')).map do |k|
        war_info k.gsub(/(^wordwar:|:start$)/, '')
      end
    end

    def war_info(id)
      {
        id: id,
        channels: @@redis.smembers(rk(id, 'channels')),
        owner: @@redis.get(rk(id, 'owner')),
        members: @@redis.smembers(rk(id, 'members')),
        start: Chronic.parse(@@redis.get(rk(id, 'start'))),
        end: Chronic.parse(@@redis.get(rk(id, 'end')))
      }
    end

    def store_war(m, time, duration)
      # War is in the past???
      return if ((time + duration) - Time.now).to_i.negative?

      k = @@redis.incr rk('count')

      @@redis.multi do
        @@redis.sadd rk(k, 'channels'), m.channel.to_s
        @@redis.set rk(k, 'owner'), m.user.mid
        @@redis.sadd rk(k, 'members'), m.user.mid
        @@redis.set rk(k, 'start'), time.to_s
        @@redis.set rk(k, 'end'), (time + duration).to_s
      end
      k
    end

    def load_existing_wars
      all_wars.reject { |w| w[:end] < Time.now }.map do |war|
        set_war_timer(war[:id], war[:start], war[:end] - war[:start])
      end
    end
  end
end
