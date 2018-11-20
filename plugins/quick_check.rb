# frozen_string_literal: true

class Rogare::Plugins::QuickCheck
  extend Rogare::Plugin

  command Rogare.prefix, hidden: true
  match_empty :execute

  def execute(m, _param)
    if defined? Rogare::Plugins::Wordcount
      wc = Rogare::Plugins::Wordcount.new
      usual = wc.get_counts(m, [m.user.mid], return: true).first
      live = wc.get_counts(m, [m.user.mid], live: true, return: true).first

      if usual && live
        usual[:live] = live[:diff]

        if usual[:count] > 100_000 && rand > 0.8
          m.reply "Content Warning: #{%w[Astonishing Wondrous Beffudling Shocking Awely].sample} Wordcount"
          sleep 1
        end

        m.reply wc.format usual
      end
    end

    if defined? Rogare::Plugins::Wordwar
      ww = Rogare::Plugins::Wordwar.new

      ww.all_wars
        .reject { |w| w[:end] < Time.now }
        .sort_by { |w| w[:start] }
        .each do |war|
        ww.say_war_info m, war
      end
    end

    m.reply 'You’re doing great!' if rand > 0.95
  end
end
