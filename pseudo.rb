# frozen_string_literal: true

require './cli'

logs '=====> Patching the system'

module Pseudo
  class << self
    @bot = nil
    attr_accessor :bot
  end
end

require './pseudo/bot'
require './pseudo/shim'
require './pseudo/terminal'
require './pseudo/core'

Rogare.spinoff(:pseudo) do
  sleep 2
  logs '=====> We’re in'
  Pseudo::Terminal.new.player!
end

logs '=====> Crossing fingers'

require './app'
