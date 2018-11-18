# frozen_string_literal: true

class Rogare::Plugins::Calc
  extend Rogare::Plugin

  command 'calc'
  aliases '='
  usage '`!% <a calculation>`'
  handle_help

  match_command /(.+)/
  match_message /(?:\d+\s*[\-+]\s*\d+)/
  match_empty :help_message

  def execute(m, param)
    param.strip!

    # By far the most common calcs are simple sub/add (after wordwars)
    wordcalc = /^!?(\d+)\s*([\-+])\s*(\d+)$/.match(param)
    if wordcalc
      a = wordcalc[1].to_i
      op = wordcalc[2]
      b = wordcalc[3].to_i
      res = a - b if op == '-'
      res = a + b if op == '+'
      return m.reply "#{a} #{op} #{b} = #{res}"
    end

    res = Typhoeus.get 'https://api.wolframalpha.com/v2/query', params: {
      input: param,
      appid: ENV['WOLFRAM_KEY'],
      primary: 'true',
      format: 'plaintext'
    }

    doc = Nokogiri::XML.parse res.body
    pods = doc.css('queryresult pod')
    return m.reply 'No results ;(' if pods.nil? || pods.empty?

    pod0 = pods[0].at_css('subpod plaintext').content.strip
    pod1 = pods[1].at_css('subpod plaintext').content.strip
    return m.reply 'Mm, that didn’t work.' if pod0.nil?

    if pod1.lines.count > 2
      m.user.send "Calc results:\n#{pod0} =\n#{pod1}", true
    elsif pod0.length > 1000
      m.user.send "#{pod0} = #{pod1}", true
    else
      m.reply "#{pod0} = #{pod1}"
    end
  end
end
