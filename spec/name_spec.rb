require_relative '../plugins/name.rb'
Name = Rogare::Plugins::Name

RSpec.describe Rogare::Plugins::Name do
  context ': its matcher' do
    before do
      @matcher = Name.matchers.first.pattern
    end

    it 'responds to !name' do
      expect(@matcher).to match '!name'
    end

    it 'responds to !name<space>' do
      expect(@matcher).to match '!name '
    end

    it 'responds to !name some words' do
      expect(@matcher).to match '!name some words'
    end
  end

  context ': its executor' do
    before do
      @bot = spy('bot')
      @plugin = Name.new(@bot)
    end

    context 'with no arguments' do
      it 'returns a random name and surname' do
        m = spy('message')
        @plugin.execute m, ''
        expect(m).to have_received(:reply).once.with /^\w+ \w+$/
      end
    end

    context 'with a number' do
      it '(digits) returns that amount of names' do
        m = spy('message')
        @plugin.execute m, '3'
        expect(m).to have_received(:reply).once.with /^(\w+ \w+, ){2}\w+ \w+$/
      end

      it '(words) returns that amount of names' do
        m = spy('message')
        @plugin.execute m, 'four'
        expect(m).to have_received(:reply).once.with /^(\w+ \w+, ){3}\w+ \w+$/
      end

      it '(composite) returns the first amount of names' do
        m = spy('message')
        @plugin.execute m, '5 three'
        expect(m).to have_received(:reply).once.with /^(\w+ \w+, ){4}\w+ \w+$/
      end
    end

    context 'with a one-name modifier' do
      it 'like last' do
        m = spy('message')
        @plugin.execute m, 'last name'
        expect(m).to have_received(:reply).once.with /^\w+$$/
      end

      it 'like family' do
        m = spy('message')
        @plugin.execute m, 'five family names'
        expect(m).to have_received(:reply).once.with /^(\w+, ){4}\w+$$/
      end

      it 'like given' do
        m = spy('message')
        @plugin.execute m, 'a given name'
        expect(m).to have_received(:reply).once.with /^\w+$$/
      end

      it 'like first' do
        m = spy('message')
        @plugin.execute m, '2 first names'
        expect(m).to have_received(:reply).once.with /^\w+, \w+$$/
      end
    end
  end
end
