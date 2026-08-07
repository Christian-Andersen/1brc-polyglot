:- use_module(library(readutil)).
:- initialization(main, main).

parse_temp(String, Start, Tenths) :-
    atom_codes(String, Codes),
    parse_digits(Codes, Start, 0, 0, Tenths).

parse_digits(Chars, I, V, Neg, Res) :-
    nth0(I, Chars, C),
    (   C =:= 45
    ->  I1 is I + 1,
        parse_digits(Chars, I1, V, 1, Res)
    ;   C =:= 46
    ->  I1 is I + 1,
        nth0(I1, Chars, D),
        V2 is V * 10 + (D - 48),
        (   Neg =:= 1 -> Res is -V2 ; Res = V2 )
    ;   V2 is V * 10 + (C - 48),
        I1 is I + 1,
        parse_digits(Chars, I1, V2, Neg, Res)
    ).

main :-
    read_file_to_lines("../../data/measurements.txt", Lines),
    aggregate(Lines, [], Stats),
    keysort(Stats, Sorted),
    forall(member(City-e(Mn, Mx, Tot, Cnt), Sorted),
           format("~w\t~d\t~d\t~d\t~d~n", [City, Mn, Mx, Tot, Cnt])),
    halt.

aggregate([], Acc, Acc).
aggregate([LineStr|Rest], Acc, Res) :-
    atom_string(Line, LineStr),
    sub_atom(Line, Semi, 1, _, ';'),
    sub_atom(Line, 0, Semi, _, City),
    S1 is Semi + 1,
    parse_temp(Line, S1, T),
    (   select(City-e(OldMn, OldMx, OldTot, OldCnt), Acc, RestAcc)
    ->  NewMn is min(OldMn, T), NewMx is max(OldMx, T),
        NewTot is OldTot + T, NewCnt is OldCnt + 1,
        aggregate(Rest, [City-e(NewMn, NewMx, NewTot, NewCnt)|RestAcc], Res)
    ;   aggregate(Rest, [City-e(T, T, T, 1)|Acc], Res)
    ).

read_file_to_lines(File, Lines) :-
    setup_call_cleanup(
        open(File, read, S),
        read_lines(S, Lines),
        close(S)).

read_lines(S, []) :- at_end_of_stream(S), !.
read_lines(S, [L|Ls]) :-
    read_line_to_string(S, L), !,
    read_lines(S, Ls).
