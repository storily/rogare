class Rogare::Plugins::Wordcount
  include Cinch::Plugin
  extend Memoist

  match /(wordcount|words?|count|wc)(.*)/
  @@commands = ['count [nano username] (will use your IRC nickname if you don\'t give a username)']

  def execute(m, _, param)
    param = param.strip
    if param =~ /^(help|\?|how|what|--help|-h)/
      m.reply 'Usage: !' + @@commands.first
      m.reply 'Also see https://cogitare.nz' if rand > 0.9
      return
    end

    names = []
    param.split.each do |p|
      p.downcase!
      if p =~ /^(me|self|myself|i)$/
        names.push m.user.nick
      elsif p =~ /^(random|rand|any)$/
        names.push m.channel.users.keys.shuffle.first
      else
        names.push p.to_sym
      end
    end
    names.push m.user.nick if names.empty?

    counts = names.map do |name|
      res = Typhoeus.get "https://nanowrimo.org/wordcount_api/wc/#{name}"
      if res.code == 200
        doc = Nokogiri::XML(res.body)
        if doc.css('error').length == 0
          wc = doc.at_css('user_wordcount').content
          "#{name}: #{wc} (#{(wc.to_i / 500).round}%)"
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
