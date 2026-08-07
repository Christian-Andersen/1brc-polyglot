#!/usr/bin/env escript

main(_) ->
    ok = io:setopts(standard_io, [{encoding, utf8}]),
    {ok, F} = file:open("../../data/measurements.txt", [read, {encoding, utf8}]),
    Map = process_file(F, #{}),
    file:close(F),
    lists:foreach(
      fun({City, {Mn, Mx, Tot, Cnt}}) ->
          io:format("~ts\t~p\t~p\t~p\t~p~n", [City, Mn, Mx, Tot, Cnt])
      end,
      lists:sort(maps:to_list(Map))).

process_file(F, Acc) ->
    case io:get_line(F, "") of
        eof ->
            Acc;
        {error, _} ->
            Acc;
        Line0 ->
            Line = string:trim(Line0, trailing, "\n"),
            [City, TempStr] = string:split(Line, ";"),
            Temp = list_to_integer([C || C <- TempStr, C =/= $.]),
            Acc2 = maps:update_with(
                     City,
                     fun({Mn, Mx, Tot, Cnt}) ->
                         {minv(Mn, Temp), maxv(Mx, Temp), Tot + Temp, Cnt + 1}
                     end,
                     {Temp, Temp, Temp, 1},
                     Acc),
            process_file(F, Acc2)
    end.

minv(A, B) when A < B -> A;
minv(_, B) -> B.

maxv(A, B) when A > B -> A;
maxv(_, B) -> B.
