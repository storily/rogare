class Rogare::Plugins::Debug
  include Cinch::Plugin
  extend Rogare::Plugin

  command 'debug', hidden: true

  match_command /uptime/, method: :uptime
  match_command /my id/, method: :my_id
  match_command /my name/, method: :my_name
  match_command /my nano/, method: :my_nano
  match_command /chan name/, method: :chan_name
  match_command /chan pretty name/, method: :chan_pretty_name
  match_command /chan find (.+)/, method: :chan_find
  match_command /user ids/, method: :user_ids
  match_command /war chans (.+)/, method: :war_chans
  match_command /war mems (.+)/, method: :war_mems
  match_command /voice connect (.+)/, method: :voice_connect
  match_command /voice on/, method: :voice_on
  match_command /voice play (.+)/, method: :voice_play
  match_command /voice off/, method: :voice_off
  match_command /voice bye/, method: :voice_bye

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

    if chan.is_a? Array
      m.reply 'Several chans found!'
    else
      chan = [chan]
    end

    chan.each do |c|
      m.reply "#{c.server.name.downcase.gsub(' ', '~')}/#{c.name}"
    end
  end

  def user_ids(m)
    list = []
    Rogare.discord.users.each do |id, u|
      list << "#{Rogare.nixnotif u.username} ##{u.discriminator}: #{id}"
    end
    m.reply list.join("\n")
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

  def voice_connect(m, chan)
    Rogare.discord.voice_connect Rogare.find_channel(chan).inner
  end

  def voice_on(m)
    Rogare.discord.voice(m.channel.server).speaking = true
  end

  def voice_play(m, name)
    return if name.include? '/'

    file = Dir["./voice/#{name}.dca"].first
    file ||= Dir["./voice/#{name}.mp3"].first
    return m.reply 'No such file' unless file

    voice = Rogare.discord.voice(m.channel.server)
    voice.speaking = true

    begin
      m.reply 'Playing'
      logs 'What'
      if file.end_with? '.dca'
        logs 'Dca'
        voice.play_dca(file)
      else
        logs 'File'
        logs file.inspect
        voice.play_io(open(file))
      end
      logs 'What'
      m.reply 'Played'
    rescue StandardError => e
      logs e.message
      logs e.backtrace
      m.reply "Error playing #{name}"
    end

    voice.speaking = false
  end

  def voice_off(m)
    Rogare.discord.voice(m.channel.server).speaking = false
  end

  def voice_bye(m)
    Rogare.discord.voice(m.channel.server).destroy
  end
end
