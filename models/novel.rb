# frozen_string_literal: true

class Novel < Sequel::Model
  many_to_one :user

  one_to_many :goals
  one_to_many :wordcounts
end
