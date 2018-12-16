# frozen_string_literal: true

class User < Sequel::Model
  one_to_many :novels

  def self.from_discord(discu)
    where(discord_id: discu.id).first
  end

  def self.seen_on_discord(discu)
    nick = discu.nick || discu.username
    discordian = from_discord(discu)

    return new_from_discord(discu)[:last_seen] unless discordian
    return discordian[:last_seen] unless Time.now - discordian[:last_seen] > 60 || discordian[:nick] != nick

    discordian.last_seen = Time.now
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

    create(defaults.merge(extra))
  end

  def current_novels
    novels_dataset
      .where do
        (started <= Sequel.function(:now)) &
          (finished =~ false)
      end
      .reverse(:started)
  end

  def load_novel(id)
    if id.nil? || id.empty?
      current_novels.first
    else
      novels_dataset.where(id: id).first
    end
  end
end
