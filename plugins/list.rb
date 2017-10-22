class Rogare::Plugins::List
  include Cinch::Plugin

  match /list/
  @@commands = ['list']

  def execute(m)
    m.reply 'Additional commands: !name and !plot (alias: !prompt)'
    m.reply 'Also see https://cogitare.nz for prompts' if rand > 0.95
  end
end
