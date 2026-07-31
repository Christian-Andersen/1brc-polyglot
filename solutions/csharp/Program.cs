struct Stats
{
    public int Min { get; }
    public int Max { get; }
    public int Total { get; }
    public int Count { get; }
    public Stats(int min, int max, int total, int count)
    {
        Min = min;
        Max = max;
        Total = total;
        Count = count;
    }
}
class Program
{
    static void Main()
    {
        var stats = new Dictionary<string, Stats>();
        foreach (string line in File.ReadLines("../../data/measurements.txt"))
        {
            string[] parts = line.Split(";", 2);
            string city = parts[0];
            int.TryParse(parts[1].Replace(".", ""), out int temp);
            if (stats.TryGetValue(city, out Stats existingStats))
            {
                stats[city] = new Stats(
                    min: Math.Min(existingStats.Min, temp),
                    max: Math.Max(existingStats.Max, temp),
                    total: existingStats.Total + temp,
                    count: existingStats.Count + 1
                );
            }
            else
            {
                stats[city] = new Stats(temp, temp, temp, 1);
            }
        }
        var sortedKeys = stats.Keys.OrderBy(k => k, StringComparer.Ordinal);
        foreach (var key in sortedKeys)
        {
            Stats s = stats[key];
            Console.WriteLine($"{key}\t{s.Min}\t{s.Max}\t{s.Total}\t{s.Count}");
        }
    }
}
