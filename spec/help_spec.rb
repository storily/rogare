require_relative '../plugins/help.rb'
Help = Rogare::Plugins::Help

RSpec.describe Rogare::Plugins::Help do
  context ': its matcher' do
    before do
      @matcher = Help.matchers.first.pattern
    end

    it 'responds to !help' do
      expect(@matcher).to match '!help'
    end

    it 'responds to !list' do
      expect(@matcher).to match '!list'
    end
  end

  context ': its executor' do
    before do
      @bot = spy('bot')
      @plugin = Help.new(@bot)
    end

    it 'lists available commands' do
      m = spy('message')
      @plugin.execute m
      expect(m).to have_received(:reply).once.with /^Commands:/
    end
  end
end
