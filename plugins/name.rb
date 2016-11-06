require 'namey'
require_relative 'nbnames'
require 'numbers_in_words'

class Caskbot::Plugins::Name
  include Cinch::Plugin
  extend Memoist

  match /name(.*)/
  @@commands = ['name put some words and numbers here and hope they do something']

  @@generator = Namey::Generator.new

  def execute(m, param)
    param ||= ''
    args = {call: :name, full: true, last: false, freq: :all}

    args[:n] = NumbersInWords.in_numbers(param.strip)

    param.strip.split(' ').map do |p|
      if p.to_i > 0
        p.to_i
      else
        p.downcase.to_sym
      end
    end.each do |p|
      if p =~ /^(help|\?|how|what|--help|-h)$/
        return m.reply 'Usage: !' + @@commands.first
      elsif p.is_a? Integer
        args[:n] = p
      elsif p =~ /^(males?|m[ae]n|boys?)$/
        args[:call] = :male
      elsif p =~ /^(females?|wom[ae]n|girls?)$/
        args[:call] = :female
      elsif p =~ /^(enby|nb)s?$/
        args[:call] = :unisex
      elsif p =~ /^(common)$/
        args[:freq] = :common
      elsif p =~ /^(rare|weird|funny|evil|bad)$/
        args[:freq] = :rare
      elsif p =~ /^(all|both)$/
        args[:freq] = :all
      elsif p =~ /^(first|given)$/
        args[:full] = false
      elsif p =~ /^(last|family)$/
        args[:full] = true
        args[:last] = true
      elsif p =~ /^(full)$/
        args[:full] = true
        args[:last] = false
      end
    end

    args[:n] = 100 if args[:n] > 100
    args[:n] = 1 if args[:n] < 1

    joined = (args[:n] * 2).times.map do
      next ENBYNAMES.sample(if args[:full] then 2 else 1 end).join(' ') if args[:call] == :unisex
      n = @@generator.send(args[:call], args[:freq], args[:full])
      if args[:last]
        n.split.last
      else
        n
      end
    end.uniq.first(args[:n]).join ', '
    m.reply joined
  end
end
