:- use_module(library(lists)).
:- ensure_loaded('map.pl').
:- dynamic ([
        path/4,
        wumpus_pos/2, % because we can remove wumpus from map
        wumpus_was/2,
        answer_list/1
       ]).

main :-
    assert(answer_list([])),
    format("Start ~n", []),
    (start -> gold_search; % start never true, because next_step sooner or later return false
        gold_search), % but I left true case just in case 
    print_answer,
    format("End ~n", []).

gold_search :-
    gold_pos(GX, GY),
    start_pos(SX, SY),
    (path(_, _, GX, GY) -> backtrack_path(GX, GY, SX, SY, []);
    need_to_shoot).

backtrack_path(FromX, FromY, ToX, ToY, AnsList) :-
    path(BX, BY, FromX, FromY),
    % format string
    atomics_to_string(["From (", BX, ", ", BY, ") to (", FromX, ", ", FromY, ")"], "", Ans), 
    (wumpus_was(FromX, FromY) -> atomics_to_string(["Shoot from (", BX, ", ", BY, ") to (", FromX, ", ", FromY, ")"], "", Ans1),
        append(AnsList, [Ans, Ans1], ResList);
        append(AnsList, [Ans], ResList)),
    (ToX is BX, ToY is BY -> backtrack_end(ResList); 
    backtrack_path(BX, BY, ToX, ToY, ResList)).

need_to_shoot :-
    (wumpus_pos(WX, WY) -> 
    assert(wumpus_was(WX, WY)),
    retract(wumpus_pos(WX, WY)),
    retract(path(_, _, _, _)),
    (start -> gold_search; 
        gold_search);
    loose
    ).

backtrack_end(List) :-
    answer_list(AnsList),
    append(List, AnsList, ResList),
    append(ResList, ["Path complete"], FinalResList),
    retract(answer_list(_)),
    assert(answer_list(FinalResList)).

print_answer :-
    answer_list(Ans),
    reverse(Ans, Res),
    print_list(Res).

print_list([]).

print_list([H|T]) :-
    (H == "Path complete" -> print_list(T);
    format("~w ~n", [H]), print_list(T)).

loose :-
    format("Where is no path to gold! ~n", []).

start :-
    start_pos(X, Y),
    start_game(X, Y).

start_game(X, Y) :-
    (is_death(X, Y) -> format("You die at start ~n", []);
    create_game_tree(X, Y)
    ).

create_game_tree(X, Y) :-
    next_step_plus_x(X, Y);
    next_step_minus_x(X, Y);
    next_step_plus_y(X, Y);
    next_step_plus_y(X, Y).

next_step_plus_x(X, Y) :-
    plus_one(X, Xplus1),
    next_step(X, Y, Xplus1, Y).

next_step_minus_x(X, Y) :-
    minus_one(X, Xminus1),
    next_step(X, Y, Xminus1, Y).

next_step_plus_y(X, Y) :-
    plus_one(Y, Yplus1),
    next_step(X, Y, X, Yplus1).

next_step_minus_y(X, Y) :-
    minus_one(Y, Yminus1),
    next_step(X, Y, Yminus1, Y).

% physically hero make step
next_step(X1, Y1, X2, Y2) :-
    grid_size(XM, YM),
    \+ X2 is 0,
    \+ Y2 is 0,
    \+ X2 is XM + 1,
    \+ Y2 is YM + 1,
    add_path(X1, Y1, X2, Y2),
    create_game_tree(X2, Y2).

% but if this step is death we don't add it to tree
add_path(X1, Y1, X2, Y2) :-
    \+ is_death(X2, Y2),
    \+ path(X1, Y1, X2, Y2),
    \+ path(X2, Y2, X1, Y1),
    assert(path(X1, Y1, X2, Y2)).

is_death(X, Y) :-
    wumpus_pos(X, Y);
    pit_pos(X, Y).

plus_one(X1, X2) :-
    X2 is X1 +1.

minus_one(X1, X2) :-
    X2 is X1 - 1.