# frozen_string_literal: true

class Rogare::Commands::Wordwar
  extend Rogare::Command

  command 'wordwar'
  aliases 'war', 'ww'
  usage [
    '`!% in [time before it starts (in minutes)] for [duration]`',
    'Or: `!% at [wall time e.g. 12:35] for [duration]`',
    'Or even (defaulting to a 15 minute run): `!% at/in [time]`',
    'And then everyone should: `!% join [wordwar ID]`',
    'Also say `!%` alone to get a list of current/scheduled ones',
    'To get some details about a war: `!% info [ID]` or `!% members [ID]`.'
  ]
  handle_help

  match_command /join(.*)/, method: :ex_join_war
  match_command /leave(.*)/, method: :ex_leave_war
  match_command /cancel(.*)/, method: :ex_cancel_war
  match_command /info(.*)/, method: :ex_war_info
  match_command /members(.*)/, method: :ex_war_members

  # Often people type it the other way
  match_command /(\d+)\s+join/, method: :ex_join_war
  match_command /(\d+)\s+leave/, method: :ex_leave_war
  match_command /(\d+)\s+cancel/, method: :ex_cancel_war
  match_command /(\d+)\s+info/, method: :ex_war_info
  match_command /(\d+)\s+members/, method: :ex_war_members

  match_command /((?:\d+:\d+|in|at).+)/
  match_command /.+/, method: :ex_list_wars
  match_empty :ex_list_wars

  def execute(m, param)
    user = m.user.to_db

    param.sub!(/#.+$/, '')
    time, durstr = param.strip.split(/for/i).map(&:strip)

    atmode = time =~ /^at/i
    time = time.sub(/^at/i, '').strip if time.downcase.start_with? 'at'
    durstr = '15 minutes' if durstr.nil? || durstr.empty?

    # TODO: timezones
    timenow = Time.now

    time = time.match(/(\d{1,2})(\d{2})/)[1..2].join(':') if atmode && /^\d{3,4}$/.match?(time)

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

    begin
      war = War.new(
        start: time,
        seconds: duration,
        channels: [m.channel.to_s]
      )

      raise 'War is in the past???' unless war.future?

      war.creator = user
      war.save
      war.add_member user
    rescue StandardError => err
      logs [err.message, err.backtrace].flatten.join("\n")
      return m.reply 'Got an error, check your times and try again.'
    end

    togo = dur_display(timeat, timenow)
    dur, = dur_display(timeat + duration, timeat)

    m.reply 'Got it! ' \
            "Your new wordwar will start in #{togo} and last #{dur}. " \
            "Others can join it with: `#{Rogare.prefix}ww join #{war.id}`"

    self.class.start_war_timer(war).join
  end

  def dur_display(*args)
    self.class.dur_display(*args)
  end

  def say_war_info(m, war)
    togo, neg = dur_display war.start
    others = war.others.count
    chans = war.discord_channels.map(&:pretty).join(', ')

    m.reply [
      "#{war.id}: #{war.creator.nixnotif}'s war",

      if neg
        "started #{togo} ago"
      else
        "starting in #{togo}"
      end,

      if neg
        "#{dur_display(Time.now, war.finish).first} left"
      else
        "for #{dur_display(war.finish, war.start).first}"
      end,

      ("with #{others} others" unless others.zero?),

      ("in #{chans}" unless war.channels.count <= 1 && war.channels.include?(m.channel.to_s))
    ].compact.join(', ')
  end

  def ex_list_wars(m)
    wars = War.all_current.map { |war| say_war_info m, war }
    m.reply 'No current wordwars' if wars.empty?
  end

  def ex_war_info(m, id)
    war = War[id.to_i]
    return m.reply 'No such wordwar' unless war&.current?

    say_war_info m, war
  end

  def ex_war_members(m, id)
    war = War[id.to_i]
    return m.reply 'No such wordwar' unless war&.current?

    others = war.others.map(&:nixnotif).join(', ')
    others = 'no one else :(' if others.empty?

    m.reply "#{war.id}: #{war.creator.nixnotif}’s war, with: #{others}"
  end

  def ex_join_war(m, id)
    user = m.user.to_db
    war = War[id.to_i]
    return m.reply 'No such wordwar' unless war&.current?

    war.add_member! user
    war.add_channel m.channel.to_s
    war.save

    m.reply "You're in!"
  end

  def ex_leave_war(m, id)
    user = m.user.to_db
    war = War[id.to_i]
    return m.reply 'No such wordwar' unless war&.current?

    war.remove_member user

    m.reply "You're out."
  end

  def ex_cancel_war(m, id)
    user = m.user.to_db
    war = War[id.to_i]
    return m.reply 'No such wordwar' unless war&.current?

    war.cancel! user

    m.reply "Wordwar #{war.id} cancelled."
  end

  class << self
    def start_war_timer(war)
      Thread.new do
        next if war.cancelled

        reply = ->(msg) { war.broadcast msg }

        starting = lambda { |time, &block|
          war.refresh
          next unless war.current?

          members = war.members.map(&:mid).join(', ')
          extra = ' ' + block.call unless block.nil?
          reply.call "Wordwar #{war.id} is starting #{time}! #{members}#{extra}"
        }

        ending = lambda {
          war.refresh
          next if war.cancelled

          members = war.members.map(&:mid).join(', ')
          reply.call "Wordwar #{war.id} has ended! #{members}"
        }

        if war.til_start.positive?
          # We're before the start of the war

          if war.til_start > 35
            # If we're at least 35 seconds before the start, we have
            # time to send a reminder. Otherwise, skip sending it.
            sleep war.til_start - 30
            starting.call('in 30 seconds') { '— Be ready: tell us your starting wordcount.' }
            sleep 30
          else
            # In any case, we sleep until the beginning
            sleep war.til_start
          end

          starting.call('now') { "(for #{dur_display(war.end, war.start).first})" }
          war.start!
          sleep war.seconds
          ending.call
          war.finish!
        elsif war.til_finish.negative? && !war.ended
          # We're after the END of the war, but the war is not marked
          # as ended, so it must be that the war ended as the bot was
          # restarting! Oh no. That means we're probably a bit late.
          ending.call
          war.finish!
        else
          # We're AFTER the start of the war. Probably because the
          # bot restarted while a war was running.

          unless war.started
            # The war is not marked as started but it is started, so
            # the bot probably restarted at the exact moment the war
            # was supposed to start. That means we're probably late.
            starting.call 'just now'
            war.start!
          end

          sleep war.til_finish
          ending.call
          war.finish!
        end
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

    def load_existing_wars
      War.all_existing.map do |war|
        start_war_timer(war)
      end
    end
  end
end
