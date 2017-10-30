class Rogare::Plugins::Wordwar
  include Cinch::Plugin

  match /(wordwar|war|ww)\s*(.*)/
  @@usage = [
      'Use: !wordwar in [time before it starts (in minutes)] for [duration]',
      'Or:  !wordwar at [wall time e.g. 12:35] for [duration]',
      'Or even (defaulting to a 20 minute run): !wordwar at/in [time]',
      'And then everyone should: !wordwar join [username / wordwar ID]',
      'Also say !wordwar alone to get a list of current/scheduled ones.'
  ]

  def execute(m, cat, param)
    param = param.strip
    if param =~ /^(help|\?|how|what|--help|-h)/
      @@usage.each {|l| m.reply l}
      return
    end

    if param.empty?
      m.reply 'No wordwars'
      return
    end

    time, durstr = param.split('for').map {|p| p.strip}

    time = time.sub(/^at/).strip if time.start_with? 'at'
    durstr = "20 minutes" if durstr.nil? || durstr.empty?

    timeat = Chronic.parse(time)
    timeat = Chronic.parse("in #{time}") if timeat.nil?
    if timeat.nil?
      m.reply "Can't parse time: #{time}"
      return
    end

    duration = ChronicDuration.parse("#{durstr} minutes")
    if duration.nil?
      m.reply "Can't parse duration: #{durstr}"
      return
    end

    m.reply "Time: #{timeat}, Duration: #{duration}"
  end
end
