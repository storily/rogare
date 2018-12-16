# frozen_string_literal: true

module Preparation
  def self.bake
    constants.each do |name|
      logs "     > #{name}"
      prep = const_get name
      preppy = prep.singleton_class

      preppy.extend Memoist
      preppy.memoize :prepare

      preppy.define_method :call do |*args|
        prep.prepare.call(*args)
      end
      preppy.alias_method :[], :call

      prep.init
    end
  end
end
