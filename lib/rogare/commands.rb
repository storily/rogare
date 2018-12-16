# frozen_string_literal: true

module Rogare::Commands
  def self.to_a
    constants.map { |c| const_get c }
  end
end
