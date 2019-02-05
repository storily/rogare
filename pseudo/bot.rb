# frozen_string_literal: true

class Pseudo::Bot
  def initialize
    raise 'WTF' if Pseudo.bot

    Pseudo.bot = self

    @on_message = {}
    @on = {}
  end

  def run; end

  def hook(name, &block)
    (@on[name] ||= []) << block
  end

  def call_hook(name, *args)
    @on[name]&.each { |block| block.call(*args) }
  end

  def ready(&block)
    @on_ready = block
  end

  def message(opts = {}, &block)
    pattern = opts[:contains] || //
    @on_message[pattern] = block
  end

  def remove_handler(pattern)
    @on_message.delete(pattern)
  end

  def update_status(status, game, _etc)
    @status = status
    @game = game

    call_hook(:status, status)
    call_hook(:game, game)
  end

  def users
    []
  end

  def send_ready
    @on_ready&.call
  end

  def send_message(_msg, _author = nil, _channel = nil)
    @on_message.call(event)
  end
end
