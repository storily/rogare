# frozen_string_literal: true

class User < Sequel::Model
  plugin :timestamps, create: :first_seen, update: :updated, update_on_create: true, allow_manual_update: true

  one_to_many :novels
  many_to_many :wars, join_table: :wars_members, class: :War

  def self.from_discord(discu)
    where(discord_id: discu.id).first
  end

  def self.seen_on_discord(discu)
    nick = discu.nick || discu.username
    discordian = from_discord(discu)

    return new_from_discord(discu)[:last_seen] unless discordian
    return discordian[:last_seen] unless Time.now - discordian[:last_seen] > 60 || discordian[:nick] != nick

    # keep same updated stamp unless we actually update something
    discordian.updated = discordian.updated unless nick != discordian.nick
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

  def mid
    "<@#{discord_id}>"
  end

  def nixnotif
    Rogare.nixnotif nick
  end

  def timezone
    TimeZone.new tz
  end

  def date_in_tz(date)
    timezone.local date.year, date.month, date.day
  end

  def now
    timezone.now
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

  def nano_user_valid?
    Typhoeus.get("https://nanowrimo.org/participants/#{nano_user}").code == 200
  end

  def nano_today
    return unless nano_user

    res = Typhoeus.get "https://nanowrimo.org/participants/#{nano_user}/stats"
    return unless res.code == 200

    doc = Nokogiri::HTML res.body
    doc.at_css('#novel_stats .stat:nth-child(2) .value').content.gsub(/[,\s]/, '').to_i
  end

  def nano_count
    return unless nano_user

    res = Typhoeus.get "https://nanowrimo.org/wordcount_api/wc/#{nano_user}"
    return unless res.code == 200

    doc = Nokogiri::XML(res.body)
    return unless doc.css('error').empty?

    doc.at_css('user_wordcount').content.to_i
  end
end
