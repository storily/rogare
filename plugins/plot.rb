require 'namey'

class Caskbot::Plugins::Plot
  include Cinch::Plugin
  extend Memoist

  match /plot/
  @@commands = ['plot']

  def execute(m, param)
    param ||= ''

    [last_requested, plots] = list
    if last_requested < (Time.new - 15*60)
      plots = list(true).last
    end

    m.reply plots.sample
  end

  def url
    'https://gist.githubusercontent.com/passcod/866cb3ae04fe25479d7c9232bf699a3a/raw/plots.list'
  end

  def list
    [
      Time.new,
      Typhoeus
      .get(url, followlocation: true)
      .body
      .split("\n")
      .reject { |l| l.empty? }
      .map { |l| l.strip }
    ]
  end

  memoize :url, :list
end
