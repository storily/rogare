require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || 'production').to_sym

module Caskbot
  class << self
    extend Memoist

    attr_accessor :bot

    def config
      c = Hashie::Mash.new
      ENV.each { |k,v| c[k.downcase] = v }
      return c
    end

    def mainchan
      Caskbot.bot.channel_list.find ENV['IRC_CHANNELS'].split.first
    end

    def root
      __dir__
    end

    def template(file)
      Tilt.new(root + '/templates/' + file + '.hbs')
    end

    memoize :config, :mainchan, :root, :template
  end

  module Plugins
    def self.to_a
      self.constants.map { |c| self.const_get c }
    end
  end
end

Dir['./plugins/*.rb'].each { |p| require p }
require './bot'
require './web'

Thread.new { Caskbot.bot.start }
run Caskbot::Web
