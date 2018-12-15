class User < Sequel::Model
  def self.from_discord(discu)
    self.where(discord_id: discu.id).first
  end

  def self.seen_on_discord(discu)
    nick = discu.nick || discu.username
    discordian = self.from_discord(discu)

    return self.new_from_discord(discu)[:last_seen] unless discordian
    return discordian[:last_seen] unless Time.now - discordian[:last_seen] > 60 || discordian[:nick] != nick

    discordian.last_seen = Sequel.function(:now)
    discordian.nick = nick
    discordian.save

    discordian.last_seen
  end

  def self.new_from_discord(discu, extra = {})
    defaults = {
      discord_id: discu.id,
      nick: discu.nick || discu.username,
      first_seen: Sequel.function(:now),
      last_seen: Sequel.function(:now)
    }

    self.create(defaults.merge(extra))
  end
end
