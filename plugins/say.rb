class Rogare::Plugins::Say
  include Cinch::Plugin
  extend Rogare::Plugin

  command 'say'
  usage '!% <channel> <message>'
  handle_help

  @@redis = Rogare.redis(4)

  match_command /(\S+)\s+(.*)/
  match_empty :help_message

  def execute(m, chan, message)
    channel = Rogare.find_channel(chan.strip)
    if channel.nil?
      m.reply "No such channel"
      return
    elsif channel.is_a? Array
      m.reply "Multiple channels match this:\n" + channel.map do |chan|
        "#{chan.server.name.gsub(' ', '~')}/#{chan.name}"
      end.join("\n")
      return
    end

    k = "nick:#{(m.user.discordian? ? m.user.id : m.user.nick)}:sayquota"
    quota = @@redis.get(k).to_i
    @@redis.set(k, 0, ex: 60*60) if quota == 0
    @@redis.incr(k)

    max = 5

    if quota >= max
      m.reply "Sorry! Quota exceeded for this hour."
      return
    end

    if quota >= (max*0.8).floor
      m.reply "You're approaching your quota of #{max} !say per hour!"
    end

    channel.send message
  end
end
