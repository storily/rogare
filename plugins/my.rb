# frozen_string_literal: true

class Rogare::Plugins::My
  extend Rogare::Plugin

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
    user = m.user.to_db

    m.reply [
      "**#{user[:nick]}**, first seen _#{user[:first_seen].strftime('%Y-%m-%d')}_",
      ("Nano user: `#{user[:nano_user]}`" if user[:nano_user]),
      "Timezone: **#{user[:tz]}**"
    ].compact.join("\n")
  end

  def set_nano(m, name)
    name = name.strip.split.join('-')

    res = Typhoeus.get "https://nanowrimo.org/participants/#{name}"
    unless res.code == 200
      m.reply "No such nano name (`#{name}`) found on the nano website"
      return
    end

    Rogare::Data.set_nano_user(m.user, name)
    m.reply "Your nano name has been set to #{name}."
  end

  def set_timezone(m, tz)
    tz.strip!

    begin
      TZInfo::Timezone.get(tz)
    rescue StandardError => e
      logs "Invalid timezone: #{e}"
      return m.reply 'That’s not a valid timezone.'
    end

    user = m.user.to_db
    Rogare::Data.users.where(id: user[:id]).update(tz: tz)
    m.reply "Your timezone has been set to #{tz}."
  end
end
