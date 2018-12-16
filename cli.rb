# frozen_string_literal: true

require './lib/logs'

logs '=====> Bootstrapping'
require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || 'production').to_sym

logs '=====> Loading framework'
require './lib/rogare'

logs '=====> Preparing resources'
DB = Rogare.sql
Rogare::Data.goal_parser_impl

logs '=====> Loading models'
Dir['./models/*.rb'].each do |p|
  require p
end
