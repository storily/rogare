# frozen_string_literal: true

class Project < Sequel::Model
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
end
