# Pulled from https://github.com/muffinista/namey
# This file, including its modifications in this project, is MIT licensed.
#
# The purpose of copying and changing it is to remove the dependency on SQLite,
# which is not supported on Heroku.

require 'json'
require 'zlib'

module Namey
  class << self
    def load_data(name)
      # See data/bucketise.rb for how this data is generated and organised.
      file = "#{__dir__}/../data/#{name}.json.gz"
      Zlib::GzipReader.open(file) {|gz|
        return JSON.load gz.read
      }
    end
  end

  class Generator
    def initialize()
      @db = [:male, :female, :surname].map do |name|
        [name, Namey.load_data(name)]
      end.to_h
    end

    def name(frequency = :common, surname = true)
      generate(:frequency => frequency, :with_surname =>surname)
    end

    def male(frequency = :common, surname = true)
      generate(:type => :male, :frequency => frequency, :with_surname => surname)
    end

    def female(frequency = :common, surname = true)
      generate(:type => :female, :frequency => frequency, :with_surname => surname)
    end

    def surname(frequency = :common)
      generate(:type => :surname, :frequency => frequency)
    end

    def generate(params = {})
      params = {
        :type => random_gender,
        :frequency => :common,
        :with_surname => true
      }.merge(params)

      if ! ( params[:min_freq] || params[:max_freq] )
        params[:min_freq], params[:max_freq] = frequency_values(params[:frequency])
      else

        params[:min_freq] = params[:min_freq].to_i
        params[:max_freq] = params[:max_freq].to_i

        params[:max_freq] = params[:min_freq] + 1 if params[:max_freq] <= params[:min_freq]
        params[:max_freq] = 4 if params[:max_freq] < 4
      end

      name = nil
      while name == nil
        name = get_name(params[:type], params[:min_freq], params[:max_freq])
      end

      if params[:type] != :surname && params[:with_surname] == true
        surname = nil
        while surname == nil
          surname = get_name(:surname, params[:min_freq], params[:max_freq])
        end

        name = "#{name} #{surname}"
      end
      name
    end

    protected

    def frequency_values(f)
      low = case f
            when :common then 0
            when :rare then 40
            when :all then 0
            else 0
            end

      high = case f
            when :common then 20
            when :rare then 99
            when :all then 99
            else 99
            end

      [ low, high ]
    end

    def random_gender
      rand > 0.5 ? :male : :female
    end

    def get_name(src, min_freq = 0, max_freq = 99, try = 0)
      low = min_freq * 1000
      high = max_freq * 1000
      bucket = rand(low..high)

      names = @db[src.to_sym][bucket]
      if names.empty?
        if try > 10
          nil
        else
          get_name(src, min_freq, max_freq, try + 1)
        end
      else
        names.sample
      end
    end
  end
end
