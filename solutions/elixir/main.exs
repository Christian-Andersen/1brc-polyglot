File.stream!("../../data/measurements.txt")
|> Enum.reduce(%{}, fn line, acc ->
  [city, temp] = line |> String.trim_trailing() |> String.split(";")
  temp = temp |> String.replace(".", "") |> String.to_integer()
  Map.update(acc, city, %{min: temp, max: temp, total: temp, count: 1}, fn s ->
    %{
      min: min(s.min, temp),
      max: max(s.max, temp),
      total: s.total + temp,
      count: s.count + 1
    }
  end)
end)
|> Enum.sort()
|> Enum.each(fn {city, s} ->
  IO.puts("#{city}\t#{s.min}\t#{s.max}\t#{s.total}\t#{s.count}")
end)
