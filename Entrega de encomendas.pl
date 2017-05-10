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
df :-
	pontoInicial(Ei),
	pontoFinal(Ef),
	df(Ei,Ef,[Ei],L),
	write(L).

df(Ef,Ef,L,L).
df(Ea,Ef,Lant,L) :-
	sucessor(Ea,Eseg,_),
	\+ member(Eseg,Lant),
	df(Eseg,Ef,[Eseg|Lant],L).

/* Breath-First Search */
bf :-
	pontoInicial(Ei),
	pontoFinal(Ef),
	bf([[Ei]],Ef,L),
	write(L).

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
	CamIni=[Fi,Ei\Gi],a_star([CamIni],Ef,Res),write(Res).

a_star(_Heuristica,[Cam1|_OCams],Ef,Res) :- Cam1=[_,Ef\_|_OEs],Res=Cam1.
a_star(Heuristica,[Cam1|OCams],Ef,Res) :- Cam1=[_,Ea\Ga|OEs],
	findall([[[Fseg,Eseg\Gseg]|Ea\Ga]|OEs],
		sucessor(Ea,Eseg,G),\+ member(Eseg\_,OEs),Gseg is G + Ga,
		(heuristica(Heuristica,Eseg,Hseg),Fseg is Hseg + Gseg),NovosCams),
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
