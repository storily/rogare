module Rogare::Plugins
  @@custom_configs = []
  @@custom_plugins = []

  def self.to_a
    self.constants.map { |c| self.const_get c } + @@custom_plugins
  end

  def self.config(c)
    @@custom_configs.each do |fn|
      fn.call(c)
    end
  end

  def self.add_plugin(const, &block)
    @@custom_plugins << const
    @@custom_configs << block
  end
end
