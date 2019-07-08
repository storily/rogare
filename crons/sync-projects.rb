#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../cli'

projects = Project.where do
  (sync_goal | sync_words | sync_name | sync_unit) & ((
  (finish > now.function) &
    (start - Sequel.cast('30 days', :interval) < now.function) &
    participating) | (
    (finish < now.function) & (
      (goal_synced + Sequel.cast('7 days', :interval) < now.function) |
      (words_synced + Sequel.cast('7 days', :interval) < now.function) |
      (name_synced + Sequel.cast('7 days', :interval) < now.function) |
      (unit_synced + Sequel.cast('7 days', :interval) < now.function) |
      is_null(goal_synced) |
      is_null(words_synced) |
      is_null(name_synced) |
      is_null(unit_synced)
    )
  ))
end.eager(:user)

projects.each do |p|
  print "Checking project #{p.id}... "

  if p.can_sync_goal? && p.sync_goal
    print 'fetching goal: '
    goal = p.fetch_goal
    if goal
      p.goal = goal
      p.goal_synced = p.user.now
      print "#{goal}... "
    end
  end

  if p.can_sync_words? && p.sync_words
    print 'fetching words: '
    words = p.fetch_words&.last
    if words
      p.words = words
      p.words_synced = p.user.now
      print "#{words}... "
    end
  end

  if p.can_sync_name? && p.sync_name
    print 'fetching name: '
    name = p.fetch_name
    if name
      p.name = name
      p.name_synced = p.user.now
      print "“#{name}”... "
    end
  end

  if p.can_sync_unit? && p.sync_unit
    print 'fetching unit: '
    unit = p.fetch_unit
    if unit
      p.unit = unit
      p.unit_synced = p.user.now
      print "‘#{unit}’... "
    end
  end

  puts 'saving.'
  p.save
rescue StandardError => e
  puts "Error syncing: #{e}"
end
