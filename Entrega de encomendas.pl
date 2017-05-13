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

bombaMaisPerto_aux(_,[],[]).	
bombaMaisPerto_aux(Ei, [B1|Bs], [C1-B1|Cs]):-
	df(Ei, B1, C1,_),
	bombaMaisPerto_aux(Ei, Bs, Cs).
	
	
bombaMaisPerto(Ei, Ef):-
	todasBombas(Bombas),
	bombaMaisPerto_aux(Ei, Bombas, Custos),
	sort(Custos, Ord),
	nth0(0, Ord, _-Ef).


heuristica(maxEntregas,IdPontoGrafo,Hseg) :-
	pontoFinal(IdPontoFinal),
	pontoGrafo(IdPontoFinal,Long1,Lat1),
	pontoGrafo(IdPontoGrafo,Long2,Lat2),
	Hseg = max(abs(Long2-Long1),abs(Lat2-Lat1)).

heuristica(minDist,IdPontoGrafo,Hseg) :-
	pontoFinal(IdPontoFinal),
	pontoGrafo(IdPontoFinal,Long1,Lat1),
	pontoGrafo(IdPontoGrafo,Long2,Lat2),
	Hseg = min(abs(Long2-Long1),abs(Lat2-Lat1)).

heuristica(ambos,IdPontoGrafo,Hseg) :-
	heuristica(maxEntregas,IdPontoGrafo,Hseg1),
	heuristica(minDist,IdPontoGrafo,Hseg2),
	Hseg = (Hseg1 + Hseg2) / 2.

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
bf :-
	pontoInicial(Ei),
	pontoFinal(Ef),
	bf([[Ei]],Ef,L),
	reverse(L, Final),
	write(Final).

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
a_star(Heuristica) :- pontoInicial(Ei),pontoFinal(Ef),Gi=0,heuristica(Heuristica,Ei,Hi),Fi=Hi,
	CamIni=[Fi,Ei\Gi],a_star(Heuristica,[CamIni],Ef,Res),write(Res).

a_star(_Heuristica,[Cam1|_OCams],Ef,Res) :- Cam1=[_,Ef\_|_OEs],Res=Cam1.
a_star(Heuristica,[Cam1|OCams],Ef,Res) :- Cam1=[_,Ea\Ga|OEs],
	findall([[[Fseg,Eseg\Gseg]|Ea\Ga]|OEs],
		(sucessor(Ea,Eseg,G),\+ member(Eseg\_,OEs),Gseg is G + Ga,
		heuristica(Heuristica,Eseg,Hseg),Fseg is Hseg + Gseg),NovosCams),
	append(NovosCams,OCams,NCam),sort(NCam,NCamOrd),
	a_star(Heuristica,NCamOrd,Ef,Res).

/* Minimax */
limite(1000).	% be careful with this limit
minimax :- pontoInicial(Ei), minimax(Ei).

minimax(Ea) :- minimax(Ea,1,_Max,Jogada,_V),write(Jogada).

minimax(Ea,Prof,Max,Jogada,V) :- \+ limite(Prof),
	findall(Eseg,sucessor(Ea,Max,Eseg),Lseg),
	MenorV is -9999,
	maxValue(Lseg,Prof,_,MenorV,Jogada,V).

minimax(Ea,_,_,Ea,V) :- merito(Ea,V).

maxValue([],_,ME,MV,ME,MV).
maxValue([E1|OEs],Prof,ME,MV,Eres,Vres) :-
	Prof1 is Prof + 1,
	minimax(E1,Prof1,_Min,_,V1),
	((V1 > MV,MVAux = V1,MEAux = E1)
	;MVAux = MV, MEAux = ME),
	maxValue(OEs,Prof,MEAux,MVAux,Eres,Vres).

minimo([X-Custo-C],X, C, Custo):- !.
minimo([X-A-C,Y-B-D|Tail], N, E, Custo):-
	( A > B ->
		minimo([Y-B-D|Tail], N, E, Custo);
		minimo([X-A-C|Tail], N, E, Custo)).

		
	
entregaEncomendas_df_aux(_, [], []).
entregaEncomendas_df_aux(Ei,[E1|Es], [E1-Custo-Caminho|Rs]):-
	df(Ei, E1, Custo, Caminho),	
	entregaEncomendas_df_aux(Ei, Es, Rs).



entregaEncomendas_df_aux_2(_, [],[],_).

entregaEncomendas_df_aux_2(Ei, Encomendas, [Caminho2|R], Autonomia):-
	entregaEncomendas_df_aux(Ei, Encomendas, Resultado),
	minimo(Resultado, Min, _, Custo),
	Custo > Autonomia,
	camiao(_,AutonomiaInicial,_),
	bombaMaisPerto(Ei, Ef),
	df(Ei, Ef, Custo2, Caminho2),
	write(Ef), nl,
	entregaEncomendas_df_aux_2(Ef, Encomendas, R, AutonomiaInicial).
	
entregaEncomendas_df_aux_2(Ei, Encomendas, [C|R], Autonomia):-
	entregaEncomendas_df_aux(Ei, Encomendas, Resultado),
	minimo(Resultado, Min, C, Custo),
	Custo < Autonomia,
	Autonomia2 is Autonomia - Custo,
	delete(Encomendas, Min, Resto),
	entregaEncomendas_df_aux_2(Min, Resto, R, Autonomia).
	
entregaEncomendas_df(Final):-
	todasEncomendas(EncomendasTemp),
	sort(EncomendasTemp, Encomendas),
	camiao(_,Autonomia,_),
	pontoInicial(Ei),
	pontoFinal(Ef),
	entregaEncomendas_df_aux_2(Ei, Encomendas, C, Autonomia),
	length(C, Val),
	nth1(Val, C, Ultima),
	length(Ultima, Val2),
	nth1(Val2, Ultima, Inicial),
	df(Inicial, Ef, _, Caminho),
	append(C, [Caminho], Final), write(Final).
	