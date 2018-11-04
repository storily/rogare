# frozen_string_literal: true

class Rogare::Plugins::Voice
  extend Rogare::Plugin

  command 'voice', hidden: true
  usage [
    'All commands are admin-restricted',
    '`!% connect <channel>` - Connect the bot to the given voice channel',
    '`!% on` - Turn speaking on for the current voice channel',
    '`!% off` - Turn speaking off for the current voice channel',
    '`!% bye` - Quit the current voice channel'
  ]
  handle_help

  match_command /connect (.+)/, method: :voice_connect
  match_command /on/, method: :voice_on
  match_command /play (.+)/, method: :voice_play
  match_command /off/, method: :voice_off
  match_command /bye/, method: :voice_bye

  before_handler do |method, m|
    next if method == :help_message

    is_admin = m.user.inner.roles.find { |r| (r.permissions.bits & 3) == 3 }
    unless is_admin
      m.reply('Not authorised')
      next :stop
    end
  end

  def voice_connect(_m, chan)
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
        voice.play_file(file)
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
