# frozen_string_literal: true

class War < Sequel::Model
  many_to_one :creator, class: :User
  many_to_one :canceller, class: :User
  many_to_many :members, join_table: :wars_members, right_key: :user_id, class: :User

  def self.all_existing
    where { (ended =~ false) & (cancelled =~ nil) }.order_by(:created)
  end

  def self.all_current
    all_existing.where do
      (start + concat(seconds, ' secs').cast(:interval) > now.function)
    end
  end

  def finish
    start + seconds.seconds
  end

  def til_start
    start - Time.now
  end

  def til_finish
    finish - Time.now
  end

  def current?
    !cancelled && finish > Time.now
  end

  def future?
    current? && start > Time.now
  end

  def others
    members.reject { |u| u == creator }
  end

  def discord_channels
    channels.map do |c|
      chan = Rogare.find_channel(c)
      next chan if chan && !chan.is_a?(Array)
    end.compact
  end

  def broadcast(msg)
    discord_channels.each { |chan| chan.send msg }
  end

  def start!
    self.started = true
    save
  end

  def finish!
    self.ended = true
    save
  end

  def cancel!(by_user)
    self.canceller = by_user
    self.cancelled = Time.now
    save
  end

  def add_member!(user)
    return if members.include? user

    add_member user
  end

  def add_channel(chan)
    self.channels = channels.push(chan).uniq
  end
end
