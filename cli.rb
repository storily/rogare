# frozen_string_literal: true

require './lib/logs'

logs '=====> Bootstrapping'
require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || 'production').to_sym

logs '=====> Loading framework'
require './lib/rogare'

logs '=====> Loading goal parser'
require './lib/goalterms/classes'
if ENV['RACK_ENV'] == 'production'
  require './lib/goalterms/grammar.rb'
else
  Treetop.load 'lib/goalterms/grammar.treetop'
end

logs '=====> Loading sequel'
DB = Rogare.sql
Sequel::Model.plugin :eager_each
Sequel::Model.plugin :pg_auto_constraint_validations
Sequel::Model.plugin :prepared_statements
Sequel::Model.plugin :prepared_statements_safe

logs '=====> Loading models'
Dir['./models/*.rb'].each do |p|
  logs "     > #{Pathname.new(p).basename('.rb').to_s.camelize}"
  require p
end

logs '=====> Preparing statements'
require './lib/preparation'
Dir['./preparations/*.rb'].each do |p|
  require p
end
Preparation.bake
