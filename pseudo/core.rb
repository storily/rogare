# frozen_string_literal: true

module Rogare
  class << self
    def discord
      return @bot if @bot

      @bot = Pseudo::Bot.new

      @bot.ready do
        @bot.update_status('online', Rogare.game, nil)
      end

      @bot.message do |event|
        user_cache.getset(event.author.id) do
          User.create_from_discord(event.author)
        end.seen!
      end

      @bot
    end

    def spinoff(_thing, &block)
      @@threads << Thread.new(&block)
    end
  end
end
