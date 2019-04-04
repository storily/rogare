# frozen_string_literal: true

class WarMember < Sequel::Model(:wars_members)
  include Rogare::Utilities

  many_to_one :war, class: :War
  many_to_one :user, class: :User

  def total
    ending - starting
  end

  def save_starting!(n)
    self.starting = n
    save
  end

  def save_ending!(n)
    self.ending = n
    save
  end

  def save_total!(total, type)
    self.ending = starting + total
    self.total_type = type
    save
  end
end
