require_relative '../plugins/help.rb'
Help = Rogare::Plugins::Help

RSpec.describe Rogare::Plugins::Help do
  context '#execute' do
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
