# frozen_string_literal: true

class Rogare::Plugins::QuickCheck
  extend Rogare::Plugin

  command Rogare.prefix
  usage '`!%` - Quick check of things'
  handle_help
  match_empty :execute

  def execute(m, _param)
    if defined? Rogare::Plugins::Wordcount
      wc = Rogare::Plugins::Wordcount.new
      novels = wc.get_counts([m.user.to_db]).first

      if novels.empty?
        m.reply 'You have no current novels!'
      else
        wc.display_novels m, novels
        m.reply 'You’re doing great!' if rand > 0.95
      end
    end

    if defined? Rogare::Plugins::Wordwar
      ww = Rogare::Plugins::Wordwar.new

      Rogare::Data.current_wars.each do |war|
        war[:end] = war[:start] + war[:seconds]
        ww.say_war_info m, war
      end
    end
  end
end
