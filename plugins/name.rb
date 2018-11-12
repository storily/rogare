# frozen_string_literal: true

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

  def execute(m, param = nil)
    param ||= ''
    args = { kinds: [], full: true, freq: [nil, nil], also: [] }

    args[:n] = NumbersInWords.in_numbers(param.strip)

    words = param.strip.split(' ')
    words.map! do |word|
      if word.to_i.to_s == word
        word.to_i
      else
        word.downcase
      end
    end

    words.each do |word|
      parse_word(args, word)
    end

    args[:n] = 100 if args[:n] > 100
    args[:n] = 1 if args[:n] < 1

    if args[:full]
      fargs = args.clone
      largs = args.clone
      fargs[:kinds] = args[:kinds] + ['first'] - ['last']
      largs[:kinds] = args[:kinds] - ['first'] + ['last']
      firsts = Rogare::Data.name_search(fargs)
      lasts = Rogare::Data.name_search(largs)
      names = firsts.zip(lasts).map { |fl| "#{fl[0]} #{fl[1]}" }
    else
      names = Rogare::Data.name_search(args)
    end

    m.reply names.join ', '
  end

  def parse_word(args, word)
    if word.is_a? Integer
      args[:n] = word
    elsif /^\d+%$/.match?(word)
      args[:freq] = [word.to_i, nil]
    elsif /^(males?|m[ae]n|boys?|lads?|guys?)$/i.match?(word)
      args[:kinds] << 'male'
    elsif /^(females?|wom[ae]n|girls?|lass(i?es)?|gals?)$/i.match?(word)
      args[:kinds] << 'female'
    elsif /^(enby|nb|enbie)s?$/i.match?(word)
      args[:kinds] << 'enby'
    elsif /^(common)$/i.match?(word)
      args[:freq] = [50, nil]
    elsif /^(rare|weird|funny|evil|bad)$/i.match?(word)
      args[:freq] = [nil, 20]
    elsif /^(all|both)$/i.match?(word)
      args[:freq] = [nil, nil]
    elsif /^(first|given)$/i.match?(word)
      args[:full] = false
      args[:kinds] << 'first'
    elsif /^(last(name)?|family|surname)$/i.match?(word)
      args[:full] = false
      args[:kinds] << 'last'
    elsif /^(afram|african-american)$/i.match?(word)
      args[:kinds] << 'afram'
    elsif /^(english|western|occidental)$/i.match?(word)
      args[:kinds] << 'english'
    elsif /^(indian)$/i.match?(word)
      args[:kinds] << 'indian'
    elsif /^(latin|spanish|portuguese|mexican|hispanic)$/i.match?(word)
      args[:kinds] << 'latin'
    elsif /^(french|français)$/i.match?(word)
      args[:kinds] << 'french'
    elsif /^(m[aā]ori|(te)?-?reo)$/i.match?(word)
      args[:kinds] << 'maori'
    elsif /^(maghreb|algerian|morroccan|tunis|north-african)$/i.match?(word)
      args[:kinds] << 'maghreb'
    elsif /^(mideast|arabic|hebrew|egyptian|middle-east)$/i.match?(word)
      args[:kinds] << 'mideast'
    elsif /^(easteuro|russian?|eastern|east(ern)?-europe|siberi(an|e)|east)$/i.match?(word)
      args[:kinds] << 'easteuro'
    elsif /^(pacific)$/i.match?(word)
      args[:kinds] << 'pacific'
      args[:also] << 'maori'
    elsif /^((poly|mela|micro)(nesian?)?|hawaii|samoa)$/i.match?(word)
      args[:kinds] << 'pacific'
    elsif /^(amerindian|american-indian|native-american|cherokee|navajo|sioux|apache)$/i.match?(word)
      args[:kinds] << 'french'
    elsif /^(full)$/i.match?(word)
      args[:full] = true
    else
      args[:also] << word
    end
  end
end
