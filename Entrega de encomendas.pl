/*
camiao(Id, Autonomia, CargaMaxima).
pontoGrafo(Id, Long, Lat).
pontoInicial(Id).
pontoFinal(Id).
pontoAbastecimento(Id).
encomenda(Id, Volume, Valor, IdPontoEntrega, Cliente).
sucessor(IdPontoGrafo, IdSucessor, Custo).
*/

:- load_files(data).

:- use_module(library(lists)).


/* Depth-First Search */
df(Ei, Ef, Custo, Final):-
	df(Ei,Ef,[Ei],L, Custo),
	reverse(L, Final).

df(Ef,Ef,L,L, 0).
df(Ea,Ef,Lant,L,Custo) :-
	sucessor(Ea,Eseg,C),
	\+ member(Eseg,Lant),
	df(Eseg,Ef,[Eseg|Lant],L, Custo2),
	Custo is Custo2 + C.


/* Breath-First Search */
custoTotal([_], 0).
custoTotal([P1,P2],Custo):-
	sucessor(P1,P2,Custo).
custoTotal([P1,P2|Ps], CustoTotal):-
	sucessor(P1,P2, Custo),
	custoTotal([P2|Ps], CustoTotal2),
	CustoTotal is Custo + CustoTotal2.

bf(Ei, Ef, Custo, Final):-
	bf([[Ei]],Ef,L),
	reverse(L, Final),
	custoTotal(Final, Custo).

bf([La|_],Ef,La) :- La=[Ef|_].
bf([La|OLs],Ef,L) :-
	La=[Ea|OEs],
	findall([Eseg|La],(sucessor(Ea,Eseg,_),\+ member(Eseg,OEs)),Lseg),
	append(OLs,Lseg,NL),
	bf(NL,Ef,L).


/* A* */
heuristica(IdPontoGrafo,Hseg) :-
	pontoFinal(IdPontoFinal),
	pontoGrafo(IdPontoFinal,Long1,Lat1),
	pontoGrafo(IdPontoGrafo,Long2,Lat2),
	Long is abs(Long2 - Long1),
	Lat is abs(Lat2 - Lat1),
	Hseg is sqrt(Long*Long + Lat*Lat).

astar(PontoInicial, PontoFinal, S, C):-
    heuristica(PontoInicial, Hi),
    astar(_PontoInicial, PontoFinal, [Hi-[PontoInicial]-0], Si, C), reverse(Si, S).

astar(_PontoInicial, E, [C-[E|Cam]-_|_], [E|Cam], C):- !.

astar(_PontoInicial, PontoFinal, [_-[E|Cam]-G|R], S, C):-
    findall(F2-[E2|[E|Cam]]-G2,
        (sucessor(E, E2, C), G2 is G + C, heuristica(E2, H2), F2 is G2 + H2 ),
        Lsuc),
    append(R, Lsuc, L),
    sort(L, Lord),
    astar(_PontoInicial, PontoFinal, Lord, S, C).


/* IDA* */

% idastar( Start, Solution):
%   Perform IDA* search; Start is the start node, Solution is solution path

idastar(Ei, Ef, Custo, Caminho)  :-
  retract(next_bound(_)), fail     % Clear next_bound
  ;
  asserta(next_bound(0)),         % Initialise bound
  idastar0(Ei, Ef, Solution),
  reverse(Solution, Caminho),
  custoTotal(Caminho, Custo).
  
idastar0(Ei, Ef, Sol)  :-
  retract( next_bound( Bound)),     % Current bound
  asserta( next_bound( 99999)),     % Initialise next bound
  heuristica(Ei, F),                     % f-value of start node
  df1( [Ei],Ef, F, Bound, Sol)       % Find solution; if not, change bound
  ;
  next_bound( NextBound),
  NextBound < 99999,               % Bound finite
  idastar0( Ei, Ef, Sol).           % Try with new bound

% df( Path, F, Bound, Sol):
%  Perform depth-first search within Bound
%  Path is the path from start node so far (in reverse order)
%  F is the f-value of the current node, i.e. the head of Path

df1( [N | Ns], N, F, Bound, [N | Ns])  :-
  F =< Bound.                        % Succeed: solution found

df1( [N | Ns], Ef, F, Bound, Sol)  :-
  F =< Bound,                      % Node N within f-bound
  sucessor( N, N1, _), \+member( N1, Ns),   % Expand N
  heuristica(N1, F1),
  df1( [N1,N | Ns], Ef, F1, Bound, Sol).

df1( _, _,F, Bound, _)  :-
  F > Bound,                       % Beyond Bound
  update_next_bound( F),           % Just update next bound
  fail.                            % and fail

update_next_bound( F)  :-
  next_bound( Bound),
  Bound =< F, !                      % Do not change next bound
  ;
  retract( next_bound( Bound)), !,   % Lower next bound
  asserta( next_bound( F)).


/* Entrega de encomendas */
todasEncomendas_aux([],[],_,_).
todasEncomendas_aux([Vol-_|Res], Lista, Total, CargaMaxima):-
	Total2 is Total + Vol,
	Total2 > CargaMaxima,
	todasEncomendas_aux(Res, Lista, Total, CargaMaxima).
todasEncomendas_aux([Vol-Ind|Res], [Ind|Tail], Total, CargaMaxima):-
	Total2 is Total + Vol,
	Total2 =< CargaMaxima,
	todasEncomendas_aux(Res, Tail, Total2, CargaMaxima).
todasEncomendas_aux2(_,[],_,[]).
todasEncomendas_aux2(Ei, [Vol-Enc1|Encs], Algoritmo, [Custo-Vol-Enc1|Tail]):-
	(
		(Algoritmo = df, df(Ei, Enc1, Custo, Caminho));
		(Algoritmo = astar, astar(Ei, Enc1, Caminho, Custo));
		(Algoritmo = bf, bf(Ei, Enc1, Custo, Caminho));
		(Algoritmo = idastar, idastar(Ei, Enc1, Custo, Caminho))
	),
	todasEncomendas_aux2(Ei, Encs, Algoritmo, Tail).
	
auxiliar(_,[],_,[]).
auxiliar(Ei, Encomendas, Algoritmo, [V-Ponto|Tail]):-
	todasEncomendas_aux2(Ei, Encomendas, Algoritmo, MaisProximas),
	sort(MaisProximas, OrdMaisProximas),
	nth0(0, OrdMaisProximas, _-V-Ponto),
	delete(Encomendas,_-Ponto, Restantes),
	auxiliar(Ponto, Restantes, Algoritmo, Tail).
	
todasEncomendas(Final, Opcao, Algoritmo):-
	findall(Volume-PontoGrafo, encomenda(_,Volume,_,PontoGrafo,_), Encomendas),
	pontoInicial(Ei),
	(
		(Opcao = maxEntregas, sort(Encomendas, Temp));
		(Opcao = minDist, auxiliar(Ei, Encomendas, Algoritmo, Temp))
	),
	camiao(_,_,CargaMaxima),
	todasEncomendas_aux(Temp, Final, 0, CargaMaxima).


todasBombas(Bombas):-
	findall(Id, pontoAbastecimento(Id), Bombas).

bombaMaisPerto_aux(_, _,[],[]).	
bombaMaisPerto_aux(df, Ei, [B1|Bs], [C1-B1|Cs]):-
	df(Ei, B1, C1,_),
	bombaMaisPerto_aux(df, Ei, Bs, Cs).
bombaMaisPerto_aux(bf, Ei, [B1|Bs], [C1-B1|Cs]):-
	bf(Ei, B1, C1,_),
	bombaMaisPerto_aux(bf, Ei, Bs, Cs).
bombaMaisPerto_aux(astar, Ei, [B1|Bs], [CustoSemHeuristica-B1|Cs]):-
	astar(Ei, B1, Caminho, _),
	custoTotal(Caminho, CustoSemHeuristica),
	bombaMaisPerto_aux(astar, Ei, Bs, Cs).
bombaMaisPerto_aux(idastar, Ei, [B1|Bs], [CustoSemHeuristica-B1|Cs]):-
	idastar(Ei, B1, _, Caminho),
	custoTotal(Caminho, CustoSemHeuristica),
	bombaMaisPerto_aux(idastar, Ei, Bs, Cs).

bombaMaisPerto(Algoritmo, Ei, Ef, Custo):-
	todasBombas(Bombas),
	bombaMaisPerto_aux(Algoritmo, Ei, Bombas, Custos),
	sort(Custos, Ord),
	nth0(0, Ord, Custo-Ef).


minimo([X-Custo-C],X, C, Custo):- !.
minimo([X-A-C,Y-B-D|Tail], N, E, Custo):-
	(
		(A > B, minimo([Y-B-D|Tail], N, E, Custo));
		minimo([X-A-C|Tail], N, E, Custo)
	).

entregaEncomendas_aux(_,_, [], []).
entregaEncomendas_aux(Algoritmo, Ei,[E1|Es], [E1-Custo-Caminho|Rs]):-
	(
		(Algoritmo = df, df(Ei, E1, Custo, Caminho));
		(Algoritmo = astar, astar(Ei, E1, Caminho, Custo));
		(Algoritmo = bf, bf(Ei, E1, Custo, Caminho));
		(Algoritmo = idastar, idastar(Ei, E1, Custo, Caminho))
	),
	entregaEncomendas_aux(Algoritmo, Ei, Es, Rs).

entregaEncomendas_aux_2(_,_, [],[],_).
entregaEncomendas_aux_2(Algoritmo, Ei, Encomendas, [C|R], Autonomia):-
	entregaEncomendas_aux(Algoritmo, Ei,  Encomendas, Resultado),
	minimo(Resultado, Min, C, Custo),
	Custo =< Autonomia,
	Autonomia2 is Autonomia - Custo,
	delete(Encomendas, Min, Resto),
	entregaEncomendas_aux_2(Algoritmo,Min, Resto, R, Autonomia2).
entregaEncomendas_aux_2(Algoritmo, Ei, Encomendas, [Caminho2|R], Autonomia):-
	entregaEncomendas_aux(Algoritmo, Ei, Encomendas, Resultado),
	minimo(Resultado, _, _, Custo),
	Custo > Autonomia,
	camiao(_,AutonomiaInicial,_),
	bombaMaisPerto(Algoritmo, Ei, Ef, CustoBomba),
	(
		(AutonomiaInicial > CustoBomba, AutonomiaInicial > CustoBomba, Ei \= Ef);
		(write('Caminho impossivel'), nl, !, abort)
	),
	(
		(Algoritmo = df, df(Ei, Ef, _, Caminho2));
		(Algoritmo = astar, astar(Ei, Ef, Caminho2,_));
		(Algoritmo = bf, bf(Ei, Ef,_,Caminho2));
		(Algoritmo = idastar, idastar(Ei, Ef, _, Caminho2))
	),
	entregaEncomendas_aux_2(Algoritmo, Ef, Encomendas, R, AutonomiaInicial).


cleanList([P1,P2],[P1, P2]):- P1 \= P2.
cleanList([P,P], [P]).
cleanList([P1, P2|Ps], [P1|Tail]):-
	P1 \= P2,
	cleanList([P2|Ps], Tail).
cleanList([P1,P1|Ps], Tail):-
	cleanList([P1|Ps], Tail).


entregaEncomendas(Algoritmo, Opcao):-
	todasEncomendas(EncomendasTemp, Opcao, Algoritmo),
	sort(EncomendasTemp, Encomendas),
	write('Pontos de entrega: '), write(Encomendas),nl,
	camiao(_,Autonomia,_),
	pontoInicial(Ei),
	pontoFinal(Ef),
	entregaEncomendas_aux_2(Algoritmo, Ei, Encomendas, C, Autonomia),
	length(C, Val),
	nth1(Val, C, Ultima),
	length(Ultima, Val2),
	nth1(Val2, Ultima, UltimaEntrega),
	EncomendasF = [Ef],
	entregaEncomendas_aux_2(Algoritmo, UltimaEntrega, EncomendasF, Caminho, Autonomia),
	append(C, Caminho, Final), 
	append(Final, Ex),
	cleanList(Ex, Cleaned),
	custoTotal(Cleaned, CustoFinal),
	write('Custo: '), write(CustoFinal), nl,
	write('Caminho: '), write(Final).
