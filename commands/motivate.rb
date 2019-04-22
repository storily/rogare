# frozen_string_literal: true

class Rogare::Commands::Motivate
  extend Rogare::Command

  command 'motivate'
  usage '`!%`'
  handle_help

  match_command /(.+)/
  match_empty :execute

  def execute(m, _param)
    m.reply [
      'One day you will find the right words.', # Jack Kerouac
      'Write. If it’s good, you’ll find out. If it’s not, throw it out of the window.', # William Faulkner
      'Reality cannot destroy you.', # Ray Bradbury
      'Always be a poet, even in prose.', # Charles Beaudelaire
      'Write to keep civilisation from destroying itself.', # Albert Camus (adapted)
      'Mmmm… I love deadlines. I like the whooshing sound they make as they fly by.', # Douglas Adams
      'Take a chance. It may be bad, but it’s the only way you can do anything really good.', # Faulkner again
      'Someone is sitting in the shade today because they planted a tree a long time ago… ' \
        'and then worked hard to keep it alive.', # With faint apologies to Warren Buffet

      # by Félix
      'Wake up. Kick ass. Repeat.',
      'You’re gonna make it happen!',
      'Your words are magic. Recharge! Then cast again',

      # by Star
      'Imagine signing a copy of your own book. Now finish writing it.',
      'Someone out there _needs_ your story.'
    ].sample
  end
end
