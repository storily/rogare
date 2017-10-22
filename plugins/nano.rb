class Rogare::Plugins::Nano
  include Cinch::Plugin
  extend Memoist

  match /(count|wc)(.*)/
  @@commands = ['count [username(s) to search, or "set" then a username to remember your NaNoWriMo username]']

  @@redis = Redis.new

  def get_count_by_name(name)
    res = Typhoeus.get "https://nanowrimo.org/wordcount_api/wc/#{name}"
    if res.code == 200
      doc = Nokogiri::XML(res.body)
      if doc.css('error').length == 0
        wc = doc.at_css('user_wordcount').content
        wc.to_i
      else
        nil
      end
    else
      nil
    end
  end

  def execute(m, param)
    candidates = []
    names = []

    setting = false
    random_user = false

    param ||= ''
    param.strip.split.each do |p|
      p = p.downcase.to_sym
      if p =~ /^(help|\?|how|what|--help|-h)$/
        return m.reply 'Usage: !' + @@commands.first
      elsif p =~ /^(set|-s|--set)$/
        setting = true
      elsif !setting && p =~ /^(me|self|myself|i)$/
        candidates.push m.user.nick
      elsif !setting && p =~ /^(random|rand|any)$/
        random_user = true
        m.channel.users.keys.shuffle.map do |n|
          candidates.push n.nick
        end
      else
        candidates.push p
      end
    end
    candidates.push m.user.nick if (!setting && candidates.empty?)

    if setting
      names = [candidates.join("_")]
      if names.first.length == 0
        m.reply "Please specify a NaNoWriMo username to set."
        return
      end

      m.reply "Your username has been set to #{names.first}."

      @@redis.set("nick:#{m.user.nick.downcase}:nanouser", names.first)
    else
      candidates.map do |c|
        names.push @@redis.get("nick:#{c.downcase}:nanouser") || c
      end
    end

    # `random_found` exists so that we don't check every single user in the
    # channel for a valid NaNoWriMo wordcount before choosing a random one
    # to display, instead we only request word counts up until the first one
    # that has a valid count.
    random_found = false
    counts = names.map do |name|
      next if random_user && random_found

      count = get_count_by_name(name)

      next if random_user && !count
      next "#{name}: user does not exist or has no current novel" unless count
      random_found = true

      "#{name}: #{count} (#{(count / 500).round}%)"
    end

    if random_user && counts.compact.length == 0
      m.reply "No users in this channel have novels!"
      return
    end

    m.reply counts.compact.join(', ')
  end
end
