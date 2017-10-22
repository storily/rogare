class Rogare::Plugins::List
  include Cinch::Plugin

  match /list/
  @@commands = ['list']

  def execute(m)
    m.reply 'Additional commands: !name and !plot (alias: !prompt)'
  end
end
