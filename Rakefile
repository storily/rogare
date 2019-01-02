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
    require 'logger'
    require 'sequel/core'

    version = args[:version].to_i if args[:version]

    Sequel::Database.extension :pg_comment
    Sequel.extension :migration
    Sequel.connect(ENV['DATABASE_URL'],
      loggers: [Logger.new($stdout)],
      search_path: [ENV['DB_SCHEMA'] || 'public']) do |db|
      Sequel::Migrator.run(db, 'migrations', target: version)
    end
    puts "\e[47m\e[1;35m==> Done running migrations. \e[0m"
  end

  desc 'Rollback to the penultimate migration and migrate to latest again'
  task redo: :dotenv do |_t|
    require 'logger'
    require 'sequel/core'

    version = Dir['migrations/*.rb']
              .map { |name| name.split('/').last.split('_').first }
              .sort
              .last(2)
              .first
              .to_i

    Sequel::Database.extension :pg_comment
    Sequel.extension :migration
    Sequel.connect(ENV['DATABASE_URL'],
      loggers: [Logger.new($stdout)],
      search_path: [ENV['DB_SCHEMA'] || 'public']) do |db|
      puts "\e[47m\e[1;35m==> Undoing to #{version}. \e[0m"
      Sequel::Migrator.run(db, 'migrations', target: version)
      puts "\e[47m\e[1;35m==> Migrating to latest. \e[0m"
      Sequel::Migrator.run(db, 'migrations')
    end
    puts "\e[47m\e[1;35m==> Done running migrations. \e[0m"
  end
end
