# frozen_string_literal: true

class Rogare::Plugins::Novel
  extend Rogare::Plugin

  command 'novel'
  usage [
    '`!%` - Show your current novel(s).',
    '`!% done` - Show your finished novel(s).',
    '`!% new [nano|camp] [name...]` - Start a new novel. ' \
      '`nano` and `camp` novels can only be created in their month or the 2 weeks before.',
    '`!% ID` - Show info about any novel. ' \
      'In the following sub commands, omitting `ID` will match your latest.',
    '_(not yet)_ `!% [ID] rename [name...]` - Rename your novel.',
    '_(not yet)_ `!% [ID] goal NUMBER` - Set a wordcount goal for your novel. `0` disables.',
    # '`!% [ID] curve linear|???` - Set which curve to use for your novel’s goal.',
    '`!% [ID] finish` and `unfinish` - Set your novel’s done status.',
    '_(not yet)_ `!% [ID] stats` - Show detailed wordcount stats about your novel. Will PM you.'
  ]
  handle_help

  match_command /done/, method: :finished_novels
  match_command /new\s+(.+)/, method: :create_novel

  match_command /(\d+)\s+rename\s+(.+)/, method: :rename_novel
  match_command /()rename\s+(.+)/, method: :rename_novel

  match_command /(\d+)\s+goal\s+(.+)/, method: :goalify_novel
  match_command /()goal\s+(.+)/, method: :goalify_novel

  # match_command /(\d+)\s+curve\s+(.+)/, method: :curve_novel
  # match_command /()curve\s+(.+)/, method: :curve_novel

  match_command /(\d+)\s+finish/, method: :finish_novel
  match_command /finish\s+(\d+)/, method: :finish_novel
  match_command /()finish/, method: :finish_novel

  match_command /(\d+)\s+unfinish/, method: :unfinish_novel
  match_command /unfinish\s+(\d+)/, method: :unfinish_novel
  match_command /()unfinish/, method: :unfinish_novel

  # match_command /(\d+)\s+stats\s+(.+)/, method: :statsify_novel
  # match_command /()stats\s+(.+)/, method: :statsify_novel

  match_command /(\d+)/, method: :show_novel
  match_empty :current_novels

  def current_novels(m)
    user = m.user.to_db
    novels = Rogare::Data.current_novels(user).all

    return m.reply 'No current novels! Start one with `!novel new name...`' if novels.empty?

    nmore = nil
    if novels.length > 4 # not an off-by-one! shows 1,2,3,4,3+2,3+3 etc...
      nmore = novels.length - 3
      novels.first!(3)
    end

    say = novels.map { |nov| format_novel nov }.join("\n")
    say += "\nand #{nmore} more" if nmore
    m.reply say
  end

  def finished_novels(m)
    user = m.user.to_db
    novels = Rogare::Data
             .novels
             .where { (user_id =~ user[:id]) & (finished =~ true) }
             .reverse(:started)
             .all

    return m.reply 'None finished (yet!)' if novels.empty?

    nmore = nil
    if novels.length > 4 # not an off-by-one! shows 1,2,3,4,3+2,3+3 etc...
      nmore = novels.length - 3
      novels.first!(3)
    end

    say = novels.map { |nov| format_novel nov }.join("\n")
    say += "\nand #{nmore} more" if nmore
    m.reply say
  end

  def create_novel(m, name)
    user = m.user.to_db
    name.strip!

    ntype = if /^nano\s/i.match?(name)
              name.sub(/^nano\s+/i, '')
              'nano'
            elsif /^camp\s/i.match?(name)
              name.sub(/^camp\s+/i, '')
              'camp'
            else
              'manual'
            end

    if ntype == 'nano' && (
      Time.now < (Rogare::Data.first_of(11) - 2.weeks) ||
      Time.now >= Rogare::Data.first_of(12))
      return m.reply 'Can’t create nano novel outside of nano time'
    end

    if ntype == 'camp' && (
      Time.now < (Rogare::Data.first_of(4) - 2.weeks) ||
      Time.now >= Rogare::Data.first_of(5) ||
      Time.now < (Rogare::Data.first_of(7) - 2.weeks) ||
      Time.now >= Rogare::Data.first_of(8))
      return m.reply 'Can’t create camp novel outside of camp time'
    end

    id = Rogare::Data.novels.insert(user_id: user[:id], name: name, type: ntype)
    m.reply "New novel created: #{id}."
  end

  def finish_novel(m, id)
    user = m.user.to_db
    novel = if id.empty?
              Rogare::Data.current_novels(user).first
            else
              Rogare::Data.novels.where(user_id: user[:id], id: id.to_i).first
            end

    return m.reply 'No such novel' unless novel
    return m.reply 'Already marked done' if novel[:finished]

    Rogare::Data.novels.where(id: novel[:id]).update(finished: true)

    novel[:finished] = true
    m.reply format_novel(novel)
  end

  def unfinish_novel(m, id)
    user = m.user.to_db
    novel = if id.empty?
              Rogare::Data.current_novels(user).first
            else
              Rogare::Data.novels.where(user_id: user[:id], id: id.to_i).first
            end

    return m.reply 'No such novel' unless novel
    return m.reply 'Not marked done' unless novel[:finished]

    Rogare::Data.novels.where(id: novel[:id]).update(finished: false)

    novel[:finished] = false
    m.reply format_novel(novel)
  end

  def format_novel(novel)
    "#{novel[:id]}. “#{(novel[:name] || 'Untitled').gsub(/\s+/, ' ')}”. " \
    '' + [
      (novel[:type] == 'manual' ? 'S' : "#{novel[:type].capitalize} novel s") +
      "tarted #{novel[:started].strftime('%Y-%m-%d')}",
      (Rogare::Data.goal_format novel[:goal] if novel[:goal]),
      ("#{novel[:curve]} curve" if novel[:goal] && novel[:curve] != 'linear'),
      ('done' if novel[:finished])
    ].compact.join(', ') + '.'
  end
end
