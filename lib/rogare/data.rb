# frozen_string_literal: true

module Rogare::Data
  class << self
    def first_of(month, tz)
      tz_string = tz.current_period.offset.abbreviation
      DateTime.parse("#{Time.new.year}-#{month}-01 00:00:00 #{tz_string}").to_time
    end

    def goal_format(goal)
      if goal < 1_000
        "#{goal} words goal"
      elsif goal < 10_000
        "#{(goal / 1_000.0).round(1)}k goal"
      else
        "#{(goal / 1_000.0).round}k goal"
      end
    end

    def encode_entities(raws)
      raws.gsub(/(_|\*|\`)/, '\\1')
          .gsub('~~', '\~\~')
          .gsub(/\s+/, ' ')
    end

    def datef(date)
      date.strftime('%-d %b %Y')
    end
  end
end
