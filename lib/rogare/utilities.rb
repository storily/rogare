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
    diff = time - now
    minutes = diff / 60.0
    secs = (minutes - minutes.to_i).abs * 60.0

    neg = false
    if minutes.negative?
      minutes = minutes.abs
      neg = true
    end

    [if minutes >= 5
       "#{minutes.round}m"
     elsif minutes >= 1
       "#{minutes.floor}m #{secs.round}s"
     else
       "#{secs.round}s"
     end, neg]
  end
end
