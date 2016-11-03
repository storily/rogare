class Caskbot::Plugins::List
  include Cinch::Plugin

  match /list/
  @@commands = ['list']

  def execute(m)
    m.reply 'Additional commands: !plot and !name'
  end
end
