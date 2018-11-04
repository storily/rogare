require 'csv'
require 'json'
require 'zlib'

file = ARGV.first
puts file.inspect
buckets = Array.new(100_000) { |i| [] }

# The data was originally in a SQLite DB with a frequency column, precise to
# 3 decimal places (but with duplicates that have the same freq). The idea here
# is that for freq = 12.345, we put all names that have that freq in
# `buckets[12_345]`. That way when we retrieve a random name between two freqs,
# we can say "give me a random number between A * 1000 and B * 1000", then
# fetch that bucket, and then return a random entry from it.
#
# This code extracts the data from the CSV dumps from the SQLite DB, prepares
# the buckets, and writes a compressed JSON file to be loaded by Rogare later.
#
# The data files are derived from the US census and are in the public domain.

CSV.foreach(file, col_sep: ', ') do |row|
  name = row[0]
  freq = (row[1].to_f * 1000).to_i
  buckets[freq] << name
end

Zlib::GzipWriter.open(file.sub(/csv$/, 'json.gz')) do |gz|
  gz.orig_name = file.sub(/csv$/, 'json')
  gz.write JSON.generate(buckets)
end
