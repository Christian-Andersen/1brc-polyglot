\ 1BRC for gforth - simple correct implementation
include string.fs

256 constant LINEMAX
700 constant MAXN
96  constant NLEN

create linebuf LINEMAX allot
create names   MAXN NLEN * allot
create clen    MAXN cells allot
create cmin    MAXN cells allot
create cmax    MAXN cells allot
create csum    MAXN cells allot
create ccnt    MAXN cells allot
create order   MAXN cells allot

variable nc  0 nc !
variable fh
variable va
variable vb
variable mp
variable cv

: clen@ ( i -- n ) cells clen + @ ;
: clen! ( n i -- ) cells clen + ! ;
: cmin@ ( i -- n ) cells cmin + @ ;
: cmin! ( n i -- ) cells cmin + ! ;
: cmax@ ( i -- n ) cells cmax + @ ;
: cmax! ( n i -- ) cells cmax + ! ;
: csum@ ( i -- n ) cells csum + @ ;
: csum! ( n i -- ) cells csum + ! ;
: ccnt@ ( i -- n ) cells ccnt + @ ;
: ccnt! ( n i -- ) cells ccnt + ! ;
: ord@ ( i -- v ) cells order + @ ;
: ord! ( v i -- ) cells order + ! ;

: getname ( i -- a u )
  dup clen@
  swap NLEN * names +
  swap ;

: name-eq ( a u i -- f )
  getname compare 0= ;

: find-or-add ( a u -- ix )
  { a u | ix }
  nc @ 0 ?do
    a u i name-eq if i unloop exit then
  loop
  nc @ to ix
  ix 1+ nc !
  a ix NLEN * names + u cmove
  u ix clen!
  32767 ix cmin!
  -32768 ix cmax!
  ix ;

: parse-temp ( a u -- tenths )
  { a u | v neg }
  0 to v
  1 to neg
  u 0 ?do
    a i + c@ dup
    [char] - = if
      drop -1 to neg
    else
      dup [char] . = if
        drop
      else
        [char] 0 -
        v 10 * + to v
      then
    then
  loop
  v neg * ;

: process-line ( a u -- )
  { a u | p t ix mn mx }
  0 to p
  u 0 ?do
    a i + c@ [char] ; = if
      i to p leave
    then
  loop
  a p + 1+ u p - 1- parse-temp to t
  a p find-or-add to ix
  ix cmin@ to mn
  t mn < if t to mn then
  mn ix cmin!
  ix cmax@ to mx
  t mx > if t to mx then
  mx ix cmax!
  ix csum@ t + ix csum!
  ix ccnt@ 1+ ix ccnt! ;

: cmp-order ( v1 v2 -- c )
  vb ! va !
  va @ getname
  vb @ getname
  compare ;

: sort
  nc @ 0= if exit then
  nc @ 0 ?do i i ord! loop
  nc @ 1-
  0 ?do
    i mp !
    nc @ i 1+ ?do
      i ord@ mp @ ord@ cmp-order 0< if i mp ! then
    loop
    i ord@ va !
    mp @ ord@ vb !
    va @ mp @
    ord!
    vb @ i ord!
  loop ;

: print-line ( i -- )
  dup ord@ cv !
  cv @ getname type
  9 emit
  cv @ cmin@ 0 .r
  9 emit
  cv @ cmax@ 0 .r
  9 emit
  cv @ csum@ 0 .r
  9 emit
  cv @ ccnt@ 0 .r
  cr ;

: main
  s" ../../data/measurements.txt" r/o open-file throw fh !
  begin
    linebuf LINEMAX fh @ read-line throw
  while
    linebuf swap process-line
  repeat
  drop
  fh @ close-file throw
  sort
  nc @ 0 ?do i print-line loop
  bye ;

main
