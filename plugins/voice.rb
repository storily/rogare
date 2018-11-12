# frozen_string_literal: true

class Rogare::Plugins::Voice
  extend Rogare::Plugin

  command 'voice', hidden: true
  aliases 'v'
  usage [
    'All commands are admin-restricted',
    '`!% connect <channel>` - Start the player and connect to the given voice channel',
    '`!% kill` - Kill the player',
    '`!% bye` - Quit gracefully',
    '`!% on` - Turn speaking on',
    '`!% off` - Turn speaking off',
    '`!% play <name>` - Play a named sound',
  ]
  handle_help

  match_command /connect()/, method: :voice_connect
  match_command /connect (.+)/, method: :voice_connect
  match_command /kill/, method: :voice_kill
  match_command /on/, method: :voice_on
  match_command /play (.+)/, method: :voice_play
  match_command /off/, method: :voice_off
  match_command /bye/, method: :voice_bye

  @@player = nil

  before_handler do |method, m|
    next if method == :help_message

    is_admin = m.user.inner.roles.find { |r| (r.permissions.bits & 3) == 3 }
    unless is_admin
      m.reply('Not authorised')
      next :stop
    end
  end

  def voice_connect(m, chan)
    return m.reply 'Already connected' if @@player
    chan = 'General' if chan == ''

    rchan = Rogare.find_channel(chan)
    return m.reply "No such channel: `#{chan}`" unless rchan

    pin, pout, perr, pthr = Open3.popen3('node', 'voice/player.js', err: :out)
    @@player = [pin, pout, perr, pthr]
    m.reply "Started player (#{pthr.pid})"

    return unless wait_for(m) { |line| line == "READY\n" }
    m.reply "Player started and well"

    pin.write "CONNECT #{rchan}\n"
    return unless wait_for(m) { |line| line == "CONNECTED\n" }
    m.reply "Player connected"
  end

  def wait(secs)
    pout = @@player[1]

    buf = ""
    secs.times do
      able = pout.read_nonblock 1, exception: false
      next sleep(1) if able.nil? || able == :wait_readable

      buf += able
      return buf
    end

    nil
  end

  def wait_for(m, secs = 5)
    buf = wait(secs)
    if buf.nil?
      m.reply 'Player failed to respond'
      voice_kill(m)
      return false
    end

    line = buf + @@player[1].gets
    unless yield line
      m.reply 'Player failed to respond well'
      voice_kill(m)
      return false
    end

    line
  end

  def voice_kill(m)
    return m.reply 'Already dead' unless @@player

    pin, pout, perr, pthr = @@player
    m.reply "Closing streams"
    pin.close
    pout.close
    perr.close

    return m.reply 'Looks like it’s already dead' unless check_pid pthr.pid

    begin
      m.reply "Sending TERM to #{pthr.pid}"
      Process.kill('TERM', pthr.pid)
      3.times do
        sleep 1
        return unless check_pid pthr.pid
      end
      m.reply "Sending KILL to #{pthr.pid}"
      Process.kill('KILL', pthr.pid)
    rescue
      m.reply 'Looks like it was already dead'
    ensure
      @@player = nil
    end
  end

  def check_pid(pid)
    begin
      Process.getpgid pid
      true
    rescue
      false
    end
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
