# frozen_string_literal: true

class Rogare::Plugins::QuickCheck
  extend Rogare::Plugin

  command Rogare.prefix, hidden: true
  match_empty :execute

  def execute(m, _param)
    if defined? Rogare::Plugins::Wordcount
      wc = Rogare::Plugins::Wordcount.new
      data = wc.get_counts(m, [m.user.mid], return: true).first

      wc.present_one(m, data) if data
    end

    if defined? Rogare::Plugins::Wordwar
      ww = Rogare::Plugins::Wordwar.new

      Rogare::Data.current_wars.each do |war|
        war[:end] = war[:start] + war[:seconds]
        ww.say_war_info m, war
      end
    end

    m.reply 'You’re doing great!' if rand > 0.95
  end
end
