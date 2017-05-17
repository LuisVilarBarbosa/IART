/*
camiao(Id, Autonomia, CargaMaxima).
pontoGrafo(Id, Long, Lat).
pontoInicial(Id).
pontoFinal(Id).
pontoAbastecimento(Id).
encomenda(Id, Volume, Valor, IdPontoEntrega, Cliente).
sucessor(IdPontoGrafo, IdSucessor, Custo).
*/
:- load_files('DataGenerator/data.txt').
:- use_module(library(lists)).
todasEncomendas_aux([],[],_,_).
todasEncomendas_aux([Vol-_|Res], Lista, Total, CargaMaxima):-
	Total2 is Total + Vol,
	Total2 > CargaMaxima,
	todasEncomendas_aux(Res, Lista, Total, CargaMaxima).
todasEncomendas_aux([Vol-Ind|Res], [Ind|Tail], Total, CargaMaxima):-
	Total2 is Total + Vol,
	Total2 =< CargaMaxima,
	todasEncomendas_aux(Res, Tail, Total2, CargaMaxima).

todasEncomendas(Final):-
	findall(Volume-PontoGrafo, encomenda(_,Volume,_,PontoGrafo,_), Encomendas),
	sort(Encomendas, Temp),
	reverse(Temp, Ord),
	camiao(_,_,CargaMaxima),
	todasEncomendas_aux(Ord, Final, 0, CargaMaxima).

todasBombas(Bombas):-
	findall(Id, pontoAbastecimento(Id), Bombas).

bombaMaisPerto_aux(_,_Heuristica, _,[],[]).	
bombaMaisPerto_aux(df,_Heuristica, Ei, [B1|Bs], [C1-B1|Cs]):-
	df(Ei, B1, C1,_),
	bombaMaisPerto_aux(df, _Heuristica, Ei, Bs, Cs).
bombaMaisPerto_aux(bf,_Heuristica, Ei, [B1|Bs], [C1-B1|Cs]):-
	bf(Ei, B1, C1,_),
	bombaMaisPerto_aux(bf, _Heuristica, Ei, Bs, Cs).
bombaMaisPerto_aux(astar, Heuristica, Ei, [B1|Bs], [CustoSemHeuristica-B1|Cs]):-
	astar(Ei, B1, Heuristica, Caminho, _),
	custoTotal(Caminho, CustoSemHeuristica),
	bombaMaisPerto_aux(astar, Heuristica, Ei, Bs, Cs).

	

bombaMaisPerto(Algoritmo, Heuristica, Ei, Ef, Custo):-
	todasBombas(Bombas),
	bombaMaisPerto_aux(Algoritmo, Heuristica, Ei, Bombas, Custos),
	sort(Custos, Ord),
	nth0(0, Ord, Custo-Ef).


heuristica(maxEntregas,IdPontoGrafo,Hseg) :-
	pontoFinal(IdPontoFinal),
	pontoGrafo(IdPontoFinal,Long1,Lat1),
	pontoGrafo(IdPontoGrafo,Long2,Lat2),
	Hseg is max(abs(Long2-Long1),abs(Lat2-Lat1)).

heuristica(minDist,IdPontoGrafo,Hseg) :-
	pontoFinal(IdPontoFinal),
	pontoGrafo(IdPontoFinal,Long1,Lat1),
	pontoGrafo(IdPontoGrafo,Long2,Lat2),
	Hseg is min(abs(Long2-Long1),abs(Lat2-Lat1)).

heuristica(ambos,IdPontoGrafo,Hseg) :-
	heuristica(maxEntregas,IdPontoGrafo,Hseg1),
	heuristica(minDist,IdPontoGrafo,Hseg2),
	Hseg is (Hseg1 + Hseg2) / 2.

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
custoTotal([_], 0).
custoTotal([P1,P2],Custo):-
	sucessor(P1,P2,Custo).
custoTotal([P1,P2|Ps], CustoTotal):-
	sucessor(P1,P2, Custo),
	custoTotal([P2|Ps], CustoTotal2),
	CustoTotal is Custo + CustoTotal2.
/* Breath-First Search */
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

/* Branch and bound */
/* Iterative deepning */

/* Hill climbing */
numIteracoes(1000).	% be careful with this limit

hc :- solInicial(SolI),hc(SolI,1,Sol),write(Sol).
hc(Sol,N,Sol) :- numIteracoes(N).
hc(Sol,N,SolF) :- merito(Sol,V),
	sucessor(Sol,Solseg),
	merito(Solseg,Vseg), Vseg > V,
	N1 is N + 1, hc(Solseg,N1,SolF).
hc(Sol,_,Sol).

/* A* */
astar(PontoInicial, PontoFinal, Heuristica, S, C):-
    heuristica(Heuristica, PontoInicial, Hi),
    astar(_PontoInicial, PontoFinal,Heuristica, [Hi-[PontoInicial]-0], Si, C), reverse(Si, S).

astar(_PontoInicial, E, _Heuristica,[C-[E|Cam]-_|_], [E|Cam], C):- !.

astar(_PontoInicial, PontoFinal, Heuristica, [_-[E|Cam]-G|R], S, C):-
    findall(F2-[E2|[E|Cam]]-G2,
        (sucessor(E, E2, C), G2 is G + C, heuristica(Heuristica,E2, H2), F2 is G2 + H2 ),
        Lsuc),
    append(R, Lsuc, L),
    sort(L, Lord),
    astar(_PontoInicial, PontoFinal, Heuristica,Lord, S, C).

minimo([X-Custo-C],X, C, Custo):- !.
minimo([X-A-C,Y-B-D|Tail], N, E, Custo):-
	( A > B ->
		minimo([Y-B-D|Tail], N, E, Custo);
		minimo([X-A-C|Tail], N, E, Custo)).

		
	
entregaEncomendas_aux(_,_,_, [], []).
entregaEncomendas_aux(Algoritmo, Heuristica, Ei,[E1|Es], [E1-Custo-Caminho|Rs]):-
	((Algoritmo = df, df(Ei, E1, Custo, Caminho));(Algoritmo = astar, astar(Ei, E1, Heuristica, Caminho, Custo));(Algoritmo = bf, bf(Ei, E1, Custo, Caminho))),
	entregaEncomendas_aux(Algoritmo, Heuristica, Ei, Es, Rs).



entregaEncomendas_aux_2(_,_,_, [],[],_).

entregaEncomendas_aux_2(Algoritmo, Heuristica, Ei, Encomendas, [C|R], Autonomia):-
	entregaEncomendas_aux(Algoritmo, Heuristica, Ei,  Encomendas, Resultado),
	minimo(Resultado, Min, C, Custo),
	Custo =< Autonomia,
	Autonomia2 is Autonomia - Custo,
	delete(Encomendas, Min, Resto),
	entregaEncomendas_aux_2(Algoritmo,Heuristica,Min, Resto, R, Autonomia2).

entregaEncomendas_aux_2(Algoritmo, Heuristica, Ei, Encomendas, [Caminho2|R], Autonomia):-
	entregaEncomendas_aux(Algoritmo, Heuristica, Ei, Encomendas, Resultado),
	minimo(Resultado, _, _, Custo),
	Custo > Autonomia,
	camiao(_,AutonomiaInicial,_),
	bombaMaisPerto(Algoritmo, Heuristica,Ei, Ef, CustoBomba),
	(AutonomiaInicial > CustoBomba ->
	(AutonomiaInicial > CustoBomba, Ei \= Ef);(write('Caminho impossivel'), nl, !, abort)),
	((Algoritmo = df, df(Ei, Ef, _, Caminho2));(Algoritmo = astar, astar(Ei, Ef, Heuristica, Caminho2,_)); (Algoritmo = bf, bf(Ei, Ef,_,Caminho2))),
	entregaEncomendas_aux_2(Algoritmo, Heuristica, Ef, Encomendas, R, AutonomiaInicial).
	
entregaEncomendas(astar, Heuristica):-
	entregaEncomendas_Geral(astar, Heuristica).
entregaEncomendas(df):-
	entregaEncomendas_Geral(df, _).
entregaEncomendas(bf):-
	entregaEncomendas_Geral(bf, _).

cleanList([P1,P2],[P1, P2]):- P1 \= P2.
cleanList([P,P], [P]).
cleanList([P1, P2|Ps], [P1|Tail]):-
	P1 \= P2,
	cleanList([P2|Ps], Tail).
cleanList([P1,P1|Ps], Tail):-
	cleanList([P1|Ps], Tail).
	
entregaEncomendas_Geral(Algoritmo, Heuristica):-
	todasEncomendas(EncomendasTemp),
	sort(EncomendasTemp, Encomendas),
	camiao(_,Autonomia,_),
	pontoInicial(Ei),
	pontoFinal(Ef),
	entregaEncomendas_aux_2(Algoritmo, Heuristica, Ei, Encomendas, C, Autonomia),
	length(C, Val),
	nth1(Val, C, Ultima),
	length(Ultima, Val2),
	nth1(Val2, Ultima, UltimaEntrega),
	EncomendasF = [Ef],
	entregaEncomendas_aux_2(Algoritmo, Heuristica, UltimaEntrega, EncomendasF, Caminho, Autonomia),
	append(C, Caminho, Final), 
	append(Final, Ex),
	cleanList(Ex, Cleaned),
	custoTotal(Cleaned, CustoFinal),
	write('Custo: '), write(CustoFinal), nl,
	write('Caminho: '), write(Final).
	