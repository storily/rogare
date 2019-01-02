# frozen_string_literal: true

class WarMember < Sequel::Model(:wars_members)
  include Rogare::Utilities

  many_to_one :war, class: :War
  many_to_one :user, class: :User
end
