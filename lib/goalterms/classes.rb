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

    def letter_to_i(id)
      id.split('').reverse.map.with_index do |letter, i|
        (letter.ord - 64) * ('10'.to_i(26)**i)
      end.sum
    end

    def offset_to_s(offset)
      (offset + 1)
        .to_s(26)
        .upcase
        .split('')
        .map { |l| (l.ord + (l.ord < 65 ? 16 : 9)).chr }
        .join
    end
  end

  class Line
    def initialize(terms)
      terms.each do |term|
        @offset = (term.to_i - 1) if term.is_a? GoalTerms::Letter
        @letter = term.to_s if term.is_a? GoalTerms::Letter
        @words = term.to_i if term.is_a? GoalTerms::Words
        @days = term.to_i if term.is_a? GoalTerms::Days
        @repeat = term.on if term.is_a? GoalTerms::Repeat
        @start = term if term.is_a? GoalTerms::Start
        @curve = term if term.is_a? GoalTerms::Curve
      end
    end

    attr_reader :offset, :letter, :words, :days, :repeat, :curve

    def default_start!
      @start ||= GoalTerms::Start.new 'today'
      nil
    end

    def start(tz = TimeZone.new(Rogare.tz))
      return unless @start

      @start.to_date(tz)
    end

    def finish(tz = nil)
      return unless start && days

      start(tz) + days.days
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
      GoalTerms.letter_to_i @id
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

  class Curve
    def initialize(curve)
      @curve = curve
    end

    def to_s
      @curve.downcase
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
      dt&.to_date&.to_datetime
    ensure
      Chronic.time_class = Time
    end
  end
end
