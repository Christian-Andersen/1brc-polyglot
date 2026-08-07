Stats = Struct.new(:min, :max, :total, :count)
data = {}
File.foreach("../../data/measurements.txt") do |line|
  parts = line.split(";")
  city = parts[0]
  temp = parts[1].gsub(".", "").to_i
  if data.key?(city)
    s = data[city]
    s.min = temp if temp < s.min
    s.max = temp if temp > s.max
    s.total += temp
    s.count += 1
  else
    data[city] = Stats.new(temp, temp, temp, 1)
  end
end
data.keys.sort.each do |key|
  value = data[key]
  puts "#{key}\t#{value.min}\t#{value.max}\t#{value.total}\t#{value.count}"
end
