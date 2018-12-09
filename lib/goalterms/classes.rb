# frozen_string_literal: true

module GoalTerms
  class << self
    def flascend(elements)
      return if elements.nil?
      elements.flat_map do |el|
        next el.value if el.respond_to? :value
        next flascend el.elements if el.respond_to? :elements
        el
      end.compact
    end
  end

  class Letter
    def initialize(id)
      @id = id.upcase
    end
  end

  class Words
    def initialize(words)
      @words = words
    end
  end

  class Days
    def initialize(days)
      @days = days
    end
  end

  class Repeat
    def initialize(yes)
      @repeat = yes
    end
  end

  class Start
    def initialize(date)
      @date = date
    end
  end
end
