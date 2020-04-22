# frozen_string_literal: true

class Game < Sequel::Model
  def self.random_text
    enabled = where(enabled: true).all
    return nil if enabled.empty?

    enabled.sample.text
  end

  def display
    user_obj = User[creator_id]
    user = user_obj&.nick ? user_obj.nixnotif : 'somebody'
    indicator = enabled ? 'on' : 'off'

    "[`#{id}` - #{indicator}]: `#{text}` (added by #{user})"
  end
end
