class Caskbot::Plugins::Nano
  include Cinch::Plugin
  extend Memoist

  match /count(.*)/
  @@commands = ['count username']

  @@generator = Namey::Generator.new

  def execute(m, param)
    param ||= ''
    names = [m.user.nick]
    param.strip.split(' ').map do |p|
      if p.to_i > 0
        p.to_i
      else
        p.downcase
      end
    end.each do |p|
      names = []
      if p =~ /^(help|\?|how|what|--help|-h)$/
        return m.reply '!' + @@commands.first
      elsif p =~ /^(random|rand|any)$/
        names << m.channel.users.keys.shuffle.first
      else
        names << p
      end
    end

    hydra = Typhoeus::Hydra.new
    counts = {}
    names.each do |name|
      req Typhoeus::Request.new("http://nanowrimo.org/wordcount_api/wc/#{name}", followlocation: true)
      req.on_complete do |res|
        return if res.code != 200
        doc = Nokogiri::XML(res.body)
        if doc.css('error').length == 0
          counts[name] = doc.at_css('user_wordcount').content
        end
      end
    end
    hydra.run

    m.reply counts.map do |name, wc|
      "#{name}: #{wc}"
    end.join ', '
  end
end
