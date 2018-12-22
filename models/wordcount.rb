# frozen_string_literal: true

class Wordcount < Sequel::Model
  plugin :timestamps, create: :created, update: nil

  many_to_one :novel
end
