#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../cli'

this_year = Time.now.year

known = [
  {
    type: 'nano',
    name: "NaNo #{this_year}",
    start: Date.parse("#{this_year}-11-01"),
    finish: Date.parse("#{this_year}-11-30"),
    goal: 50_000,
    sync_goal: false
  },
  {
    type: 'camp',
    name: "April Camp #{this_year}",
    start: Date.parse("#{this_year}-04-01"),
    finish: Date.parse("#{this_year}-04-30"),
    sync_goal: true
  },
  {
    type: 'camp',
    name: "July Camp #{this_year}",
    start: Date.parse("#{this_year}-07-01"),
    finish: Date.parse("#{this_year}-07-31"),
    sync_goal: true
  }
]

User.eager(projects: proc { |ds| ds.where { start >= Sequel.cast("#{this_year}-01-01", :date) } }).each do |user|
  known.each do |kp|
    # skip if a project with the same type and bounds exists
    next if user.projects.find { |p| p.type == kp[:type] && p.start == kp[:start] && p.finish == kp[:finish] }

    user.add_project kp
  end
end
