# frozen_string_literal: true

class Rogare::Commands::Wordcount
  extend Rogare::Command
  extend Memoist

  command 'wc'
  aliases 'count'
  usage [
    '`!%`, `!% <id>`, `!% <nanoname>`, or `!% <@nick>` (to see others’ counts)',
    'To register your nano name against your discord user: `!my nano <nanoname>`',
    'To set your goal: `!novel goal set <count>`. To set your timezone: `!my tz <timezone>`.'
  ]
  handle_help

  def nano_get_today(name)
    res = Typhoeus.get "https://nanowrimo.org/participants/#{name}/stats"
    return unless res.code == 200

    doc = Nokogiri::HTML res.body
    doc.at_css('#novel_stats .stat:nth-child(2) .value').content.gsub(/[,\s]/, '').to_i
  end

  def nano_get_count(name)
    res = Typhoeus.get "https://nanowrimo.org/wordcount_api/wc/#{name}"
    return unless res.code == 200

    doc = Nokogiri::XML(res.body)
    return unless doc.css('error').empty?

    doc.at_css('user_wordcount').content.to_i
  end

  match_command /(\d+)/, method: :novel_count
  match_command /(.+)/, method: :other_counts
  match_empty :own_count

  def own_count(m)
    novels = get_counts([m.user]).first

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

  def get_project_count(novel, user = nil)
    user ||= novel.user

    data = {
      user: user,
      novel: novel,
      count: 0
    }

    if user.id == 10 && user.nick =~ /\[\d+\]$/ # tamgar sets their count in their nick
      data[:count] = user.nick.split(/[\[\]]/).last.to_i
    elsif novel[:type] == 'nano' # TODO: camp
      data[:count] = nano_get_count(user.nano_user) || 0
      data[:today] = nano_get_today(user.nano_user) if data[:count].positive?
    end

    goal = novel.current_goal
    data[:goal] = goal

    # no need to do any time calculations if there's no time limit
    if goal&.finish
      tz = TimeZone.new(user.tz)
      now = tz.now

      gstart = tz.local goal.start.year, goal.start.month, goal.start.day
      gfinish = tz.local(goal.finish.year, goal.finish.month, goal.finish.day).end_of_day

      totaldiff = gfinish - gstart.end_of_day
      days = (totaldiff / 1.day).to_i
      totaldiff = days.days

      timetarget = gfinish
      timediff = timetarget - now

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
        goal = goal.words.to_f

        count_at_goal_start = if db_wc.positive?
                                novel.wordcount_at gstart
                              else
                                0
                              end

        count_from_goal_start = data[:count] - count_at_goal_start

        goal_live = ((goal / goal_secs) * data[:days][:gone]).round
        goal_today = (goal / data[:days][:total] * nth).round

        data[:target] = {
          diff: goal_today - count_from_goal_start,
          live: goal_live - count_from_goal_start,
          percent: (100.0 * count_from_goal_start / goal).round(1)
        }
      end
    end

    data
  end

  def get_counts(users)
    users.map do |user|
      user.current_projects.map do |novel|
        get_project_count novel, user
      end
    end
  end

  def display_novels(m, novels)
    if rand > 0.5 && !novels.select { |n| n[:novel][:type] == 'nano' && n[:count] > 100_000 }.empty?
      m.reply "Content Warning: #{%w[Astonishing Wondrous Beffudling Shocking Monstrous].sample} Wordcount"
      sleep 1
    end

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
      if count[:novel][:type] == 'nano'
        deets << goal_format(count[:goal][:words]) unless count[:goal][:words] == 50_000
        deets << 'nano has ended' if count[:days][:expired]
      elsif count[:days] && count[:days][:expired]
        deets << goal_format(count[:goal][:words])
        deets << "over #{count[:days][:total]} days"
        deets << 'expired'
      elsif count[:target]
        deets << goal_format(count[:goal][:words])
        days = (count[:days][:left] / 1.day.to_i).floor
        deets << (days == 1 ? 'one day left' : "#{days} days left")
      else
        deets << goal_format(count[:goal][:words])
      end
    end

    name = count[:novel][:name]
    name = name[0, 35] + '…' if name && name.length > 40
    name = " _“#{name}”_" if name

    "[#{count[:novel][:id]}] #{count[:user][:nick]}:#{name} — **#{count[:count]}** (#{deets.join(', ')})"
  end

	def goal_format(goal)
		if goal < 1_000
			"#{goal} words goal"
		elsif goal < 10_000
			"#{(goal / 1_000.0).round(1)}k goal"
		else
			"#{(goal / 1_000.0).round}k goal"
		end
	end
end
