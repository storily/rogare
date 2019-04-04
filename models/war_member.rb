# frozen_string_literal: true

class WarMember < Sequel::Model(:wars_members)
  include Rogare::Utilities

  many_to_one :war, class: :War
  many_to_one :user, class: :User

  def save_total!(total, type)
    self.total = total
    self.total_type = type
    save
  end
end
