# frozen_string_literal: true

class Rogare::Commands::Dice
  extend Rogare::Command

  command 'dice'
  aliases 'roll'
  usage '`!% 3d6` or `!% 4d5 d20` or even `!% 2d12o24` (each roll offset by 24)'
  handle_help

  match_command /(.+)/
  match_empty :help_message

  def execute(m, param)
    die_regex = /(?<amount>\d+)?d(?<sides>\d+)(?:o(?<offset>\d+))?/

    dice = param.split.map do |die|
      bits = die_regex.match die
      next unless bits
      logs bits.inspect

      amount = (bits[:amount] || 1).to_i
      sides = (bits[:sides] || 6).to_i
      offset = (bits[:offset] || 0).to_i

      next if amount.zero?
      next 0 if sides.zero?

      amount.times.map { rand(sides + 1) + 1 + offset }
    end.compact.flatten

    if dice.empty?
      m.reply "dunno how to roll that!"
    else
      m.reply "#{dice.join(' ')} (#{dice.sum} total)"
    end
  end
end
