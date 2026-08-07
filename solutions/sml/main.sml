structure Main =
struct
  type station = { min : int, max : int, sum : int, count : int }

  fun hashCity s =
    let
      val n = String.size s
      fun loop i acc =
        if i >= n then acc
        else loop (i + 1) (Word.+ (Word.* (acc, 0w31), Word.fromInt (Char.ord (String.sub (s, i)))))
    in
      loop 0 0w0
    end

  fun parseTemp s =
    let
      val n = String.size s
      val neg = n > 0 andalso String.sub (s, 0) = #"-"
      val start = if neg then 1 else 0
      fun d i = Char.ord (String.sub (s, i)) - Char.ord #"0"
      fun go i acc =
        if i >= n then acc
        else
          case String.sub (s, i) of
            #"." => acc * 10 + (if i + 1 < n then d (i + 1) else 0)
          | _ => go (i + 1) (acc * 10 + d i)
    in
      if neg then ~(go start 0) else go start 0
    end

  fun splitSemi s =
    let
      val n = String.size s
      fun idx i = if i >= n then n else if String.sub (s, i) = #";" then i else idx (i + 1)
      val p = idx 0
    in
      (String.substring (s, 0, p), String.substring (s, p + 1, n - p - 1))
    end

  fun intToString n =
    if n < 0 then "-" ^ Int.toString (~n) else Int.toString n

  fun run () =
    let
      val ht =
        HashTable.mkTable (hashCity, fn (a, b) => a = b) (4096, Fail "city")
      val ins = TextIO.openIn "../../data/measurements.txt"
      fun foldLine () =
        case TextIO.inputLine ins of
          NONE => ()
        | SOME line =>
            let
              val (city, tstr) = splitSemi line
              val t = parseTemp tstr
            in
              (case HashTable.find ht city of
                 NONE =>
                   HashTable.insert
                     ht
                     (city, ({ min = t, max = t, sum = t, count = 1 } : station))
               | SOME r =>
                   HashTable.insert
                     ht
                     ( city
                     , ( { min = Int.min (#min r, t)
                         , max = Int.max (#max r, t)
                         , sum = #sum r + t
                         , count = #count r + 1
                         }
                       : station
                       )
                     ));
              foldLine ()
            end
      val _ = foldLine ()
      val _ = TextIO.closeIn ins
      val entries =
        HashTable.foldi (fn (city, r, acc) => (city, r) :: acc) [] ht
      val sorted =
        ListMergeSort.sort
          (fn ((a, _), (b, _)) => String.compare (a, b) <> LESS)
          entries
      fun emit (city, r : station) =
        print
          (city ^ "\t" ^ intToString (#min r) ^ "\t" ^ intToString (#max r)
           ^ "\t" ^ intToString (#sum r) ^ "\t" ^ intToString (#count r)
           ^ "\n")
    in
      app emit sorted;
      TextIO.flushOut TextIO.stdOut;
      OS.Process.exit OS.Process.success
    end

  val _ = run ()
end