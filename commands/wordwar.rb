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
    # 'And add their total at the end with `!% total [ID] [total]`',
    # 'Then get the summary with `!% summary [ID]`',
    'Also say `!%` alone to get a list of current/scheduled ones',
    'To get some details about a war: `!% info [ID]` or `!% members [ID]`.'
  ]
  handle_help

  match_command /join(.*)/, method: :ex_join_war
  match_command /leave(.*)/, method: :ex_leave_war
  match_command /cancel(.*)/, method: :ex_cancel_war
  match_command /total\s+(\d+)\s+(.*)/, method: :ex_total_war
  match_command /words\s+(\d+k?)/, method: :ex_words_war
  match_command /info(.*)/, method: :ex_war_info
  match_command /summary(.*)/, method: :ex_war_summary
  match_command /members(.*)/, method: :ex_war_members

  # Often people type it the other way
  match_command /(\d+)\s+join/, method: :ex_join_war
  match_command /(\d+)\s+leave/, method: :ex_leave_war
  match_command /(\d+)\s+cancel/, method: :ex_cancel_war
  match_command /(\d+)\s+total\s+(.*)/, method: :ex_total_war
  match_command /(\d+)\s+words\s+(\d+k?)/, method: :ex_words_war
  match_command /(\d+)\s+info/, method: :ex_war_info
  match_command /(\d+)\s+summary/, method: :ex_war_summary
  match_command /(\d+)\s+members/, method: :ex_war_members

  match_command /((?:\d+:\d+|in|at).+)/
  match_command /.+/, method: :ex_list_wars
  match_empty :ex_list_wars

  def execute(m, param)
    param.sub!(/#.+$/, '')
    time, durstr = param.strip.split(/for/i).map(&:strip)

    sudo = time =~ /!$/ || (!durstr.nil? && durstr =~ /!$/)
    time.sub!(/!$/, '')
    durstr&.sub!(/!$/, '')

    atmode = time =~ /^at/i
    time = time.sub(/^at/i, '').strip if time.downcase.start_with? 'at'
    durstr = '15 minutes' if durstr.nil? || durstr.empty?

    # TODO: timezones for 'at XXXX'
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

    if timeat < timenow && time.slice(0, 2).to_i < 13
      # This is if someone entered 12-hour PM time,
      # and it parsed as AM time, e.g. 9:00.
      timeat += 12.hour
    end

    if timeat < timenow
      # If time is still in the past, something is wrong
      m.reply [
        "#{time} is in the past, what???",
        'I can’t time-travel _that_ far',
        'Historical AUs go in your draft, not in your wars!',
        'If I found a way to travel back in time, I would use it to tell you off.',
        'hmmmmmmmmm. no.'
      ].sample
      return
    end

    if time.slice(0, 2).to_i < 13 && timeat.hour < 13 && timenow.hour > 12 &&
       (timeat > timenow.midnight + 1.day) &&
       (timeat - 12.hour > timenow)
      # This is if someone entered 12-hour PM time,
      # and it parsed as AM time the NEXT day.
      timeat -= 12.hour
    end

    if timeat > timenow + 22.hour
      if sudo
        m.reply [
          'With a bit of luck this isn’t a mistake.',
          'My checking code is off to make itself a sandwich, hope you know what you’re doing.',
          'Roses are nominally red, violets are sometimes blue, errors are whatever you make them to be, baby.',
          '_sparkles mischievously_',
          'Oh hey, you found my dangerous side. Let’s go for a ride.'
        ].sample
      else
        m.reply [
          'Cannot schedule more than 22 hours in the future, sorry',
          'Nope',
          'No can do',
          'Try with more bang!',
          'You’re asking the imp… er. Well, the improbable, at least.',
          'meenie minie moe… for you this will be no!'
        ].sample
        return
      end
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

  def ex_total_war(m, id, param)
    types = %w[words lines pages minutes]
    data = param.split(' ')
    war = War[id]

    total = data[0].to_i
    type = data[1] ||= 'words'

    return m.reply 'No such wordwar' unless war&.exists?
    return m.reply 'It’s not over yet' if war.current?
    return m.reply 'That’s not a valid total' if total.zero?
    return m.reply 'That’s not a valid type' unless types.include? type

    war.add_total(m.user, total, type)
    m.reply 'Got it!'
  end

  def ex_words_war(m, id, words = nil)
    if words
      war = War[id]
      member = WarMember[war_id: id, user_id: m.user.id]
    else
      words = id
      war, member = m.user.latest_war
    end

    return m.reply 'No such wordwar' unless war&.exists?
    return m.reply 'Not a member of that war' unless member&.exists?

    words = if words.end_with? 'k'
              words.to_i * 1000
            else
              words.to_i
            end

    if war.ended
      member.save_ending! words
      m.reply "You finished war #{war.id} with " \
        "(#{member.ending} - #{member.starting}) = " \
        "**#{member.total}** #{member.total_type}."

      ex_war_summary(m, war.id) unless war.memberships_dataset.where(ending: 0).count.positive?
    else
      member.save_starting! words
      m.reply "You’re starting war #{war.id} with **#{member.starting}** #{member.total_type}."
    end
  end

  def ex_war_summary(m, id)
    war = War[id.to_i] || m.user.latest_war & [0]

    return m.reply 'No such wordwar' unless war&.exists?
    return m.reply 'It’s not over yet' if war.current?

    m.reply "**Statistics for war #{id.to_i}:**\n" +
            war.totals.join("\n")
  end
end
