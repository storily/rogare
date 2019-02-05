# frozen_string_literal: true

require 'numbers_in_words'

class Rogare::Commands::Name
  extend Rogare::Command
  extend Memoist

  command 'name'
  aliases 'names'
  usage [
    '`!% [optionally put some words and numbers here and hope they do something]`',
    '`common` and `rare` control the _weirdness_ of names. ' \
    '`male`, `female`, `enby` control the gender. ' \
    'Any number controls the amount. ' \
    'Anything else will be interpreted as a _kind_.',
    'Names are categorised by _kind_, which is sort of a rough origin/ethinicity thing. ' \
    'You can find the list of kinds by running `!debug name stats`, which also shows ' \
    'much data there is for each as not all ‘kinds’ will have data yet.',
    'A map showing rough areas for each _kind_ can be found with `!debug kind map`.',
    'There are also lots of aliases. Try to experiment! All keywords should be one word, ' \
    'hyphens may be there for multi-word keywords.'
  ]
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
      Name.parse_word(args, word)
    end

    args[:n] = 100 if args[:n] > 100
    args[:n] = 1 if args[:n] < 1

    if args[:full]
      firsts = Name.search(args_first_name(args))
      lasts = Name.search(args_last_name(args))
      diff = firsts.length - lasts.length
      get_more_lasts(args, diff).each { |n| lasts << n } if diff.positive?

      lasts.map! do |name|
        next name if rand > 0.1 || name.include?('-')

        another = get_some_lasts args, 1
        another = get_more_lasts args, 1 if another == name
        [name, another].join('-')
      end

      names = firsts.zip(lasts).map { |fl| "#{fl[0]} #{fl[1]}" }
    else
      names = Name.search(args)
    end

    names = ['No matching names yet :('] if names.empty?
    m.reply names.join ', '
  end

  def amend_args(args, plus, minus)
    new_args = args.clone
    new_args[:kinds] = args[:kinds] - [minus] + [plus]
    new_args
  end

  def args_first_name(args)
    amend_args(args, 'first', 'last')
  end

  def args_last_name(args)
    amend_args(args, 'last', 'first')
  end

  def get_some_lasts(args, amount)
    new_args = args_last_name args
    new_args[:n] = amount
    Name.search new_args
  end

  def get_more_lasts(args, amount)
    Name.search(
      n: amount,
      kinds: ['last'],
      full: false,
      freq: args[:freq],
      also: args[:kinds] - ['first']
    )
  end
end
