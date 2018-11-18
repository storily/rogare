# frozen_string_literal: true

class Rogare::Plugins::W
  extend Rogare::Plugin

  command '!', hidden: true
  match_empty :execute

  def execute(m, _param)
    Rogare::Plugins::Wordcount.new.own_count(m) if defined? Rogare::Plugins::Wordcount
    Rogare::Plugins::Wordwar.new.ex_list_wars(m) if defined? Rogare::Plugins::Wordwar
  end
end
