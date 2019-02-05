# frozen_string_literal: true

class Name < Sequel::Model(:names_scored)
  class << self
    extend Memoist
    def kinds
      DB[:enum]
        .with(:enum, enum_values(:name_kind))
        .where do
        (Sequel.function(:left, value, 1) !~ '-') &
          (value !~ %w[first last])
      end
        .select_map(:value)
    end
    memoize :kinds

    def to_kinds(knds)
      Sequel[Sequel.pg_array(knds)].cast(:'name_kind[]')
    end

    def query(args)
      args[:kinds] ||= []
      args[:freq] ||= []

      last = args[:kinds].include? 'last'
      args[:kinds] -= %w[last male female enby] if last

      query = select(:name).order { random.function }.where(surname: last).limit(args[:n])
      query = query.where { score >= args[:freq][0] } if args[:freq][0]
      query = query.where { score <= args[:freq][1] } if args[:freq][1]

      unless args[:kinds].empty?
        castkinds = to_kinds(args[:kinds].uniq)
        query = query.where(Sequel[:kinds].pg_array.contains(castkinds))
      end

      # TODO: use args[:also] to do further filtering with fallback to non-also if there's too few results

      query
    end

    def search(args)
      query(args).all.map { |name| format name[:name], name[:surname] }
    end

    def fulls(args)
      args[:kinds] ||= []
      args[:freq] ||= []

      firsts = search(args_first_name(args))
      lasts = search(args_last_name(args))
      diff = firsts.length - lasts.length
      get_more_lasts(args, diff).each { |n| lasts << n } if diff.positive?

      lasts.map! do |name|
        next name if rand > 0.1 || name.include?('-')

        another = get_some_lasts args, 1
        another = get_more_lasts args, 1 if another == name
        [name, another].flatten
      end

      firsts.zip(lasts)
    end

    def format(name, surname = false)
      name.split(/(?<![[:alnum:]])/).map do |part|
        p = part[0..-2].capitalize + part[-1]

        p.gsub!(/^(Ma?c|V[ao]n)(\w+)/) { |_s| "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}" }

        if surname
          p.gsub!(/^O([bcdfghklmnrst]\w+)/) { |_s| "O’#{Regexp.last_match(1).capitalize}" }
          p.gsub!(/^O’Mac(\w+)/) { |_s| "O’Mac#{Regexp.last_match(1).capitalize}" }
        end

        begin
          rn = RomanNumerals.to_decimal(p.upcase)
          raise ArgumentError, 'not a roman number' if rn.zero?
          raise ArgumentError, 'not a roman number' unless RomanNumerals.to_roman(rn) == p.upcase

          p.upcase!
          if rand < 0.2
            o = case rn % 100
                when 11, 12, 13 then 'th'
                else
                  case rn % 10
                  when 1 then 'st'
                  when 2 then 'nd'
                  when 3 then 'rd'
                  else 'th'
                  end
                end

            p = "the #{rn}#{o}"
          end
        rescue ArgumentError => e
          e.inspect # do nothing
        end

        p
      end.join
    end

    def stats
      queries = kinds.map do |kind|
        where(
          Sequel.pg_array(:kinds).contains(to_kinds([kind]))
        ).select { count('*') }.as(kind)
      end

      queries << select { count('*') }.as(:total)
      queries << where(surname: false).select { count('*') }.as(:firsts)
      queries << where(surname: true).select { count('*') }.as(:lasts)

      stats = DB.select { queries }.first
      total = stats.delete :total
      firsts = stats.delete :firsts
      lasts = stats.delete :lasts

      {
        total: total,
        firsts: firsts,
        lasts: lasts,
        kinds: stats
      }
    end

    def parse_word(args, word)
      if word.is_a? Integer
        args[:n] = word
      elsif /^\d+%$/.match?(word)
        args[:freq] = [word.to_i, nil]
      elsif /^(males?|m[ae]n|boys?|lads?|guys?)$/i.match?(word)
        args[:kinds] << 'male'
      elsif /^(females?|wom[ae]n|girls?|lass(i?es)?|gals?)$/i.match?(word)
        args[:kinds] << 'female'
      elsif /^(enby|nb|enbie)s?$/i.match?(word)
        args[:kinds] << 'enby'
      elsif /^(common)$/i.match?(word)
        args[:freq] = [50, nil]
      elsif /^(rare|weird|funny|evil|bad)$/i.match?(word)
        args[:freq] = [nil, 20]
      elsif /^(all|both)$/i.match?(word)
        args[:freq] = [nil, nil]
      elsif /^(first|given)$/i.match?(word)
        args[:full] = false
        args[:kinds] << 'first'
      elsif /^(last(name)?|family|surname)$/i.match?(word)
        args[:full] = false
        args[:kinds] << 'last'
      elsif /^(afram|african-?american)$/i.match?(word)
        args[:kinds] << 'afram'
      elsif /^(english|western|occidental)$/i.match?(word)
        args[:kinds] << 'english'
      elsif /^(indian)$/i.match?(word)
        args[:kinds] << 'indian'
      elsif /^(latin|spanish|portuguese|mexican|hispanic)$/i.match?(word)
        args[:kinds] << 'latin'
      elsif /^(french|français)$/i.match?(word)
        args[:kinds] << 'french'
      elsif /^(m[aā]ori|(te)?-?reo)$/i.match?(word)
        args[:kinds] << 'maori'
      elsif /^(maghreb|algerian|morroccan|tunis|north-?african)$/i.match?(word)
        args[:kinds] << 'maghreb'
      elsif /^(mideast|arabic|hebrew|egyptian|middle-?east)$/i.match?(word)
        args[:kinds] << 'mideast'
      elsif /^(easteuro|russian?|eastern|east(ern)?-?europe|siberi(an|e)|east)$/i.match?(word)
        args[:kinds] << 'easteuro'
      elsif /^(pacific)$/i.match?(word)
        args[:kinds] << 'pacific'
        args[:also] << 'maori'
      elsif /^((poly|mela|micro)(nesian?)?|hawaii|samoa)$/i.match?(word)
        args[:kinds] << 'pacific'
      elsif /^(amerindian|american-?indian|native-?american|cherokee|navajo|sioux|apache)$/i.match?(word)
        args[:kinds] << 'amerindian'
      elsif /^(aborigin(al|e)?|native-?australian)$/i.match?(word)
        args[:kinds] << 'aboriginal'
      elsif /^(full)$/i.match?(word)
        args[:full] = true
      else
        args[:also] << word
      end
    end

    private

    def enum_values(type)
      DB.select do
        unnest.function(
          enum_range.function(Sequel[nil].cast(type))
        ).cast(:text).as(:value)
      end
    end

    def amend_args(args, plus, minus)
      new_args = args.clone
      new_args[:kinds] = args[:kinds] - [minus] + [plus]
      new_args
    end

    def args_first_name(args)
      amend_args(args, 'first', 'last')
    end

    def args_last_name(args)
      amend_args(args, 'last', 'first')
    end

    def get_some_lasts(args, amount)
      new_args = args_last_name args
      new_args[:n] = amount
      Name.search new_args
    end

    def get_more_lasts(args, amount)
      Name.search(
        n: amount,
        kinds: ['last'],
        full: false,
        freq: args[:freq],
        also: args[:kinds] - ['first']
      )
    end
  end
end
