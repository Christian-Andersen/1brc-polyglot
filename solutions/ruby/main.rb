Stats = Struct.new(:min, :max, :total, :count)
data = {}
File.foreach("../../data/measurements.txt") do |line|
  parts = line.split(";")
  city = parts[0]
  temp = parts[1].gsub(".", "").to_i
  data[city] ||= Stats.new(1000, -1000, 0, 0)
  data[city].min = [data[city].min, temp].min
  data[city].max = [data[city].max, temp].max
  data[city].total += temp
  data[city].count += 1
end
data.keys.sort.each do |key|
  value = data[key]
  puts "#{key}\t#{value.min}\t#{value.max}\t#{value.total}\t#{value.count}"
end
