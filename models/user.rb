# frozen_string_literal: true

class User < Sequel::Model
  plugin :timestamps, create: :first_seen, update: :updated, update_on_create: true, allow_manual_update: true

  one_to_many :novels
  one_to_many :war_memberships, class: :WarMember, key: :user_id
  many_to_many :wars, join_table: :wars_members, class: :War

  @discord = nil
  attr_accessor :discord

  def self.from_discord(discu)
    u = where(discord_id: discu.id).first
    u.discord = discu
    u
  end

  def self.create_from_discord(discu)
    u = from_discord discu
    return u if u

    u = create(discord_id: discu.id)
    u.discord = discu
    u
  end

  def seen!
    return self unless Time.now - last_seen > 60 || nick != discord_nick

    # keep same updated stamp unless we actually update something
    self.updated = updated unless nick != discord_nick
    self.last_seen = Time.now
    self.nick = nick
    save

    self
  end

  def discord_nick
    (@discord.nick if @discord.is_a? Discordrb::Member) ||
      @discord.username ||
      '?'
  end

  def send(message)
    @discord.pm message
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
