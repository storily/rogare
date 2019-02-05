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

    names = if args[:full]
              Name.fulls(args).map do |fl|
                first, last = fl
                last = last.join('-') if last.is_a? Array
                [first, last].join(' ')
              end
            else
              Name.search(args)
            end

    names = ['No matching names yet :('] if names.empty?
    m.reply names.join ', '
  end
end
