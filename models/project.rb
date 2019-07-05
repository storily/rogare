# frozen_string_literal: true

class Project < Sequel::Model
  include ActionView::Helpers::DateHelper

  plugin :timestamps, create: :created, update: :updated, update_on_create: true

  many_to_one :user

  def time_to_finish
    if start < user.now
      nil
    elsif user.now > finish
      nil
    else
      (finish - user.now).days
    end
  end

  def days_to_finish
    time_to_finish&.round&.days
  end

  def finished?
    user.now >= finish.end_of_day
  end

  def words_updated
    time_words_since(sync_words && words_synced)
  end

  def goal_updated
    time_words_since(sync_words && words_synced)
  end

  def can_sync_words?
    case type
    when 'camp'
      true
    when 'nano'
      true
    else
      false
    end
  end

  def can_sync_goal?
    case type
    when 'camp'
      true
    else
      false
    end
  end

  def fetch_goal
    case type
    when 'camp'
      fetch_camp_goal
    when 'nano'
      50_000
    end
  end

  def fetch_words
    case type
    when 'camp'
      fetch_camp_words
    when 'nano'
      fetch_nano_words
    end
  end

  # private

  def time_words_since(time)
    return 'never' unless time

    seconds = Time.now - time.to_time
    if seconds > 60
      time_ago_in_words(time) + ' ago'
    elsif seconds < 3
      'just now'
    else
      "#{seconds.round}s ago"
    end
  end

  def fetch_camp
    unless remote_id
      camp = user.fetch_camps.find { |c| c[:date] == start.strftime('%B %Y') }
      return unless camp

      remote_id ||= camp[:slug]
    end
    return unless remote_id

    html = Typhoeus.get("https://campnanowrimo.org/campers/#{user.nano_user}/projects/#{remote_id}/stats").body
    Nokogiri::HTML.parse html
  end

  def fetch_camp_goal
    dom = fetch_camp
    return unless dom

    jsdata = dom.css('script:not([src])').map { |s| s.text.lines }.flatten(1).grep(/parData\s*=/).first
    jsdata.split(/[\[\]]/)[1].split(',').map(&:to_i).last
  end

  def fetch_camp_words
    dom = fetch_camp
    return unless dom

    jsdata = dom.css('script:not([src])').map { |s| s.text.lines }.flatten(1).grep(/rawCamperData\s*=/).first
    jsdata.split(/[\[\]]/)[1].split(',').map(&:to_i)
  end

  def fetch_nano_words; end
end
