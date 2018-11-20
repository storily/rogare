# frozen_string_literal: true

class Rogare::Plugins::Say
  extend Rogare::Plugin

  command 'say'
  usage '`!% <channel> <message>` - Say something as the bot in an arbitrary channel'
  handle_help

  match_command /(\S+)\s+(.*)/
  match_empty :help_message

  def execute(m, channel, message)
    channel = Rogare.find_channel(channel.strip)
    if channel.nil?
      m.reply 'No such channel'
      return
    elsif channel.is_a? Array
      m.reply "Multiple channels match this:\n" + channel.map do |chan|
        "#{chan.server.name.tr(' ', '~')}/#{chan.name}"
      end.join("\n")
      return
    end

    # k = "nick:#{m.user.id}:sayquota"
    # quota = @@redis.get(k).to_i
    # @@redis.set(k, 0, ex: 60 * 60) if quota.zero?
    # @@redis.incr(k)
    #
    # max = 5
    #
    # if quota >= max
    #   m.reply 'Sorry! Quota exceeded for this hour.'
    #   return
    # end
    #
    # m.reply "You're approaching your quota of #{max} !say per hour!" if quota >= (max * 0.8).floor

    channel.send message
  end
end
