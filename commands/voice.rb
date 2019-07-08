class Rogare::Commands::Voice
  extend Rogare::Command

  command 'voice', hidden: true
  aliases 'v'

  match_command /connect (.+)/, method: :voice_connect
  match_command /connect()/, method: :voice_connect
  match_command /on/, method: :voice_on
  match_command /off/, method: :voice_off
  match_command /bye/, method: :voice_bye
  match_command /play (.+)/, method: :voice_play

  def voice_connect(m, chan)
    chan = 'General' if chan.empty?
    Rogare.discord.voice_connect Rogare.find_channel(chan).inner
  end

  def voice_on(m)
    Rogare.discord.voice(m.channel.server).speaking = true
  end

  def voice_off(m)
    Rogare.discord.voice(m.channel.server).speaking = false
  end

  def voice_bye(m)
    Rogare.discord.voice(m.channel.server).destroy
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
end
