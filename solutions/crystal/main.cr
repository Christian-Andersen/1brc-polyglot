class Stats
  property min : Int32
  property max : Int32
  property total : Int32
  property count : Int32

  def initialize(@min, @max, @total, @count)
  end
end

data = {} of String => Stats
File.each_line("../../data/measurements.txt") do |line|
  parts = line.split(";")
  city = parts[0]
  temp = parts[1].gsub(".", "").to_i
  if stats = data[city]?
    stats.min = temp if temp < stats.min
    stats.max = temp if temp > stats.max
    stats.total += temp
    stats.count += 1
  else
    data[city] = Stats.new(temp, temp, temp, 1)
  end
end
data.keys.sort.each do |key|
  value = data[key]
  puts "#{key}\t#{value.min}\t#{value.max}\t#{value.total}\t#{value.count}"
end
