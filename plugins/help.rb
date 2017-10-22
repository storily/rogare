class Rogare::Plugins::Help
  include Cinch::Plugin

  match /(help|list|bot|what)/
  @@commands = ['help']

  def execute(m)
    m.reply 'Bot answers to: !count (!wc), !wordwar (!ww), !pick (!choose), !help, !name, and !plot (!prompt, !seed)'
    m.reply 'Use "!commandname help" for more info'
    m.reply 'Also see https://cogitare.nz for prompts' if rand > 0.9
  end
end
