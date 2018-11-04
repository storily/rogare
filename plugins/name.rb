# frozen_string_literal: true

require_relative '../lib/namey'
require_relative '../lib/nbnames'
require 'numbers_in_words'

class Rogare::Plugins::Name
  extend Rogare::Plugin
  extend Memoist

  command 'name'
  aliases 'names'
  usage '!% [optionally put some words and numbers here and hope they do something]'
  handle_help

  match_command /(.*)/
  match_empty :execute

  @@generator = Namey::Generator.new

  def execute(m, param = nil)
    param ||= ''
    args = { call: :name, full: true, last: false, freq: :all }

    args[:n] = NumbersInWords.in_numbers(param.strip)

    param.strip.split(' ').map do |p|
      if p.to_i > 0
        p.to_i
      else
        p.downcase.to_sym
      end
    end.each do |p|
      if p.is_a? Integer
        args[:n] = p
      elsif /^(males?|m[ae]n|boys?)$/i.match?(p)
        args[:call] = :male
      elsif /^(females?|wom[ae]n|girls?)$/i.match?(p)
        args[:call] = :female
      elsif /^(enby|nb|enbie)s?$/i.match?(p)
        args[:call] = :unisex
      elsif /^(pierre|stone|rock|pebble)s?$/i.match?(p)
        args[:call] = :pierre
      elsif /^(common)$/i.match?(p)
        args[:freq] = :common
      elsif /^(rare|weird|funny|evil|bad)$/i.match?(p)
        args[:freq] = :rare
      elsif /^(all|both)$/i.match?(p)
        args[:freq] = :all
      elsif /^(first|given)$/i.match?(p)
        args[:full] = false
      elsif /^(last(name)?|family|surname)$/i.match?(p)
        args[:full] = true
        args[:last] = true
      elsif /^(full)$/i.match?(p)
        args[:full] = true
        args[:last] = false
      end
    end

    args[:n] = 100 if args[:n] > 100
    args[:n] = 1 if args[:n] < 1

    joined = (args[:n] * 3).times.map do
      next ENBYNAMES.sample(args[:full] ? 2 : 1).join(' ') if args[:call] == :unisex
      next %w[Pierre Pierre].sample(args[:full] ? 2 : 1).join(' ') if args[:call] == :pierre

      n = @@generator.send(args[:call], args[:freq], args[:full])
      if args[:last]
        n.split.last
      else
        n
      end
    end.compact

    if args[:call] == :pierre
      stone = rand < 0.4
      stoned = stone ? 'It’s the Stone Age' : 'C’est l’Age de Pierre '
      joined.map! { |n| n.gsub(/Pierre/, 'Stone') } if stone
      joined[0] = "#{stoned}! #{joined[0]}"
    else
      joined = joined.uniq
    end

    m.reply joined.first(args[:n]).join ', '
  end
end
