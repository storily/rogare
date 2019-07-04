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
    time_to_finish&.round.days
  end

  def finished?
    user.now >= finish.end_of_day
  end

  def words_updated
    return 'never' unless sync_words && words_synced
    time_ago_in_words(words_synced) + ' ago'
  end

  def goal_updated
    return 'never' unless sync_goal && goal_synced
    time_ago_in_words(goal_synced) + ' ago'
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
end
