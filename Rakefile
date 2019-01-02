# frozen_string_literal: true

require 'dotenv/tasks'
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:lint)

task fix: 'lint:auto_correct'

task :console do
  require 'pry'
  require './cli'

  ARGV.clear
  Pry.start
end

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] => :dotenv do |_t, args|
    require 'sequel/core'

    version = args[:version].to_i if args[:version]

    Sequel.extension :migration
    Sequel.connect(ENV['DATABASE_URL']) do |db|
      Sequel::Migrator.run(db, 'migrations', target: version)
    end
  end

  desc 'Rollback to the penultimate migration and migrate to latest again'
  task redo: :dotenv do |_t|
    require 'sequel/core'

    version = Dir['migrations/*.rb']
              .map { |name| name.split('/').last.split('_').first }
              .sort
              .last(2)
              .first

    Sequel.extension :migration
    Sequel.connect(ENV['DATABASE_URL']) do |db|
      Sequel::Migrator.run(db, 'migrations', target: version)
      Sequel::Migrator.run(db, 'migrations')
    end
  end
end
