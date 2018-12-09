# frozen_string_literal: true

module GoalTerms
  module Id
    def value
      text_value
    end
  end

  module Number
    def value
      text_value.to_i
    end
  end

  module Words
    def value
      mult = k.empty? ? 1 : 1000
      number.value * mult
    end
  end

  module Days
    def value
      number.value
    end
  end

  module Repeat
    def value
      norepeat.empty?
    end
  end

  module Date
    def value
      text_value
    end
  end
end
