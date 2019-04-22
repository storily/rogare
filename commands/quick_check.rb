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
      novels = m.user.current_novels
                .map { |novel| wc.get_novel_count novel, m.user }
                .sort { |a, b| [b[:novel].last_update, b[:count]] <=> [a[:novel].last_update, a[:count]] }
                .first(5)

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

      war_counts = m.user
                    .war_memberships_dataset
                    .where { (ending - starting) >= 1 }
                    .join(:wars, id: :war_id)
                    .reverse(:created)
                    .limit(50)
                    .map { |w| w[:ending] - w[:starting] }

      if war_counts.length > 2
        avg = war_counts.sum / war_counts.length
        spark = Sparkr.sparkline(war_counts)
        m.reply "Last #{war_counts.length} wars: #{spark} (avg #{avg} words per war)"
      end
    end

    m.reply 'You’re doing great!' if great && rand > 0.95
  end
end
