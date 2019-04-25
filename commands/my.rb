# frozen_string_literal: true

class Rogare::Commands::My
  extend Rogare::Command

  command 'my'
  usage [
    '`!%` - Show yourself!',
    '`!% nano <nanoname>` - Register your nano username against your Discord user.',
    '`!% tz <timezone e.g. Pacific/Auckland>` - Set your timezone (for counts, goals, etc).'
  ]
  handle_help

  match_command /nano\s+(.+)/, method: :set_nano
  match_command /tz\s+(.+)/, method: :set_timezone
  match_empty :show

  def show(m)
    m.reply [
      "**#{m.user.nick}**, first seen _#{m.user.first_seen.strftime('%Y-%m-%d')}_",
      ("Nano user: `#{m.user.nano_user}`" if m.user.nano_user),
      "Timezone: **#{m.user.tz}**"
    ].compact.join("\n")

    Rogare::Commands::Wordwar.new.ex_war_stats(m) if defined? Rogare::Commands::Wordwar
  end

  def set_nano(m, name)
    name = name.strip.split.join('-')

    m.user.nano_user = name
    unless m.user.nano_user_valid?
      m.reply "No such nano name (`#{name}`) found on the nano website"
      return
    end

    m.user.save
    m.reply "Your nano name has been set to #{name}."
  end

  def set_timezone(m, tz)
    tz.strip!

    unless TimeZone.new(tz)
      logs "Invalid timezone: #{e}"
      return m.reply 'That’s not a valid timezone.'
    end

    m.user.tz = tz
    m.user.save
    m.reply "Your timezone has been set to #{tz}."
  end
end
