# frozen_string_literal: true

class Wordcount < Sequel::Model
  many_to_one :novel
end
