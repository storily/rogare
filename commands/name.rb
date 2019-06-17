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
    'how much data there is for each as not all ‘kinds’ will have data yet.',
    'A map showing rough areas for each _kind_ can be found with `!debug kind map`.',
    'There are also lots of aliases. Try to experiment! All keywords should be one word, ' \
    'hyphens may be there for multi-word keywords.'
  ]
  handle_help

  match_command /(.*)/
  match_empty :execute

  def execute(m, param = nil)
    names = if param.empty? || param.strip.empty?
              Nominare.random
            else
              Nominare.search param
            end

    names = [names] unless names.is_a? Array
    names.map! do |name|
      last = if name['last'].is_a? Array
               name['last'].join('-')
             else
               name['last']
             end

      [name['first'], last].compact.join(' ').gsub(/\s+/, "\u00a0")
    end

    m.reply names.join(', ')
  end
end
