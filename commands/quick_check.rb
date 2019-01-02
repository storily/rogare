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
      user = m.user.to_db
      novels = user.current_novels
                   .map { |novel| wc.get_novel_count novel, user }
                   .sort { |a, b| [a[:count], a[:novel].last_update] <=> [b[:count], b[:novel].last_update] }
                   .first(3)

      if novels.empty?
        m.reply 'You have no current novels!'
      else
        wc.display_novels m, novels
        great = true
      end
    end

    if defined? Rogare::Commands::Wordwar
      ww = Rogare::Commands::Wordwar.new

      War.all_current.each do |war|
        war[:end] = war[:start] + war[:seconds]
        ww.say_war_info m, war
      end
    end

    m.reply 'You’re doing great!' if great && rand > 0.95
  end
end
