# frozen_string_literal: true

module Rogare::Plugins
  @@custom_configs = []
  @@custom_plugins = []

  def self.to_a
    constants.map { |c| const_get c } + @@custom_plugins
  end

  def self.config(conf)
    @@custom_configs.each do |fn|
      fn.call(conf)
    end
  end

  def self.add_plugin(const, &block)
    @@custom_plugins << const
    @@custom_configs << block
  end
end
