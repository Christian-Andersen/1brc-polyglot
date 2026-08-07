open System
open System.Collections.Generic
open System.IO

type Stats = { Min: int; Max: int; Total: int64; Count: int64 }

[<EntryPoint>]
let main _ =
    let data = Dictionary<string, Stats>()
    for line in File.ReadLines("../../data/measurements.txt") do
        let semi = line.IndexOf(';')
        let city = line.Substring(0, semi)
        let temp = line.Substring(semi + 1).Replace(".", "") |> int64
        match data.TryGetValue(city) with
        | true, s ->
            data.[city] <-
                { Min = min s.Min (int temp)
                  Max = max s.Max (int temp)
                  Total = s.Total + temp
                  Count = s.Count + 1L }
        | false, _ ->
            data.[city] <-
                { Min = int temp
                  Max = int temp
                  Total = temp
                  Count = 1L }
    for kv in data |> Seq.sortBy (fun kv -> kv.Key) do
        printfn "%s\t%d\t%d\t%d\t%d" kv.Key kv.Value.Min kv.Value.Max kv.Value.Total kv.Value.Count
    0
