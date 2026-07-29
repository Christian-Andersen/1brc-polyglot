local MIN = 1
local MAX = 2
local TOTAL = 3
local COUNT = 4

local file, err = io.open("../../data/measurements.txt", "r")
if not file then
	error("Could not open file! Reason: " .. tostring(err))
end

local DATA = {}
for line in file:lines() do
	local city, temp = string.match(line, "([^;]+);([^;]+)")
	temp = tonumber((string.gsub(temp, "%.", "", 1))) or error("Malformed line")
	local stats = DATA[city]
	if not stats then
		stats = { temp, temp, temp, 1 }
		DATA[city] = stats
	else
		if temp < stats[MIN] then
			stats[MIN] = temp
		end
		if temp > stats[MAX] then
			stats[MAX] = temp
		end
		stats[TOTAL] = stats[TOTAL] + temp
		stats[COUNT] = stats[COUNT] + 1
	end
end
file:close()

local cities = {}
for k in pairs(DATA) do
	cities[#cities + 1] = k
end
table.sort(cities)
for _, city in ipairs(cities) do
	local stats = DATA[city]
	print(string.format("%s	%d	%d	%d	%d", city, stats[MIN], stats[MAX], stats[TOTAL], stats[COUNT]))
end
