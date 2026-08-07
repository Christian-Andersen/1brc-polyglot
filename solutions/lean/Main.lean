import Lean

namespace Main

structure City where
  mn : Int
  mx : Int
  sum : Int
  cnt : Int
  deriving Repr

def City.init (t : Int) : City := { mn := t, mx := t, sum := t, cnt := 1 }

def City.add (c : City) (t : Int) : City :=
  { mn := min c.mn t, mx := max c.mx t, sum := c.sum + t, cnt := c.cnt + 1 }

-- "28.4" -> 284, "-12.3" -> -123. One decimal place always.
def parseTemp (s : String) : Int :=
  let neg : Bool := s.startsWith "-"
  let body := s.drop (if neg then 1 else 0)
  let digits := body.replace "." ""
  let n : Nat :=
    match digits.toNat? with
    | some n => n
    | none   => 0
  if neg then -Int.ofNat n else Int.ofNat n

abbrev Assoc := List (String × City)

def upsert (acc : Assoc) (city : String) (t : Int) : Assoc :=
  match acc.find? (fun p => p.1 == city) with
  | some (_, c) =>
      acc.map (fun p => if p.1 == city then (city, City.add c t) else p)
  | none =>
      (city, City.init t) :: acc

partial def go : IO Unit := do
  let content <- IO.FS.readFile "../../data/measurements.txt"
  let lines := content.splitOn "\n"
  let mut acc : Assoc := []
  for line in lines do
    if line.isEmpty then continue
    let parts := line.splitOn ";"
    let city := parts[0]!
    let t := parseTemp parts[1]!
    acc := upsert acc city t
  let sorted : Assoc := List.mergeSort acc (fun a b => a.1 < b.1)
  let mut out : String := ""
  for (cty, rec) in sorted do
    out := out ++ cty ++ "\t" ++ toString rec.mn ++ "\t" ++ toString rec.mx ++
      "\t" ++ toString rec.sum ++ "\t" ++ toString rec.cnt ++ "\n"
  IO.print out

end Main

-- top-level entry for `lean --run Main.lean`
def main : IO Unit := Main.go
