# frozen_string_literal: true

class Rogare::Commands::Debug
  extend Rogare::Command

  command 'debug'
  aliases 'show'
  usage [
    'All commands are restricted to #boating, and some are admin-restricted.',
    '**Public commands:**',
    '`!% uptime` - Show uptime, boot time, host, and version info',

    '`!% my id` - Show own discord id',
    '`!% my name` - Show own name as per API',
    '`!% my user` - Show own db user',

    '`!% user info <@user or ID or nick>` - Show user’s db info',
    '`!% name info <name>` - Show !name name db info (quite verbose)',
    '`!% name stats` - Show !name kind list and stats',
    '`!% kind map` - Show !name kind map',
    '`!% name adjust <name> <+/-kind>` - File an adjustment for a name to be (+) or not be (-) a particular kind.',

    "\n**Admin commands:**",
    '`!% game` - Cycle the bot’s playing now status',
    '`!% take a nap` - Voluntarily exit',

    '`!% name regen` - Regenerate the !name index.',

    '`!% chan name` - Show this channel’s internal name',
    '`!% chan find <name>` - Find a channel from name or internals',
    '`!% user ids` - Display all known users and their IDs',

    '`!% wc set user <discord user> <nano user>` - Set a user’s nano name for them'
  ]
  handle_help

  match_command /uptime/, method: :uptime
  match_command /game/, method: :cycle_game
  match_command /take a nap/, method: :take_a_nap

  match_command /my id/, method: :my_id
  match_command /my name/, method: :my_name
  match_command /my user/, method: :my_user

  match_command /user info (.+)/, method: :user_info
  match_command /name info ([[:alnum:]]+)/, method: :name_info
  match_command /name stats/, method: :name_stats
  match_command /kind map/, method: :kind_map
  match_command /name adjust ([[:alnum:]]+) ([+\-]\w+)/, method: :name_adjust
  match_command /name regen/, method: :name_regen

  match_command /chan name/, method: :chan_name
  match_command /chan find (.+)/, method: :chan_find
  match_command /user ids/, method: :user_ids

  match_command /wc set user (.+) (.+)/, method: :wc_set_user

  before_handler do |method, m|
    unless m.channel.name == 'boating'
      m.reply('Debug in #boating only please')
      next :stop
    end

    next if %i[
      uptime help_message
      my_id my_name my_user
      user_info name_info name_adjust
      kind_info kind_map
    ].include? method

    is_admin = m.user.discord.roles.find { |r| (r.permissions.bits & 3) == 3 }
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

  def cycle_game(_m)
    Rogare.discord.update_status('online', Rogare.game, nil)
  end

  def take_a_nap(m)
    m.reply ['It’s been a privilege', 'See you soon', 'I’ll see you on the other side'].sample
    sleep 1

    logs 'Sending TERM to self'
    Process.kill('TERM', Process.pid)

    sleep 5
    logs 'exeunt.'
    Process.exit
  end

  def my_id(m)
    m.reply m.user.discord.id
  end

  def my_name(m)
    m.reply m.user.discord_nick
  end

  def my_user(m)
    m.reply "`#{m.user.to_h.inspect}`"
  end

  def user_info(m, mid)
    discu = Rogare.from_discord_mid mid
    discu ||= User.where(nick: mid).first
    return m.reply "No such user: `#{mid}`" unless discu

    user = User.from_discord discu
    return m.reply "Not in db: `discord::#{discu.id}`" unless user

    m.debugly user
  end

  def name_info(m, name)
    m.debugly(
      *Name.where(name: name.downcase).all,
      '------------------------------------------------',
      *DB[:names].where(name: name.downcase).select(:name, :kinds, :source, :surname).distinct.all
    )
  end

  def name_stats(m)
    stats = Name.stats

    nt = stats[:total]
    ng = stats[:firsts]
    ns = stats[:lasts]

    nm = stats[:kinds].delete :male
    nf = stats[:kinds].delete :female
    ne = stats[:kinds].delete :enby

    m.reply "**#{nt}** unique given names " \
      "(**#{ng}** total, with **#{nm}** male, **#{nf}** female, and **#{ne}** explicitely enby) " \
      "and surnames (**#{ns}** total)." \
      "\nKinds: " +
            stats[:kinds].map { |k, v| "**#{v}** #{k}" }.join(', ') + '.'
  end

  def kind_map(m)
    m.reply 'https://nominare.cogitare.nz/kinds.png'
  end

  def name_adjust(m, name, adjustment)
    adjustment.sub!(/^\+/, '')

    origs = Name.where(name: name.downcase).all
    return m.reply "No such name in db: `#{name}`" if origs.empty?

    surname = origs.any? { |n| n[:surname] }

    info = {
      name: name,
      kinds: Name.to_kinds([adjustment]),
      source: m.user.nick
    }

    DB[:names].insert(info)
    DB[:names].insert(info.merge(surname: true)) if surname

    m.reply "Adjustment to `#{name}` added. Ask an admin to regenerate indexes. " \
            '(Admins, do that with: `!debug name regen`.)'
  end

  def name_regen(m)
    m.reply 'Refreshing name scores'
    DB['REFRESH MATERIALIZED VIEW names_scored_raw;'].all
    m.reply 'Refreshing name index'
    DB['REFRESH MATERIALIZED VIEW names_scored;'].all
    m.reply 'Refreshing done'
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

  def wc_set_user(m, user, nano)
    du = Rogare.from_discord_mid user
    du ||= User.from_discord(Rogare.discord.users.find { |_i, u| u.name == user }[1])
    return m.reply('No such user') unless du

    du.nano_user = nano
    du.save

    m.reply "User `#{du.discord.id}` nanouser set to `#{nano}`"
  end
end
