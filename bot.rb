require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || 'production').to_sym

require_relative 'lib/rogare.rb'
Dir['./plugins/*.rb'].each { |p| require p }
Rogare.bot.start
