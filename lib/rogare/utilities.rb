# frozen_string_literal: true

module Rogare::Utilities
  def first_of(month, tz)
    tz_string = tz.current_period.offset.abbreviation
    DateTime.parse("#{Time.new.year}-#{month}-01 00:00:00 #{tz_string}").to_time
  end

  def encode_entities(raws)
    raws.gsub(/(_|\*|\`)/, '\\1')
        .gsub('~~', '\~\~')
        .gsub(/\s+/, ' ')
  end

  def datef(date)
    date.strftime('%-d %b %Y')
  end

  def dur_display(time, now = Time.now)
    secs = (time - now).round
    neg = false
    if secs.negative?
      secs = secs.abs
      neg = true
    end

    hours = secs / 1.hour
    secs -= hours.hour.to_i
    minutes = secs / 1.minute
    secs -= minutes.minute.to_i

    [if hours >= 1
       "#{hours}h #{minutes}m"
     elsif minutes >= 5
       "#{minutes}m"
     elsif minutes >= 1
       "#{minutes}m #{secs}s"
     else
       "#{secs}s"
     end, neg]
  end
end
