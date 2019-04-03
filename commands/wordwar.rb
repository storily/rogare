# frozen_string_literal: true

class Rogare::Commands::Wordwar
  extend Rogare::Command
  include Rogare::Utilities

  command 'wordwar'
  aliases 'war', 'ww'
  usage [
    '`!% in [time before it starts (in minutes)] for [duration]`',
    'Or: `!% at [wall time e.g. 12:35] for [duration]`',
    'Or even (defaulting to a 15 minute run): `!% at/in [time]`',
    'And then everyone should: `!% join [wordwar ID]`',
    'And add their total at the end with `!% total [ID] [total]`',
    'Then get the summary with `!% summary [ID]`',
    'Also say `!%` alone to get a list of current/scheduled ones',
    'To get some details about a war: `!% info [ID]` or `!% members [ID]`.'
  ]
  handle_help

  match_command /join(.*)/, method: :ex_join_war
  match_command /leave(.*)/, method: :ex_leave_war
  match_command /cancel(.*)/, method: :ex_cancel_war
  match_command /total(.*)/, method: :ex_total_war
  match_command /info(.*)/, method: :ex_war_info
  match_command /summary(.*)/, method: :ex_war_summary
  match_command /members(.*)/, method: :ex_war_members

  # Often people type it the other way
  match_command /(\d+)\s+join/, method: :ex_join_war
  match_command /(\d+)\s+leave/, method: :ex_leave_war
  match_command /(\d+)\s+cancel/, method: :ex_cancel_war
  match_command /(\d+)\s+total/, method: :ex_total_war
  match_command /(\d+)\s+info/, method: :ex_war_info
  match_command /(\d+)\s+summary/, method: :ex_war_summary
  match_command /(\d+)\s+members/, method: :ex_war_members

  match_command /((?:\d+:\d+|in|at).+)/
  match_command /.+/, method: :ex_list_wars
  match_empty :ex_list_wars

  def execute(m, param)
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
      timeat += 12.hour
    end

    if timeat < timenow
      # If time is still in the past, something is wrong
      m.reply "#{time} is in the past, what???"
      return
    end

    if time.to_i < 13 && timeat.hour < 13 && timenow.hour > 12 &&
       (timeat > timenow.midnight + 1.day) &&
       (timeat - 12.hour > timenow)
      # This is if someone entered 12-hour PM time,
      # and it parsed as AM time the NEXT day.
      timeat -= 12.hour
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
        start: timeat,
        seconds: duration,
        channels: [m.channel.to_s]
      )

      raise 'War is in the past???' unless war.future?

      war.creator = m.user
      war.save
      war.add_member m.user
    rescue StandardError => err
      logs [err.message, err.backtrace].flatten.join("\n")
      return m.reply 'Got an error, check your times and try again.'
    end

    togo, = dur_display(timeat, timenow)
    dur, = dur_display(timeat + duration, timeat)

    m.reply 'Got it! ' \
            "Your new wordwar will start in #{togo} and last #{dur}. " \
            "Others can join it with: `#{Rogare.prefix}ww join #{war.id}`"

    war.start_timer.join
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
    war = War[id.to_i]
    return m.reply 'No such wordwar' unless war&.current?

    war.add_member! m.user
    war.add_channel m.channel.to_s
    war.save

    m.reply "You're in!"
  end

  def ex_leave_war(m, id)
    war = War[id.to_i]
    return m.reply 'No such wordwar' unless war&.current?

    war.remove_member m.user

    m.reply "You're out."
  end

  def ex_cancel_war(m, id)
    war = War[id.to_i]
    return m.reply 'No such wordwar' unless war&.current?

    war.cancel! m.user

    m.reply "Wordwar #{war.id} cancelled."
  end

  def ex_total_war(m, id)
    types = %w[words lines pages minutes]
    data = id.split(' ')
    check = begin
              data[1].to_i
            rescue StandardError
              nil
            end
    war = War[data[0].to_i]
    data[2] ||= 'words'

    return m.reply 'No such wordwar' unless war&.exists?
    return m.reply 'It\'s not over yet' if war.current?
    return m.reply 'That\'s not a valid total' if check.nil?
    return m.reply 'That\'s not a valid type' unless types.include? data[2]

    war.add_total(m.user, data[1].to_i, data[2])

    m.reply 'Got it!'
  end

  def ex_war_summary(m, id)
    war = War[id.to_i]

    return m.reply 'No such wordwar' unless war&.exists?
    return m.reply 'It\'s not over yet' if war.current?

    members = war.totals

    m.reply "**Statistics for war #{id.to_i}:**\n\n" +
            members.join("\n")
  end
end
