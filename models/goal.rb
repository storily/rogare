# frozen_string_literal: true

class Goal < Sequel::Model
  many_to_one :novel
end
