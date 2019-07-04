# frozen_string_literal: true

require_relative '../cli'

projects = Project.where do
  (finish > now.function) &
    (participating =~ true)
end

projects.each do |p|
  pp p
end
