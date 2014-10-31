require 'namey'

class Caskbot::Plugins::Name
  include Cinch::Plugin
  extend Memoist

  match /name(.*)/
  @@commands = ['name [N] [male|female|common|rare|all|first|last|full] [name|names]']

  @@generator = Namey::Generator.new

  def execute(m, param)
    param ||= ''
    args = {n: 1, call: :name, full: true, last: false, freq: :all}
    param.strip.split(' ').map do |p|
      if p.to_i > 0
        p.to_i
      else
        p.downcase.to_sym
      end
    end.each do |p|
      if p =~ /^(help|\?|how|what|--help|-h)$/
        return m.reply @@commands.first
      elsif p.is_a? Integer
        args[:n] = p
      elsif p =~ /^(male|man|boy)$/
        args[:call] = :male
      elsif p =~ /^(female|woman|girl)$/
        args[:call] = :female
      elsif p =~ /^(common)$/
        args[:freq] = :common
      elsif p =~ /^(rare|weird)$/
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

    args[:n] = 10 if args[:n] > 10
    joined = args[:n].times.map do
      n = @@generator.send(args[:call], args[:freq], args[:full])
      if args[:last]
        n.split.last
      else
        n
      end
    end.join ', '
    m.reply joined
  end
end
