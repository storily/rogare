class Rogare::Plugins::Nano
  include Cinch::Plugin
  extend Rogare::Help
  extend Memoist

  command 'count'
  aliases 'wc'
  usage '!% [username(s) to search, or "set" then a username to remember your NaNoWriMo username]'
  handle_help

  @@redis = Rogare.redis(2)

  def get_count_by_name(name)
    res = Typhoeus.get "https://nanowrimo.org/wordcount_api/wc/#{name}"
    if res.code == 200
      doc = Nokogiri::XML(res.body)
      if doc.css('error').length == 0
        wc = doc.at_css('user_wordcount').content
        return wc.to_i
      end
    end
    nil
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
      next if random && random_found

      count = get_count_by_name(name)

      next if random && count.nil?
      next "#{name}: user does not exist or has no current novel" if count.nil?
      random_found = true

      "#{name}: #{count} (#{(count / 500).round}%)"
    end

    if random && counts.compact.length == 0
      m.reply "No users in this channel have novels!"
      return
    end

    m.reply counts.compact.join(', ')
  end
end
