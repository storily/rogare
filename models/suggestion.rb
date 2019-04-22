# frozen_string_literal: true

class Suggestion < Sequel::Model
  plugin :timestamps, create: :created, update: :updated, update_on_create: true
  include Rogare::Utilities

  many_to_one :author, class: :User, key: :user_id
end
