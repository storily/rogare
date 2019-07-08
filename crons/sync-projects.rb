#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../cli'

projects = Project.where do
  (sync_goal | sync_words | sync_name) & ((
  (finish > now.function) &
    (start - Sequel.cast('30 days', :interval) < now.function) &
    participating) | (
    (finish < now.function) & (
      (goal_synced + Sequel.cast('7 days', :interval) < now.function) |
      (words_synced + Sequel.cast('7 days', :interval) < now.function) |
      (name_synced + Sequel.cast('7 days', :interval) < now.function) |
      !goal_synced |
      !words_synced |
      !name_synced
    )
  ))
end.eager(:user)

projects.each do |p|
  print "Checking project #{p.id}... "
  if p.sync_goal
    print 'fetching goal: '
    goal = p.fetch_goal
    if goal
      p.goal = goal
      p.goal_synced = p.user.now
      print "#{goal}... "
    end
  end

  if p.sync_words
    print 'fetching words: '
    words = p.fetch_words&.last
    if words
      p.words = words
      p.words_synced = p.user.now
      print "#{words}... "
    end
  end

  if p.sync_name
    print 'fetching name: '
    name = p.fetch_name
    if name
      p.name = name
      p.name_synced = p.user.now
      print "“#{name}”... "
    end
  end

  puts 'saving.'
  p.save
rescue StandardError => e
  puts "Error syncing: #{e}"
end
