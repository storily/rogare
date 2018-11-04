# frozen_string_literal: true

class Rogare::Plugins::Debug
  extend Rogare::Plugin

  command 'debug', hidden: true
  usage [
    'All commands except `!% uptime` and `!% my` are admin-restricted',
    '`!% uptime` - Show uptime, boot time, host, and version info',
    '`!% status <status>` - Set bot’s status',

    '`!% my id` - Show own discord id',
    '`!% my name` - Show own name as per API',
    '`!% my nano` - Show own nano user',

    '`!% chan name` - Show this channel’s internal name',
    '`!% chan find <name>` - Find a channel from name or internals',
    '`!% user ids` - Display all known users and their IDs',

    '`!% war chans <war id>` - Display channels the war is in',
    '`!% war mems <war id>` - Display raw members the war has',

    '`!% wc set user <discord user> <nano user>` - Set a user’s nano name for them',
    '`!% wc set goal <discord user> <nano goal>` - Set a user’s nano goal for them'
  ]
  handle_help

  match_command /uptime/, method: :uptime
  match_command /status (.+)/, method: :status

  match_command /my id/, method: :my_id
  match_command /my name/, method: :my_name
  match_command /my nano/, method: :my_nano

  match_command /chan name/, method: :chan_name
  match_command /chan find (.+)/, method: :chan_find
  match_command /user ids/, method: :user_ids

  match_command /war chans (.+)/, method: :war_chans
  match_command /war mems (.+)/, method: :war_mems

  match_command /wc set user (.+) (.+)/, method: :wc_set_user
  match_command /wc set goal (.+) (.+)/, method: :wc_set_goal

  before_handler do |method, m|
    next if %i[uptime help_message my_id my_name my_nano].include? method

    is_admin = m.user.inner.roles.find { |r| (r.permissions.bits & 3) == 3 }
    unless is_admin
      m.reply('Not authorised')
      next :stop
    end
  end

  def uptime(m)
    version = ENV['HEROKU_SLUG_DESCRIPTION'] || `git log -n1 --abbrev-commit --pretty=oneline` || 'around'
    m.reply "My name is sassbot, #{Socket.gethostname} is my home, running #{version}"
    m.reply "I made my debut at #{Rogare.boot}, #{(Time.now - Rogare.boot).round} seconds ago"
  end

  def status(m, param)
    Rogare.discord.update_status(param, Rogare.game, nil)
    m.reply "Status set to `#{param}`"
  end

  def my_id(m)
    m.reply m.user.id
  end

  def my_name(m)
    m.reply m.user.nick
  end

  def my_nano(m)
    m.reply "nano map key: #{m.user.id}"

    redis = Rogare.redis(2)
    nano = redis.get("nick:#{m.user.id}:nanouser")
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
      m.reply "#{c.server.name.downcase.tr(' ', '~')}/#{c.name}"
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

    chans.map! { |c| Rogare.find_channel c }
    m.reply "`#{chans.inspect}`"
  end

  def war_mems(m, param)
    redis = Rogare.redis(3)
    mems = redis.smembers "wordwar:#{param.strip}:members"
    m.reply "`#{mems.inspect}`"
  end

  def wc_set_user(m, user, nano)
    redis = Rogare.redis(2)

    du = Rogare.from_discord_mid user
    du ||= Rogare.discord.users.find { |_i, u| u.name == user }[1]
    return m.reply('No such user') unless du

    redis.set("nick:#{du.id}:nanouser", nano)
    m.reply "User `#{du.id}` nanouser set to `#{nano}`"
  end

  def wc_set_goal(m, user, goal)
    redis = Rogare.redis(2)
    goal.sub! /k$/, '000'

    du = Rogare.from_discord_mid user
    du ||= Rogare.discord.users.find { |_i, u| u.name == user }[1]
    return m.reply('No such user') unless du

    nano = redis.get("nick:#{du.id}:nanouser")
    redis.set("nano:#{nano}:goal", goal.to_i)
    m.reply "User `#{du.id}` nanouser `#{nano}` goal set to `#{goal}`"
  end
end
