# frozen_string_literal: true

class Rogare::Plugins::Novel
  extend Rogare::Plugin

  command 'novel'
  usage [
    '`!%` - Show your current novel(s).',
    '`!% done` - Show your finished novel(s).',
    # '`!% all` - PMs you all your novel(s).',
    '`!% new [nano|camp] [name...]` - Start a new novel. ' \
      '`nano` and `camp` novels can only be created in their month or the 2 weeks before.',
    '`!% ID` - Show info about any novel. ' \
      'In the following sub commands, omitting `ID` will match your latest.',
    '`!% [ID] rename [name...]` - Rename your novel.',
    '`!% [ID] finish` and `unfinish` - Set your novel’s done status.',
    # '`!% [ID] stats` - Show detailed wordcount stats about your novel. Will PM you.',
    '`!% [ID] goal new [<number> words] [<number> days] [(no)repeat] [start <date>]` '\
      '- Add a new word goal to the novel.',
    '`!% [ID] goal edit [same as above]` or `!% [ID] goal edit <letter> [...]` '\
      '- Edit a goal. If `<letter>` is omitted, guesses.',
    '`!% [ID] goal remove <letter>` ' \
      '- Remove the goal from the novel. If `<letter>` is omitted, guesses.',
    "\nFor example, a revolving weekly goal of 5000 words would be set up with: " \
      '`!% goal new 5k words 7 days repeat start monday`.'
  ] # todo: nano goals rather than nano novels
  handle_help

  match_command /done/, method: :finished_novels
  match_command /new\s+(.+)/, method: :create_novel
  match_command /new/, method: :help_message

  match_command /(\d+)\s+rename\s+(.+)/, method: :rename_novel
  match_command /()rename\s+(.+)/, method: :rename_novel

  match_command /(\d+)\s+goal\s+new\s+(.+)/, method: :new_goal
  match_command /()goal\s+new\s+(.+)/, method: :new_goal

  match_command /(\d+)\s+goal\s+edit\s+(.+)/, method: :edit_goal
  match_command /()goal\s+edit\s+(.+)/, method: :edit_goal

  match_command /(\d+)\s+goal\s+(?:remove|rm)(?:\s+([a-z]+))?/, method: :remove_goal
  match_command /()goal\s+(?:remove|rm)(?:\s+([a-z]+))?/, method: :remove_goal

  match_command /(\d+)\s+goal/, method: :show_novel
  match_command /(\d+)\s+goal\s+(.*)/, method: :help_message
  match_command /goal\s+(.*)/, method: :help_message

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
    m.reply say.strip
  end

  def show_novel(m, id)
    novel = Rogare::Data.novels.where(id: id.to_i).first

    return m.reply 'No such novel' unless novel

    m.reply format_novel(novel)
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
    m.reply say.strip
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

    tz = TZInfo::Timezone.get(user[:tz] || Rogare.tz)
    now = tz.local_to_utc(tz.now)

    if ntype == 'nano' && (
      now < (Rogare::Data.first_of(11, tz) - 2.weeks) ||
      now >= Rogare::Data.first_of(12, tz))
      return m.reply 'Can’t create nano novel outside of nano time'
    end

    if ntype == 'camp' && (
      now < (Rogare::Data.first_of(4, tz) - 2.weeks) ||
      now >= Rogare::Data.first_of(5, tz) ||
      now < (Rogare::Data.first_of(7, tz) - 2.weeks) ||
      now >= Rogare::Data.first_of(8, tz))
      return m.reply 'Can’t create camp novel outside of camp time'
    end

    novel = {
      name: name,
      type: ntype,
      user_id: user[:id]
    }

    goal = nil

    if ntype == 'nano'
      novel[:started] = Rogare::Data.first_of(11, tz)
      goal = {
        start: novel[:started],
        finish: Rogare::Data.first_of(12, tz),
        words: 50_000
      }
    end

    if ntype == 'camp'
      if now >= (Rogare::Data.first_of(4, tz) - 2.weeks) || now < Rogare::Data.first_of(5, tz)
        novel[:started] = Rogare::Data.first_of(4, tz)
        goal = {
          start: novel[:started],
          finish: Rogare::Data.first_of(5, tz),
          words: 30
        }
      elsif now >= (Rogare::Data.first_of(7, tz) - 2.weeks) || now < Rogare::Data.first_of(8, tz)
        novel[:started] = Rogare::Data.first_of(7, tz)
        goal = {
          start: novel[:started],
          finish: Rogare::Data.first_of(8, tz),
          words: 31
        }
      end
    end

    id = Rogare::Data.novels.insert(novel)

    if goal
      goal[:novel_id] = id
      Rogare::Data.goals.insert(goal)
    end

    m.reply "New novel created: #{id}."
  end

  def rename_novel(m, id, name)
    user = m.user.to_db
    novel = load_novel user, id

    return m.reply 'No such novel' unless novel

    name.strip!
    Rogare::Data.novels.where(id: novel[:id]).update(name: name)

    novel[:name] = name
    m.reply format_novel(novel)
  end

  def parse_goal(line)
    # [<letter>] [<number> words] [<number> days] [(no)repeat] [start <date>]
    parser = Rogare::Data.goal_parser
    tree = parser.parse line.strip.downcase

    raise "Bad input: #{parser.failure_reason}" unless tree

    tree.value
  end

  def new_goal(m, id, line)
    user = m.user.to_db
    novel = load_novel user, id
    tz = TimeZone.new(user[:tz] || Rogare.tz)

    return m.reply 'No such novel' unless novel

    begin
      goal = parse_goal line
      goal.default_start!
    rescue StandardError => err
      return m.reply err
    end

    return m.reply "I need at least a word count" unless goal.words && goal.words.positive?

    Rogare::Data.goals.insert({
      novel_id: novel[:id],
      words: goal.words,
      start: goal.start(tz),
      finish: goal.finish(tz),
      repeat: goal.repeat,
      curve: goal.curve,
    }.compact)

    m.reply format_novel(novel)
  end

  def edit_goal(m, id, line)
    user = m.user.to_db
    novel = load_novel user, id
    tz = TimeZone.new(user[:tz] || Rogare.tz)

    return m.reply 'No such novel' unless novel

    begin
      goal = parse_goal line
    rescue StandardError => err
      return m.reply err
    end

    current = Rogare::Data.current_goal(novel, goal.offset || 0)
    update = {}
    update[:words] = goal.words if goal.words && goal.words != current[:words]
    update[:start] = goal.start(tz) if goal.start && goal.start(tz) != current[:start]
    update[:finish] = goal.finish(tz) if goal.finish(tz) && goal.finish(tz) != current[:finish]
    update[:repeat] = goal.repeat if goal.repeat && goal.repeat != current[:repeat]
    update[:curve] = goal.curve if goal.curve && goal.curve != current[:curve]

    update[:finish] = nil if goal.days.zero?

    Rogare::Data.goals.where(id: current[:id]).update(update) unless update.empty?

    m.reply format_novel(novel)
  end

  def remove_goal(m, id, letter = nil)
    user = m.user.to_db
    novel = load_novel user, id

    return m.reply 'No such novel' unless novel

    offset = letter ? (GoalTerms.letter_to_i(letter) - 1) : 0
    goal = Rogare::Data.current_goal(novel, offset)

    Rogare::Data.goals.where(id: goal[:id]).update(removed: Sequel.function(:now))

    m.reply format_novel(novel)
  end

  def finish_novel(m, id)
    user = m.user.to_db
    novel = load_novel user, id

    return m.reply 'No such novel' unless novel
    return m.reply 'Already marked done' if novel[:finished]

    Rogare::Data.novels.where(id: novel[:id]).update(finished: true)

    novel[:finished] = true
    m.reply format_novel(novel)
  end

  def unfinish_novel(m, id)
    user = m.user.to_db
    novel = load_novel user, id

    return m.reply 'No such novel' unless novel
    return m.reply 'Not marked done' unless novel[:finished]

    Rogare::Data.novels.where(id: novel[:id]).update(finished: false)

    novel[:finished] = false
    m.reply format_novel(novel)
  end

  def load_novel(user, id)
    Rogare::Data.load_novel user, id
  end

  def format_goal(goal, offset = nil)
    goal_words = Rogare::Data.goal_format(goal[:words])

    if offset
      goal_words = goal_words.sub('goal', '').strip
      "#{GoalTerms.offset_to_s(offset)}: "
    end.to_s + [
      "**#{goal_words}**",
      "starting _#{Rogare::Data.datef(goal[:start])}_",
      ("ending _#{Rogare::Data.datef(goal[:finish])}_" if goal[:finish]),
      ('repeating' if goal[:repeat]),
      ("#{goal[:curve]} curve" if goal[:curve] != 'linear')
    ].compact.join(', ') # todo: strike if goal is achieved before finish line
  end

  def format_novel(novel)
    goals = Rogare::Data.current_goals(novel).all

    "#{novel[:finished] ? '📘' : '📖'} " \
    "#{novel[:id]}. “**#{Rogare::Data.encode_entities(novel[:name] || 'Untitled')}**”. " \
    '' + [
      (novel[:type] == 'manual' ? 'S' : "#{novel[:type].capitalize} novel s") +
      "tarted _#{Rogare::Data.datef(novel[:started])}_",
      (if goals.empty?
        nil
      elsif goals.length == 1
        format_goal goals.first
      else
        "**#{goals.length}** current/future goals:"
      end unless novel[:finished]),
      ('done' if novel[:finished])
    ].compact.join(', ') + if goals.length > 1
      "\n" + goals.map.with_index { |goal, i| format_goal(goal, i) }.join("\n") + "\n"
    end.to_s # todo append number of past goals
  end
end
