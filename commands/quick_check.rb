# frozen_string_literal: true

class Rogare::Commands::QuickCheck
  extend Rogare::Command

  command Rogare.prefix
  usage '`!%` - Quick check of things'
  handle_help
  match_empty :execute

  def execute(m, _param)
    if defined? Rogare::Commands::Project
      pro = Rogare::Commands::Project.new
      pro.show_current m, novels
    end

    if defined? Rogare::Commands::Wordwar
      ww = Rogare::Commands::Wordwar.new

      War.all_current.each do |war|
        war[:end] = war[:start] + war[:seconds]
        ww.say_war_info m, war
      end

      ww.ex_war_stats(m)
    end

    print ''
  end
end
