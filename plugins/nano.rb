class Caskbot::Plugins::Nano
  include Cinch::Plugin
  extend Memoist

  match /count(.*)/
  @@commands = ['count username']

  def execute(m, param)
    param ||= ''
    names = []
    param.strip.split.each do |p|
      p = p.downcase.to_sym
      if p =~ /^(help|\?|how|what|--help|-h)$/
        return m.reply 'Usage: !' + @@commands.first
      elsif p =~ /^(me|self|myself|i)$/
        names.push m.user.nick
      elsif p =~ /^(random|rand|any)$/
        names.push m.channel.users.keys.shuffle.first
      else
        names.push p
      end
    end
    names.push m.user.nick if names.empty?

    counts = names.map do |name|
      res = Typhoeus.get "http://nanowrimo.org/wordcount_api/wc/#{name}"
      if res.code == 200
        doc = Nokogiri::XML(res.body)
        if doc.css('error').length == 0
          wc = doc.at_css('user_wordcount').content
          "#{name}: #{wc}"
        else
          nil
        end
      else
        nil
      end
    end

    m.reply counts.compact.join(', ')
  end
end
