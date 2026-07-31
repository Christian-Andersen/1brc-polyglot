mutable struct Stats
    min::Int
    max::Int
    total::Int
    count::Int
end
data = Dict{String, Stats}()
open("../../data/measurements.txt", "r") do file
    for line in eachline(file)
        city, temp = split(line, ";", limit=2)
        temp = parse(Int, replace(temp, "." =>""))
        stats = get!(data, city) do
            Stats(temp, temp, 0, 0)
        end
        stats.min = min(stats.min, temp)
        stats.max = max(stats.max, temp)
        stats.total += temp
        stats.count += 1
    end
end
for city in sort(collect(keys(data)))
    stats = data[city]
    println("$city\t$(stats.min)\t$(stats.max)\t$(stats.total)\t$(stats.count)")
end
