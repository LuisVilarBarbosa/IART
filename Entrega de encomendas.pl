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
df(Ei,Ef,Custo,Caminho) :-
	df(Ei,Ef,[Ei],L,Custo),
	reverse(L,Caminho).

df(Ef,Ef,L,L,0).
df(Ea,Ef,Lant,L,Custo) :-
	sucessor(Ea,Eseg,C),
	\+ member(Eseg,Lant),
	df(Eseg,Ef,[Eseg|Lant],L,Custo2),
	Custo is Custo2 + C.


/* Breath-First Search */
custoTotal([_],0).
custoTotal([P1,P2],Custo) :-
	sucessor(P1,P2,Custo).
custoTotal([P1,P2|Ps],CustoTotal) :-
	sucessor(P1,P2,Custo),
	custoTotal([P2|Ps],CustoTotal2),
	CustoTotal is Custo + CustoTotal2.

bf(Ei,Ef,Custo,Caminho) :-
	bf([[Ei]],Ef,L),
	reverse(L,Caminho),
	custoTotal(Caminho,Custo).

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
	Hseg is sqrt(Long * Long + Lat * Lat).

astar(PontoInicial,PontoFinal,Caminho,Custo) :-
    heuristica(PontoInicial,Hi),
    astar(PontoInicial, PontoFinal,[Hi-[PontoInicial]-0],L,Custo),
	reverse(L,Caminho).

astar(_PontoInicial,E,[C-[E|Cam]-_|_],[E|Cam],C) :- !.
astar(PontoInicial,PontoFinal,[_-[E|Cam]-G|R],S,C) :-
    findall(F2-[E2|[E|Cam]]-G2,
        (sucessor(E,E2,C),G2 is G + C,heuristica(E2,H2),F2 is G2 + H2),
        Lsuc),
    append(R,Lsuc,L),
    sort(L,Lord),
    astar(PontoInicial,PontoFinal,Lord,S,C).


/* IDA* */
idastar(Ei,Ef,Custo,Caminho) :-
    retract(next_bound(_)),
	fail
	;
    asserta(next_bound(0)),
    idastarAux(Ei,Ef,L),
    reverse(L,Caminho),
    custoTotal(Caminho,Custo).
  
idastarAux(Ei,Ef,L) :-
    retract(next_bound(Bound)),
    asserta(next_bound(100000)),
    heuristica(Ei,Hi),
    df1([Ei],Ef,Hi,Bound,L)
	;
    next_bound(NextBound),
    NextBound < 100000,
    idastarAux(Ei,Ef,L).

df1([E|OEs],E,H,Bound,[E|OEs]) :- H =< Bound.
df1([E|OEs],Ef,H,Bound,Sol) :-
    H =< Bound,
    sucessor(E,Esuc,_),\+ member(Esuc,OEs),
    heuristica(Esuc,Hsuc),
    df1([Esuc,E|OEs],Ef,Hsuc,Bound,Sol).
df1(_,_,H,Bound,_) :-
    H > Bound,
    update_next_bound(H),
    fail.
update_next_bound(H) :-
    next_bound(Bound),
    Bound =< H,
    !
    ;
    retract(next_bound(Bound)),
    !,
    asserta(next_bound(H)).


/* Entrega de encomendas */
todasEncomendas_aux([],[],_,_).
todasEncomendas_aux([Vol-_|Res],Lista,CargaTotal,CargaMaxima) :-
	CargaTotal2 is CargaTotal + Vol,
	CargaTotal2 > CargaMaxima,
	todasEncomendas_aux(Res,Lista,CargaTotal,CargaMaxima).
todasEncomendas_aux([Vol-IdP|Res],[IdP|OPs],CargaTotal, CargaMaxima) :-
	CargaTotal2 is CargaTotal + Vol,
	CargaTotal2 =< CargaMaxima,
	todasEncomendas_aux(Res,OPs,CargaTotal2,CargaMaxima).

todasEncomendas_aux2(_,[],_,[]).
todasEncomendas_aux2(Ei,[Vol-Enc1|Encs],Algoritmo,[Custo-Vol-Enc1|Res]) :-
	(
		(Algoritmo = df,df(Ei,Enc1,Custo,Caminho));
		(Algoritmo = astar,astar(Ei,Enc1,Caminho,Custo));
		(Algoritmo = bf,bf(Ei,Enc1,Custo,Caminho));
		(Algoritmo = idastar,idastar(Ei,Enc1,Custo,Caminho))
	),
	todasEncomendas_aux2(Ei,Encs,Algoritmo,Res).
	
auxiliar(_,[],_,[]).
auxiliar(Ei,Encomendas,Algoritmo,[V-Ponto|Res]) :-
	todasEncomendas_aux2(Ei,Encomendas,Algoritmo,MaisProximas),
	sort(MaisProximas,OrdMaisProximas),
	nth0(0,OrdMaisProximas,_-V-Ponto),
	delete(Encomendas,_-Ponto,Restantes),
	auxiliar(Ponto,Restantes,Algoritmo,Res).
	
todasEncomendas(Encs,Opcao,Algoritmo) :-
	findall(Volume-PontoGrafo,encomenda(_,Volume,_,PontoGrafo,_),Encomendas),
	pontoInicial(Ei),
	(
		(Opcao = maxEntregas,sort(Encomendas,Sorted));
		(Opcao = minDist,auxiliar(Ei,Encomendas,Algoritmo,Sorted))
	),
	camiao(_,_,CargaMaxima),
	todasEncomendas_aux(Sorted,Encs,0,CargaMaxima).


todasBombas(Bombas) :-
	findall(Id,pontoAbastecimento(Id),Bombas).

bombaMaisPerto_aux(_, _,[],[]).	
bombaMaisPerto_aux(df,Ei,[E|Es],[C-E|Cs]) :-
	df(Ei,E,C,_),
	bombaMaisPerto_aux(df,Ei,Es,Cs).
bombaMaisPerto_aux(bf,Ei,[E|Es],[C-E|Cs]) :-
	bf(Ei,E,C,_),
	bombaMaisPerto_aux(bf,Ei,Es,Cs).
bombaMaisPerto_aux(astar,Ei,[E|Es],[CustoSemHeuristica-E|Cs]) :-
	astar(Ei,E,Caminho,_),
	custoTotal(Caminho,CustoSemHeuristica),
	bombaMaisPerto_aux(astar,Ei,Es,Cs).
bombaMaisPerto_aux(idastar,Ei,[E|Es],[CustoSemHeuristica-E|Cs]) :-
	idastar(Ei,E,_,Caminho),
	custoTotal(Caminho,CustoSemHeuristica),
	bombaMaisPerto_aux(idastar,Ei,Es,Cs).

bombaMaisPerto(Algoritmo,Ei,Ef,Custo) :-
	todasBombas(Bombas),
	bombaMaisPerto_aux(Algoritmo,Ei,Bombas,Custos),
	sort(Custos,Ord),
	nth0(0,Ord,Custo-Ef).


minimo([X-Custo-C],X,C,Custo) :- !.
minimo([X-A-C,Y-B-D|Res],N,E,Custo) :-
	(
		(A > B,minimo([Y-B-D|Res],N,E,Custo));
		minimo([X-A-C|Res],N,E,Custo)
	).

entregaEncomendas_aux(_,_,[],[]).
entregaEncomendas_aux(Algoritmo,Ei,[E1|Es],[E1-Custo-Caminho|Rs]) :-
	(
		(Algoritmo = df,df(Ei,E1,Custo,Caminho));
		(Algoritmo = astar,astar(Ei,E1,Caminho,Custo));
		(Algoritmo = bf,bf(Ei,E1,Custo,Caminho));
		(Algoritmo = idastar,idastar(Ei,E1,Custo,Caminho))
	),
	entregaEncomendas_aux(Algoritmo,Ei,Es,Rs).

entregaEncomendas_aux_2(_,_,[],[],_).
entregaEncomendas_aux_2(Algoritmo,Ei,Encomendas,[C|R],Autonomia) :-
	entregaEncomendas_aux(Algoritmo,Ei,Encomendas,Resultado),
	minimo(Resultado,Min,C,Custo),
	Custo =< Autonomia,
	Autonomia2 is Autonomia - Custo,
	delete(Encomendas,Min,Resto),
	entregaEncomendas_aux_2(Algoritmo,Min,Resto,R,Autonomia2).
entregaEncomendas_aux_2(Algoritmo,Ei,Encomendas,[Caminho2|R],Autonomia) :-
	entregaEncomendas_aux(Algoritmo,Ei,Encomendas,Resultado),
	minimo(Resultado,_,_,Custo),
	Custo > Autonomia,
	camiao(_,AutonomiaInicial,_),
	bombaMaisPerto(Algoritmo,Ei,Ef,CustoBomba),
	(
		(AutonomiaInicial > CustoBomba,AutonomiaInicial > CustoBomba,Ei \= Ef);
		(write('Caminho impossivel'),nl,!,abort)
	),
	(
		(Algoritmo = df,df(Ei,Ef,_,Caminho2));
		(Algoritmo = bf,bf(Ei,Ef,_,Caminho2));
		(Algoritmo = astar,astar(Ei,Ef,Caminho2,_));
		(Algoritmo = idastar,idastar(Ei,Ef,_,Caminho2))
	),
	entregaEncomendas_aux_2(Algoritmo,Ef,Encomendas,R,AutonomiaInicial).


cleanList([P1,P2],[P1,P2]) :- P1 \= P2.
cleanList([P,P],[P]).
cleanList([P1,P2|Ps],[P1|Res]) :-
	P1 \= P2,
	cleanList([P2|Ps],Res).
cleanList([P1,P1|Ps],Res) :-
	cleanList([P1|Ps],Res).


entregaEncomendas(Algoritmo,Opcao) :-
	todasEncomendas(EncomendasTemp,Opcao,Algoritmo),
	sort(EncomendasTemp,Encomendas),
	write('Pontos de entrega: '),write(Encomendas),nl,
	camiao(_,Autonomia,_),
	pontoInicial(Ei),
	pontoFinal(Ef),
	entregaEncomendas_aux_2(Algoritmo,Ei,Encomendas,C,Autonomia),
	length(C,Val),
	nth1(Val,C,Ultima),
	length(Ultima,Val2),
	nth1(Val2,Ultima,UltimaEntrega),
	EncomendasF = [Ef],
	entregaEncomendas_aux_2(Algoritmo,UltimaEntrega,EncomendasF,Caminho,Autonomia),
	append(C,Caminho,CaminhoFinal),
	append(CaminhoFinal,CaminhoFinalFlat),
	cleanList(CaminhoFinalFlat,CaminhoLimpo),
	custoTotal(CaminhoLimpo,CustoFinal),
	write('Custo: '),write(CustoFinal),nl,
	write('Caminho: '),write(CaminhoFinal).
