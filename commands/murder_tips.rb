# frozen_string_literal: true

class Rogare::Commands::MurderTips
  extend Rogare::Command

  command 'tips', hidden: true
  usage '`!%` — Content warning for allusions to murder'
  handle_help

  match_command /(.+)/, method: :execute
  match_empty :execute

  def execute(m, _param)
    m.reply [
      'Make sure to burn all the hair.',
      'Acid leaves few traces but will get you in databases.',
      'Thermite is useful for small items to dispose of at a pinch. Take care when storing.',
      'Even stainless steel rings and bars will rust if in presence of steel wool in saline.',
      'Never underestimate the effectiveness of a good cement block and a length of chain.',
      'Modern cars are awfully electronic these days; even with submersion or deflagration, prefer older models.',
      'Do not forget to leave the freezer going: one never knows when one has a need.',
      'Making incidents implausibly intentional can be convoluted, but remember the mundane is often the most overlooked.',
      'Statistics say one of the suprisingly common causes of accidental deaths is falling air-conditioning units. Do with that what you will.',
      "Digging shallow graves\nprotects no shovels nor braves;\ngo six feet under\nor bars you\'ll see forever.",
      'Make pumice a part of your hand-washing routine.',
      'Rotten blood smells foul, but you\'ll need to build up a tolerance: fortunately, that\'s a common enough supermarket purchase and some weeks or months in the waiting.',
      'Plan everything, but always take an extra knife.',
      'Spare hankerchiefs will make you look both distinguished, if a bit old-fashioned, and provide a discrete means of wiping blood off fingers, doorknobs, and blades.',
      'Carry a flask of strong alcohol to disinfect, act as solvent, or fortify.',
      'Pigs are notoriously picky eaters, despite popular claims. Some bodies they\'ll eat, some bodies they\'ll leave.',
      'Getting gored by a wild animal is terribly Games of Thrones. Try not to make it too obvious.',
      'Mafiosos generally have codes. You can exploit that, and suffer their wrath, or you can play by their rules and leave them confused or oblivious.',
      'Take care of the reputation you leave. An assassination in bright daylight is a thrill, but you\'ll get no sympathy from the horrified passerbys.',
      'Keep our tools sharp and your senses sharper.',
      'Absence of a body is a mystery; finding the wrong one is a frustration.'
    ].sample
  end
end
