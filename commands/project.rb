# frozen_string_literal: true

class Rogare::Commands::Project
  extend Rogare::Command

  command 'p'
  aliases 'project', 'projects'
  usage [
    '`!%` - Show all current and potential projects',
    '`!% <id> participate` - Activate said project',
    '`!% <id> name <name...>` - Manually rename the project',
    '`!% <id> name sync` - Automatically sync the project’s name where possible',
    '`!% <id> goal <N>` - Manually set the project’s goal',
    '`!% <id> goal sync` - Automatically sync the project’s goal where possible',
    '`!% <id> total <N>` - Manually set the project’s total so far',
    '`!% <id> total sync` - Automatically sync the project’s total where possible'
  ]
  handle_help

  match_command /(\d+)\s+(?:activate|participate|go)$/, method: :participate
  match_command /(\d+)\s+(?:re)?name\s+(.+)/, method: :set_name
  match_command /(\d+)\s+(?:re)?name\s*$/, method: :get_name
  match_command /(\d+)\s+goal\s+(sync|\d+)/, method: :set_goal
  match_command /(\d+)\s+goal\s*$/, method: :get_goal
  match_command /(\d+)\s+(?:wc|word(?:s|count)|total)\s+(sync|\d+)/, method: :set_words
  match_command /(\d+)\s+(?:wc|word(?:s|count)|total)\s*$/, method: :get_words
  match_command /(\d+)/, method: :show
  match_command /all/, method: :show_all
  match_empty :show_current

  def show_all(m)
    projects = m.user.projects.map do |p|
      format p
    end.join("\n")

    if projects.empty?
      m.reply 'No projects'
    else
      m.reply projects
    end
  end

  def show_current(m)
    projects = m.user.all_current_projects.map do |p|
      format p
    end.join("\n")

    if projects.empty?
      m.reply 'No projects'
    else
      m.reply projects
    end
  end

  def show(m, id)
    p = Project.where(id: id.to_i).first
    return m.reply 'No such project' unless p

    m.reply format p
  end

  def participate(m, id)
    p = m.user.projects_dataset.where(id: id.to_i).first
    return m.reply 'No such project' unless p
    return m.reply 'Project is finished' if p.finished?
    return m.reply 'Already participating 💪' if p.participating

    p.participating = true
    p.save

    unless p.can_sync_goal?
      m.reply '⚠ This project cannot autosync goals, ' \
      "customise yours with `#{Rogare.prefix}p #{p.id} goal 12345`"
    end

    unless p.can_sync_words?
      m.reply '⚠ This project cannot autosync its total, ' \
      "set yours with `#{Rogare.prefix}p #{p.id} total 6789`"
    end

    unless p.can_sync_name?
      m.reply '⚠ This project cannot autosync its name, ' \
      "set yours with `#{Rogare.prefix}p #{p.id} name Your fancy title`"
    end

    m.reply "Now participating in this #{p.type}! 🎆📝✨"
  end

  def get_name(m, id)
    p = m.user.projects_dataset.where(id: id.to_i).first
    return m.reply 'No such project' unless p

    m.reply "“#{p.name}”"
  end

  def set_name(m, id, name)
    p = m.user.projects_dataset.where(id: id.to_i).first
    return m.reply 'No such project' unless p

    return get_name(m, id) if name.strip.empty?

    if name =~ /sync/i
      p.sync_name = true
      p.save
      m.reply 'name will now autosync'
      return
    end

    p.name = name
    p.sync_name = false
    p.save
    m.reply format p
  end

  def get_goal(m, id)
    p = m.user.projects_dataset.where(id: id.to_i).first
    return m.reply 'No such project' unless p

    if p.goal
      m.reply [
        "**#{p.goal}**",
        ("[autosynced, last updated #{p.goal_updated}]" if p.sync_goal),
        ('[manual]' unless p.sync_goal)
      ].compact.join(' ')
    elsif p.sync_goal
      m.reply 'goal not synced yet'
    else
      m.reply 'goal not set yet'
    end
  end

  def set_goal(m, id, goal)
    p = m.user.projects_dataset.where(id: id.to_i).first
    return m.reply 'No such project' unless p

    if goal =~ /sync/i
      p.sync_goal = true
      p.save
      m.reply 'goal will now autosync'
      return
    end

    return get_goal(m, id) unless goal.to_i.positive?

    p.goal = goal.to_i
    p.sync_goal = false
    p.save
    m.reply format p
  end

  def get_words(m, id)
    p = m.user.projects_dataset.where(id: id.to_i).first
    return m.reply 'No such project' unless p

    if p.words
      m.reply [
        "**#{p.words}**",
        ("[autosynced, last updated #{p.words_updated}]" if p.sync_words),
        ('[manual]' unless p.sync_words)
      ].compact.join(' ')
    elsif p.sync_words
      m.reply 'total not synced yet'
    else
      m.reply 'total not set yet'
    end
  end

  def set_words(m, id, words)
    p = m.user.projects_dataset.where(id: id.to_i).first
    return m.reply 'No such project' unless p

    if words =~ /sync/i
      p.sync_words = true
      p.save
      m.reply 'total will now autosync'
      return
    end

    return get_words(m, id) unless words.to_i.positive?

    p.words = words.to_i
    p.sync_words = false
    p.save
    m.reply format p
  end

  private

  def format(p)
    deets = "[#{p.id}] _#{p.user.nick.gsub('_', '\\_')}’s #{p.type}_: “#{p.name}” — Starts #{p.start}, ends #{p.finish}"

    deets += if p.participating
               ' _(participating)_.'
             else
               ' _(not participating)_.'
             end

    if p.goal
      deets += "\n\t— Goal: **#{p.goal}**"
      deets += if p.sync_goal
                 " [autosynced, last updated #{p.goal_updated}]"
               else
                 ' [manual]'
               end
    end

    if p.words
      deets += "\n\t— So far: **#{p.words}**"
      deets += if p.sync_words
                 " [autosynced, last updated #{p.words_updated}]"
               else
                 ' [manual]'
               end
    end

    deets
  end
end
