class Rogare::Plugins::Nano
  include Cinch::Plugin
  extend Rogare::Help
  extend Memoist

  command 'count'
  aliases 'wc'
  usage '!% [username(s) to search, or "set" then a username to remember your NaNoWriMo username]'
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

  match_command /set\s+(.+)/, method: :set_username
  match_command /(.+)/
  match_empty :own_count

  def own_count(m)
    get_counts(m, [m.user.nick])
  end

  def set_username(m, param)
    name = param.strip.split.join("_")
    @@redis.set("nick:#{m.user.nick.downcase}:nanouser", name)
    m.reply "Your username has been set to #{name}."
    get_counts(m, [name])
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
      nth = ((Time.now - Chronic.parse('1st November')) / (60*60*24)).ceil
      goal = (50_000 / 30.0 * nth).round
      diff = goal - count

      "#{name}: #{count} (#{[
        "#{(count / 500).round(1)}%",
        if today then "today: #{today}" end,
        if diff == 0
          "up to date"
        elsif diff > 0
          "#{diff} behind"
        else
          "#{diff.abs} ahead"
        end
      ].join(', ')})"
    end

    if random && counts.compact.length == 0
      m.reply "No users in this channel have novels!"
      return
    end

    m.reply counts.compact.join(', ')
  end
end
