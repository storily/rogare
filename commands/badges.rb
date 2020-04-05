# frozen_string_literal: true

class Rogare::Commands::Badges
  extend Rogare::Command

  command 'badges'
  usage [
    '`!%` - Show your badges (roles)',
    '`!% list` - Show available badges',
    '`!% get <badge name>...` - Wear said badge(s)',
    '`!% leave <badge name>...` - Remove said badge(s)',
    '`!% clear` - Remove all badges'
  ]
  handle_help

  match_empty :show_own
  match_command /list/, method: :list_all
  match_command /(?:get|add)\s+(.+)/, method: :add_badge
  match_command /(?:leave|re?m(?:ove)?|del(?:ete))\s+(.+)/, method: :remove_badge
  match_command /(?:get|add)/, method: :help_message
  match_command /(?:leave|re?m(?:ove)?|del(?:ete))/, method: :help_message
  match_command /clear/, method: :clear_badges
  match_command /.+/, method: :help_message

  def known_badges
    %w[
      ey/em
      he/him
      it/its
      she/her
      they/them
      any/pronoun

      auckland
      wellington
      christchurch
      otago-southland
      northland
      central-north
      waikato-taupo
      palmerston-north
      wairarapa
      hawkes-bay
      australia
      elsewhere
      overseas
    ]
  end

  def list_all(m)
    badges = m.channel.server.roles.select { |role| known_badges.include?(role.name) }
    m.reply "Available badges: #{badges.map { |b| "`#{b.name}`" }.join(', ')}"
  end

  def show_own(m)
    badges = m.user.discord.roles.select { |role| known_badges.include?(role.name) }
    if badges.empty?
      m.reply "You have no badges yet! Add some with `#{Rogare.prefix}badges get <badge name>`."
    else
      m.reply "Your badges: #{badges.map { |b| "`#{b.name}`" }.join(', ')}"
      m.reply "Add more with `#{Rogare.prefix}badges get <badge name>`." if rand > 0.5
    end
  end

  def add_badge(m, badges)
    badges = badges.downcase.split
    member = m.user.discord

    if badges.length > 1
      roles = m.channel.server.roles
      valid = badges.select { |b| known_badges.include?(b) && roles.any? { |r| r.name == b } }
      invalid = badges.reject { |b| valid.include?(b) }

      return m.reply 'I know none of these' if valid.empty?

      m.reply "Ignoring unknown: #{invalid.map { |b| "`#{b}`" }.join(', ')}" unless invalid.empty?

      err = false
      valid.each do |badge|
        role = m.channel.server.roles.find { |r| r.name == badge }
        next if member.roles.any? { |r| r.id == role.id }

        begin
          member.add_role(role, 'Asked with !badges')
        rescue StandardError => e
          err = true
          logs "!!! Failed to add badge: #{role.name} to: #{m.user.name}\n#{e}"
        end
      end

      if err
        m.reply 'Oh no, that didn’t work. Tell an admin!'
      else
        m.reply 'You got ’em!'
      end
    else
      badge = badges.first
      return m.reply 'This is not a known badge!' unless known_badges.include?(badge)

      role = m.channel.server.roles.find { |r| r.name == badge }

      if member.roles.any? { |r| r.id == role.id }
        m.reply 'You already have this badge'
      else
        begin
          member.add_role(role, 'Asked with !badges')
          m.reply 'You got it!'
        rescue StandardError => e
          m.reply 'Oh no, that didn’t work. Tell an admin!'
          logs "!!! Failed to add badge: #{role.name} to: #{m.user.name}\n#{e}"
        end
      end
    end
  end

  def remove_badge(m, badges)
    badges = badges.downcase.split
    member = m.user.discord

    if badges.length > 1
      roles = m.channel.server.roles
      valid = badges.select { |b| known_badges.include?(b) && roles.any? { |r| r.name == b } }
      invalid = badges.reject { |b| valid.include?(b) }

      return m.reply 'I know none of these' if valid.empty?

      m.reply "Ignoring unknown: #{invalid.map { |b| "`#{b}`" }.join(', ')}" unless invalid.empty?

      err = false
      valid.each do |badge|
        role = m.channel.server.roles.find { |r| r.name == badge }
        next unless member.roles.any? { |r| r.id == role.id }

        begin
          member.remove_role(role, 'Asked with !badges')
        rescue StandardError => e
          err = true
          logs "!!! Failed to remove badge: #{role.name} from: #{m.user.name}\n#{e}"
        end
      end

      if err
        m.reply 'Oh no, that didn’t work. Tell an admin!'
      else
        m.reply 'Those are gone now.'
      end
    else
      badge = badges.first
      return m.reply 'This is not a known badge!' unless known_badges.include?(badge)

      member = m.user.discord
      role = m.channel.server.roles.find { |r| r.name == badge }

      if member.roles.any? { |r| r.id == role.id }
        begin
          member.remove_role(role, 'Asked with !badges')
          m.reply 'I’ve got that'
        rescue StandardError => e
          m.reply 'Oh no, that didn’t work. Tell an admin!'
          logs "!!! Failed to remove badge: #{role.name} from: #{m.user.name}\n#{e}"
        end
      else
        m.reply 'You don’t have this badge, anyway.'
        logs "!!! Failed to remove badge: #{role.name} from: #{m.user.name}\n#{e}"
      end
    end
  end

  def clear_badges(m)
    member = m.user.discord

    err = false
    member.roles.select { |role| known_badges.include?(role.name) }.each do |role|
      member.remove_role(role, 'Asked with !badges (clear)')
    rescue StandardError => e
      err = true
      logs "!!! Failed to remove badge: #{role.name} from: #{m.user.name}\n#{e}"
    end

    if err
      m.reply 'Oh no, that didn’t work. Tell an admin!'
    else
      m.reply 'All your badges are off.'
    end
  end
end
