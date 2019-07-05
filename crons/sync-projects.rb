#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../cli'

projects = Project.where do
  (finish > now.function) &
    (start - Sequel.cast('30 days', :interval) < now.function) &
    participating &
    (sync_goal | sync_words)
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

  puts 'saving.'
  p.save
end
