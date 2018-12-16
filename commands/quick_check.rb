# frozen_string_literal: true

class Rogare::Commands::QuickCheck
  extend Rogare::Command

  command Rogare.prefix
  usage '`!%` - Quick check of things'
  handle_help
  match_empty :execute

  def execute(m, _param)
    great = false

    if defined? Rogare::Commands::Wordcount
      wc = Rogare::Commands::Wordcount.new
      novels = wc.get_counts([m.user.to_db]).first

      if novels.empty?
        m.reply 'You have no current novels!'
      else
        wc.display_novels m, novels
        great = true
      end
    end

    if defined? Rogare::Commands::Wordwar
      ww = Rogare::Commands::Wordwar.new

      Rogare::Data.current_wars.each do |war|
        war[:end] = war[:start] + war[:seconds]
        ww.say_war_info m, war
      end
    end

    m.reply 'You’re doing great!' if great && rand > 0.95
  end
end
