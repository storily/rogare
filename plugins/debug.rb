class Rogare::Plugins::Debug
  include Cinch::Plugin
  extend Rogare::Plugin

  command 'debug', hidden: true

  match_command /uptime/, method: :uptime
  match_command /my id/, method: :my_id
  match_command /my name/, method: :my_name
  match_command /my nano/, method: :my_nano
  match_command /chan name/, method: :chan_name
  match_command /chan find (.+)/, method: :chan_find
  match_command /war chans (.+)/, method: :war_chans
  match_command /war mems (.+)/, method: :war_mems

  def uptime(m)
    version = ENV['HEROKU_SLUG_DESCRIPTION'] || `git log -n1 --abbrev-commit --pretty=oneline` || 'around'
    m.reply "My name is sassbot, #{Socket.gethostname} is my home, running #{version}"
    m.reply "I made my debut at #{Rogare.boot}, #{(Time.now - Rogare.boot).round} seconds ago"
  end

  def my_id(m)
    m.reply m.user.id
  end

  def my_name(m)
    m.reply m.user.nick
  end

  def my_nano(m)
    uid = (m.user.discordian? ? m.user.id : nil) || m.user.nick
    m.reply "nano map key: #{uid}"

    redis = Rogare.redis(2)
    nano = redis.get("nick:#{uid}:nanouser")
    m.reply "nano map value: `#{nano.inspect}`"
  end

  def chan_name(m)
    m.reply m.channel.to_s
  end

  def chan_find(m, param)
    chan = Rogare.find_channel param.strip
    return m.reply 'No such chan' unless chan
    m.reply chan.name
  end

  def war_chans(m, param)
    redis = Rogare.redis(3)
    chans = redis.smembers "wordwar:#{param.strip}:channels"
    m.reply "`#{chans.inspect}`"

    chans.map! {|c| Rogare.find_channel c }
    m.reply "`#{chans.inspect}`"
  end

  def war_mems(m, param)
    redis = Rogare.redis(3)
    mems = redis.smembers "wordwar:#{param.strip}:members"
    m.reply "`#{mems.inspect}`"
  end
end
