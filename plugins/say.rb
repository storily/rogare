class Rogare::Plugins::Say
  include Cinch::Plugin
  extend Rogare::Help

  command 'say'
  usage '!% <channel> <message>'
  handle_help

  @@redis = Rogare.redis(4)

  match_command /(#+\w+)\s+(.*)/
  match_empty :help_message

  def execute(m, chan, message)
    channel = Rogare.bot.channel_list.find(chan.downcase.strip)
    if channel.nil?
      m.reply "No such channel"
      return
    end

    k = "nick:#{m.user.nick}:sayquota"
    quota = @@redis.get(k).to_i
    @@redis.set(k, 0, ex: 60*60) if quota == 0
    @@redis.incr(k)

    if quota >= 10
      m.reply "Sorry! Quota exceeded for this hour."
      return
    end

    if quota >= 8
      m.reply "You're approaching your quota of 10 !say per hour!"
    end

    channel.send message
  end
end
