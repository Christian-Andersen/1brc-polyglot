let () =
  let tbl = Hashtbl.create 65536 in
  let ic = open_in "../../data/measurements.txt" in
  let rec loop () =
    match input_line ic with
    | line ->
        let semi = String.index line ';' in
        let city = String.sub line 0 semi in
        let temp = String.sub line (semi + 1) (String.length line - semi - 1) in
        let digits = String.concat "" (String.split_on_char '.' temp) in
        let value = int_of_string digits in
        let stats =
          match Hashtbl.find_opt tbl city with
          | Some (mn, mx, tot, cnt) -> (min mn value, max mx value, tot + value, cnt + 1)
          | None -> (value, value, value, 1)
        in
        Hashtbl.replace tbl city stats;
        loop ()
    | exception End_of_file -> ()
  in
  loop ();
  close_in ic;
  let cities = Hashtbl.fold (fun c _ acc -> c :: acc) tbl [] in
  List.iter
    (fun c ->
      let mn, mx, tot, cnt = Hashtbl.find tbl c in
      Printf.printf "%s\t%d\t%d\t%d\t%d\n" c mn mx tot cnt)
    (List.sort compare cities)
