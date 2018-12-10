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

  class Line
    def initialize(terms)
      terms.each do |term|
        @id_offset = term.to_i if term.is_a? GoalTerms::Letter
        @words = term.to_i if term.is_a? GoalTerms::Words
        @days = term.to_i if term.is_a? GoalTerms::Days
        @repeat = term.on if term.is_a? GoalTerms::Repeat
        @start = term if term.is_a? GoalTerms::Start
      end
    end

    attr_reader :letter, :words, :days, :repeat

    def start(tz = TZInfo::Timezone.get(Rogare.tz))
      @start.to_date(tz)
    end
  end

  class Letter
    def initialize(id)
      @id = id.upcase
    end

    def to_s
      @id
    end

    def to_i
      @id.split('').reverse.map.with_index do |letter, i|
        (letter.ord - 64) * ('10'.to_i(26)**i)
      end.sum
    end
  end

  class Words
    def initialize(words)
      @words = words
    end

    def to_i
      @words
    end
  end

  class Days
    def initialize(days)
      @days = days
    end

    def to_i
      @days
    end
  end

  class Repeat
    def initialize(yes)
      @repeat = yes
    end

    def on
      @repeat
    end
  end

  class Start
    def initialize(date)
      @date = date
    end

    def to_s
      @date
    end

    def to_date(tz)
      Chronic.time_class = tz
      dt = Chronic.parse(@date)
      dt&.to_date
    ensure
      Chronic.time_class = Time
    end
  end
end
