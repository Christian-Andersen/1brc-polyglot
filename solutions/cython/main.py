from solution import solve

stats = solve("../../data/measurements.txt")
for city in sorted(stats):
    mn, mx, tot, cnt = stats[city]
    print(f"{city}\t{mn}\t{mx}\t{tot}\t{cnt}")
