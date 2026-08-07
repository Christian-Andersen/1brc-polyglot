program main;
uses SysUtils;

const
  cap = 65536;

type
  TEntry = record
    city: string;
    min: longint;
    max: longint;
    total: int64;
    count: int64;
    used: boolean;
  end;

var
  table: array[0..cap - 1] of TEntry;
  f: Text;
  line: string;
  semi: SizeInt;
  city, temp: string;
  value: int64;
  i, idx, n, j, k: longint;
  order: array[0..cap - 1] of longint;

function hashf(const s: string): longint;
var
  h, i: longint;
begin
  h := 0;
  for i := 1 to Length(s) do
    h := (h * 31 + Ord(s[i])) mod cap;
  if h = 0 then h := 1;
  hashf := h;
end;

begin
  Assign(f, '../../data/measurements.txt');
  Reset(f);
  while not EOF(f) do
  begin
    ReadLn(f, line);
    semi := Pos(';', line);
    if semi = 0 then Continue;
    city := Copy(line, 1, semi - 1);
    temp := Copy(line, semi + 1, Length(line) - semi);
    temp := StringReplace(temp, '.', '', [rfReplaceAll]);
    value := StrToInt64(temp);

    idx := hashf(city);
    while table[idx].used and (table[idx].city <> city) do
      idx := (idx + 1) mod cap;

    if not table[idx].used then
    begin
      table[idx].used := True;
      table[idx].city := city;
      table[idx].min := value;
      table[idx].max := value;
      table[idx].total := value;
      table[idx].count := 1;
    end
    else
    begin
      if value < table[idx].min then table[idx].min := value;
      if value > table[idx].max then table[idx].max := value;
      table[idx].total := table[idx].total + value;
      table[idx].count := table[idx].count + 1;
    end;
  end;
  Close(f);

  n := 0;
  for i := 0 to cap - 1 do
    if table[i].used then
    begin
      order[n] := i;
      Inc(n);
    end;

  for i := 1 to n - 1 do
  begin
    k := order[i];
    j := i - 1;
    while (j >= 0) and (table[order[j]].city > table[k].city) do
    begin
      order[j + 1] := order[j];
      Dec(j);
    end;
    order[j + 1] := k;
  end;

  for i := 0 to n - 1 do
  begin
    idx := order[i];
    WriteLn(table[idx].city, #9, table[idx].min, #9, table[idx].max, #9,
      table[idx].total, #9, table[idx].count);
  end;
end.
