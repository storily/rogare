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
      query(args).all.map { |name| format name[:name] }
    end

    def format(name)
      name.split(/(?<![[:alnum:]])/).map do |part|
        (part[0..-2].capitalize + part[-1])
          .gsub(/^(Ma?c|V[ao]n)(\w+)/) { |_s| "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}" }
          .gsub(/^O([bcdfghklmnrst]\w+)/) { |_s| "O’#{Regexp.last_match(1).capitalize}" }
          .gsub(/^O’Mac(\w+)/) { |_s| "O’Mac#{Regexp.last_match(1).capitalize}" }
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
  end
end
