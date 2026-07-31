class Stats
  property min : Int32
  property max : Int32
  property total : Int32
  property count : Int32

  def initialize(@min = Int32::MAX, @max = Int32::MIN, @total = 0, @count = 0)
  end

  def update(value : Int32)
    @min = value if value < @min
    @max = value if value > @max
    @total += value
    @count += 1
  end
end

data = {} of String => Stats
File.each_line("../../data/measurements.txt") do |line|
  parts = line.split(";")
  city = parts[0]
  temp = parts[1].gsub(".", "").to_i
  stats = data[city] ||= Stats.new
  stats.update(temp)
end
data.keys.sort.each do |key|
  value = data[key]
  puts "#{key}\t#{value.min}\t#{value.max}\t#{value.total}\t#{value.count}"
end
