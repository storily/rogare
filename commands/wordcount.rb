# frozen_string_literal: true

class Rogare::Commands::Wordcount
  extend Rogare::Command
  extend Memoist
  include Rogare::Utilities

  command 'wc'
  aliases 'count'
  usage [
    '`!%`, `!% <id>`, `!% <nanoname>`, or `!% <@nick>` (to see others’ counts)',
    '`!% set <words>` or `!% add <words>` - Set or increment your word count.',
    '`!% (set|add) <words> (for|to) <novel ID>` - Set the word count for a particular novel.',
    '`!% set today <words> [for <novel ID>]` - Set the word count for today.',
    '`!% (set|add) yesterday <words> (for|to) <novel ID>` - Set the word count for yesterday (🤯).',
    '`!% add <words> to <novel ID>` - Set the word count for a particular novel.',
    'To register your nano name against your discord user: `!my nano <nanoname>`',
    'To set your goal: `!novel goal set <count>`. To set your timezone: `!my tz <timezone>`.'
  ]
  handle_help

  match_command /set\s+today\s+(\d+)(?:\s+(?:for|to)\s+(\d+))?/, method: :set_today_count
  match_command /set\s+yesterday\s+(\d+)(?:\s+(?:for|to)\s+(\d+))?/, method: :set_count_yesterday
  match_command /add\s+yesterday\s+(-?\d+)(?:\s+(?:for|to)\s+(\d+))?/, method: :add_count_yesterday
  match_command /set\s+(\d+)(?:\s+(?:for|to)\s+(\d+))?/, method: :set_count
  match_command /add\s+(-?\d+)(?:\s+(?:for|to)\s+(\d+))?/, method: :add_count

  match_command /(set|add)\s+.+/, method: :help_message
  match_command /(\d+)/, method: :novel_count
  match_command /(.+)/, method: :other_counts
  match_empty :own_count

  def own_count(m)
    novels = get_counts([m.user.to_db]).first

    return m.reply 'Something is very wrong' unless novels
    return m.reply 'You have no current novel' if novels.empty?

    display_novels m, novels
  end

  def other_counts(m, param = '')
    names = param.strip.split.uniq.compact
    return own_count(m) if names.empty?

    users = get_counts(names.map do |name|
      if /^<@!?\d+>$/.match?(name)
        # Exact match from @mention / mid
        Rogare.from_discord_mid(name).to_db
      else
        # Case-insensitive match from nick
        User.where { nick =~ /^#{name}$/i }.first
      end
    end.compact)

    return m.reply 'No valid users found' unless users
    return m.reply 'No current novels found' if users.select { |n| n.length.positive? }.empty?

    display_novels m, users.flatten(1)
  end

  def novel_count(m, id)
    novel = Novel[id]
    return m.reply 'No such novel' unless novel

    count = get_novel_count novel
    display_novels m, [count]
  end

  def set_count(m, words, id = '')
    novel = m.user.to_db.load_novel id

    return m.reply 'No such novel' if id && !novel
    return m.reply 'You don’t have a novel yet' unless novel
    return m.reply 'Can’t set wordcount of a finished novel' if novel.finished

    novel.wordcount = words.strip.to_i
    own_count(m)
  end

  def set_count_yesterday(m, words, id = '')
    novel = m.user.to_db.load_novel id

    return m.reply 'No such novel' if id && !novel
    return m.reply 'You don’t have a novel yet' unless novel
    return m.reply 'Can’t set wordcount of a finished novel' if novel.finished

    novel.wordcount_yesterday = words.strip.to_i
    own_count(m)
  end

  def set_today_count(m, words, id = '')
    novel = m.user.to_db.load_novel id

    return m.reply 'No such novel' if id && !novel
    return m.reply 'You don’t have a novel yet' unless novel
    return m.reply 'Can’t set wordcount of a finished novel' if novel.finished

    existing = novel.wordcount
    today = novel.todaycount
    gap = words.strip.to_i - today

    novel.wordcount = existing + gap
    own_count(m)
  end

  def add_count_yesterday(m, words, id = '')
    user = m.user.to_db
    novel = user.load_novel id

    return m.reply 'No such novel' if id && !novel
    return m.reply 'You don’t have a novel yet' unless novel
    return m.reply 'Can’t set wordcount of a finished novel' if novel.finished

    existing = novel.wordcount_at(user.timezone.now.beginning_of_day)
    new_words = existing + if words.start_with? '-'
                             words[1..-1].to_i * -1
                           else
                             words.to_i
                           end

    return m.reply "Can’t remove more words than the novel had (#{existing})" if new_words.negative?

    novel.wordcount_yesterday = new_words
    own_count(m)
  end

  def add_count(m, words, id = '')
    novel = m.user.to_db.load_novel id

    return m.reply 'No such novel' if id && !novel
    return m.reply 'You don’t have a novel yet' unless novel
    return m.reply 'Can’t set wordcount of a finished novel' if novel.finished

    existing = novel.wordcount
    new_words = existing + if words.start_with? '-'
                             words[1..-1].to_i * -1
                           else
                             words.to_i
                           end

    return m.reply "Can’t remove more words than the novel has (#{existing})" if new_words.negative?

    novel.wordcount = new_words
    own_count(m)
  end

  def get_novel_count(novel, user = nil)
    user ||= novel.user

    data = {
      user: user,
      novel: novel,
      count: 0
    }

    db_wc = novel.wordcount

    if user.id == 10 && user.nick =~ /\[\d+\]$/ # tamgar sets their count in their nick
      data[:count] = user.nick.split(/[\[\]]/).last.to_i
    elsif db_wc.positive?
      data[:count] = db_wc
      data[:today] = novel.todaycount
    end

    goal = novel.current_goal
    data[:goal] = goal

    # no need to do any time calculations if there's no time limit
    if goal&.finish
      totaldiff = goal.tz_finish - goal.tz_start.end_of_day
      days = (totaldiff / 1.day).to_i
      totaldiff = days.days

      timetarget = goal.tz_finish
      timediff = timetarget - user.now

      data[:days] = {
        total: days,
        length: totaldiff,
        finish: goal.finish,
        left: timediff,
        gone: totaldiff - timediff,
        expired: !timediff.positive?
      }

      unless data[:days][:expired]
        goal_secs = 1.day.to_i * data[:days][:total]

        nth = (data[:days][:gone] / 1.day.to_i).ceil
        fgoal = goal.words.to_f

        count_at_goal_start = if db_wc.positive?
                                novel.wordcount_at goal.tz_start
                              else
                                0
                              end

        count_from_goal_start = data[:count] - count_at_goal_start

        goal_live = ((fgoal / goal_secs) * data[:days][:gone]).round
        goal_today = (fgoal / data[:days][:total] * nth).round

        data[:target] = {
          diff: goal_today - count_from_goal_start,
          live: goal_live - count_from_goal_start,
          percent: (100.0 * count_from_goal_start / fgoal).round(1)
        }
      end
    end

    data
  end

  def get_counts(users)
    users.map do |user|
      user.current_novels.map do |novel|
        get_novel_count novel, user
      end
    end
  end

  def display_novels(m, novels)
    # if rand > 0.5 && !novels.select { |n| n[:novel][:type] == 'nano' && n[:count] > 100_000 }.empty?
    #   m.reply "Content Warning: #{%w[Astonishing Wondrous Beffudling Shocking Monstrous].sample} Wordcount"
    #   sleep 1
    # end

    m.reply novels.map { |n| format n }.join("\n")
  end

  def format(count)
    deets = []

    deets << "#{count[:target][:percent]}%" if count[:target]
    deets << "today: #{count[:today]}" if count[:today]

    if count[:target]
      diff = count[:target][:diff]
      deets << if diff.zero?
                 'up to date'
               elsif diff.positive?
                 "#{diff} behind"
               else
                 "#{diff.abs} ahead"
               end

      live = count[:target][:live]
      deets << if live.zero?
                 'up to live'
               elsif live.positive?
                 "#{live} behind live"
               else
                 "#{live.abs} ahead live"
               end
    end

    if count[:goal]
      if count[:days] && count[:days][:expired]
        deets << count[:goal].format_words
        deets << "over #{count[:days][:total]} days"
        deets << 'expired'
      elsif count[:target]
        deets << count[:goal].format_words
        days = (count[:days][:left] / 1.day.to_i).floor
        deets << (days == 1 ? 'one day left' : "#{days} days left")
      else
        deets << count[:goal].format_words
      end
    end

    name = count[:novel][:name]
    name = name[0, 35] + '…' if name && name.length > 40
    name = " _“#{encode_entities name}”_" if name

    "[#{count[:novel][:id]}] #{count[:user][:nick]}:#{name} — **#{count[:count]}** (#{deets.join(', ')})"
  end
end
