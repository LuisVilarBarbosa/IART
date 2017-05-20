/*
camiao(Id, Autonomia, CargaMaxima).
pontoGrafo(Id, Long, Lat).
pontoInicial(Id).
pontoFinal(Id).
pontoAbastecimento(Id).
encomenda(Id, Volume, Valor, IdPontoEntrega, Cliente).
sucessor(IdPontoGrafo, IdSucessor, Custo).
*/

:- use_module(library(lists)).

:- load_files(dados1).

/* Pesquisa em profundidade */
pp(Ei,Ef,Custo,Caminho) :-
  pp(Ei,Ef,[Ei],L,Custo),
  reverse(L,Caminho).

pp(Ef,Ef,L,L,0).
pp(Ea,Ef,Lant,L,Custo) :-
  sucessor(Ea,Eseg,C),
  \+ member(Eseg,Lant),
  pp(Eseg,Ef,[Eseg|Lant],L,Custo2),
  Custo is Custo2 + C.


/* Pesquisa em largura */
custoTotal([_],0).
custoTotal([P1,P2],Custo) :-
  sucessor(P1,P2,Custo).
custoTotal([P1,P2|Ps],CustoTotal) :-
  sucessor(P1,P2,Custo),
  custoTotal([P2|Ps],CustoTotal2),
  CustoTotal is Custo + CustoTotal2.

pl(Ei,Ef,Custo,Caminho) :-
  pl([[Ei]],Ef,L),
  reverse(L,Caminho),
  custoTotal(Caminho,Custo).

pl([La|_],Ef,La) :- La=[Ef|_].
pl([La|OLs],Ef,L) :-
  La=[Ea|OEs],
  findall([Eseg|La],(sucessor(Ea,Eseg,_),\+ member(Eseg,OEs)),Lseg),
  append(OLs,Lseg,NL),
  pl(NL,Ef,L).


/* A* */
heuristica(IdPontoGrafo,Hseg) :-
  pontoFinal(IdPontoFinal),
  pontoGrafo(IdPontoFinal,Long1,Lat1),
  pontoGrafo(IdPontoGrafo,Long2,Lat2),
  Long is abs(Long2 - Long1),
  Lat is abs(Lat2 - Lat1),
  Hipotenusa is sqrt(Long * Long + Lat * Lat),
  Hseg is 40000 * Hipotenusa / 360.

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
  pp1([Ei],Ef,Hi,Bound,L)
  ;
  next_bound(NextBound),
  NextBound < 100000,
  idastarAux(Ei,Ef,L).

pp1([E|OEs],E,H,Bound,[E|OEs]) :- H =< Bound.
pp1([E|OEs],Ef,H,Bound,Sol) :-
  H =< Bound,
  sucessor(E,Esuc,_),
  \+ member(Esuc,OEs),
  heuristica(Esuc,Hsuc),
  pp1([Esuc,E|OEs],Ef,Hsuc,Bound,Sol).
pp1(_,_,H,Bound,_) :-
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
ordenaEncomendasDistanciaAux(_,[],_,[]).
ordenaEncomendasDistanciaAux(Ei,[Vol-Enc1|Encs],Algoritmo,[Custo-Vol-Enc1|Res]) :-
  (
    (Algoritmo = pp,pp(Ei,Enc1,Custo,Caminho));
    (Algoritmo = astar,astar(Ei,Enc1,Caminho,Custo));
    (Algoritmo = pl,pl(Ei,Enc1,Custo,Caminho));
    (Algoritmo = idastar,idastar(Ei,Enc1,Custo,Caminho))
  ),
  ordenaEncomendasDistanciaAux(Ei,Encs,Algoritmo,Res).

ordenaEncomendasDistancia(_,[],_,[]).
ordenaEncomendasDistancia(Ei,Encomendas,Algoritmo,[V-Ponto|Res]) :-
  ordenaEncomendasDistanciaAux(Ei,Encomendas,Algoritmo,MaisProximas),
  sort(MaisProximas,OrdMaisProximas),
  nth0(0,OrdMaisProximas,_-V-Ponto),
  delete(Encomendas,_-Ponto,Restantes),
  ordenaEncomendasDistancia(Ponto,Restantes,Algoritmo,Res).

encomendasCamiao([],[],_,_).
encomendasCamiao([Vol-IdP|Res],[IdP|OPs],CargaTotal,CargaMaxima) :-
  CargaTotal2 is CargaTotal + Vol,
  (
    CargaTotal2 =< CargaMaxima,
    encomendasCamiao(Res,OPs,CargaTotal2,CargaMaxima)
  );
  (
    CargaTotal2 > CargaMaxima,
    encomendasCamiao(Res,[IdP|OPs],CargaTotal,CargaMaxima)
  ).

todasEncomendas(Encs,Opcao,Algoritmo) :-
  findall(Volume-PontoGrafo,encomenda(_,Volume,_,PontoGrafo,_),Encomendas),
  pontoInicial(Ei),
  (
    (Opcao = maxEntregas,sort(Encomendas,Sorted));
    (Opcao = minDist,ordenaEncomendasDistancia(Ei,Encomendas,Algoritmo,Sorted))
  ),
  camiao(_,_,CargaMaxima),
  encomendasCamiao(Sorted,Encs,0,CargaMaxima).


todasBombas(Bombas) :-
  findall(Id,pontoAbastecimento(Id),Bombas).

bombaMaisPertoAux(_, _,[],[]).
bombaMaisPertoAux(pp,Ei,[E|Es],[C-E|Cs]) :-
  pp(Ei,E,C,_),
  bombaMaisPertoAux(pp,Ei,Es,Cs).
bombaMaisPertoAux(pl,Ei,[E|Es],[C-E|Cs]) :-
  pl(Ei,E,C,_),
  bombaMaisPertoAux(pl,Ei,Es,Cs).
bombaMaisPertoAux(astar,Ei,[E|Es],[CustoSemHeuristica-E|Cs]) :-
  astar(Ei,E,Caminho,_),
  custoTotal(Caminho,CustoSemHeuristica),
  bombaMaisPertoAux(astar,Ei,Es,Cs).
bombaMaisPertoAux(idastar,Ei,[E|Es],[CustoSemHeuristica-E|Cs]) :-
  idastar(Ei,E,_,Caminho),
  custoTotal(Caminho,CustoSemHeuristica),
  bombaMaisPertoAux(idastar,Ei,Es,Cs).

bombaMaisPerto(Algoritmo,Ei,Ef,Custo) :-
  todasBombas(Bombas),
  bombaMaisPertoAux(Algoritmo,Ei,Bombas,Custos),
  sort(Custos,Ord),
  nth0(0,Ord,Custo-Ef).


minimo([X-Custo-C],X,C,Custo) :- !.
minimo([X-A-C,Y-B-D|Res],N,E,Custo) :-
  (
    (A > B,minimo([Y-B-D|Res],N,E,Custo));
    minimo([X-A-C|Res],N,E,Custo)
  ).

calculaCaminhoAux(_,_,[],[]).
calculaCaminhoAux(Algoritmo,Ei,[E1|Es],[E1-Custo-Caminho|Rs]) :-
  (
    (Algoritmo = pp,pp(Ei,E1,Custo,Caminho));
    (Algoritmo = astar,astar(Ei,E1,Caminho,Custo));
    (Algoritmo = pl,pl(Ei,E1,Custo,Caminho));
    (Algoritmo = idastar,idastar(Ei,E1,Custo,Caminho))
  ),
  calculaCaminhoAux(Algoritmo,Ei,Es,Rs).

calculaCaminho(_,_,[],[],_).
calculaCaminho(Algoritmo,Ei,Encomendas,[Caminho|R],Autonomia) :-
  calculaCaminhoAux(Algoritmo,Ei,Encomendas,Resultado),
  minimo(Resultado,Min,Caminho,Custo),
  (
    Custo =< Autonomia,
    Autonomia2 is Autonomia - Custo,
    delete(Encomendas,Min,Resto),
    calculaCaminho(Algoritmo,Min,Resto,R,Autonomia2)
  );
  (
    Custo > Autonomia,
    camiao(_,AutonomiaInicial,_),
    bombaMaisPerto(Algoritmo,Ei,Ef,CustoBomba),
    (
      (AutonomiaInicial > CustoBomba,Ei \= Ef);
      (write('Caminho impossivel. Nao existe nenhuma bomba suficiente proxima.'),nl,!,fail)  % Necessario aumentar a autonomia do camião ou ter mais pontos de abastecimento.
    ),
    (
      (Algoritmo = pp,pp(Ei,Ef,_,Caminho));
      (Algoritmo = pl,pl(Ei,Ef,_,Caminho));
      (Algoritmo = astar,astar(Ei,Ef,Caminho,_));
      (Algoritmo = idastar,idastar(Ei,Ef,_,Caminho))
    ),
    calculaCaminho(Algoritmo,Ef,Encomendas,R,AutonomiaInicial)
  ).


eliminaRepetidosSeguidos([P1,P2],[P1,P2]) :- P1 \= P2.
eliminaRepetidosSeguidos([P,P],[P]).
eliminaRepetidosSeguidos([P1,P2|Ps],[P1|Res]) :-
  P1 \= P2,
  eliminaRepetidosSeguidos([P2|Ps],Res).
eliminaRepetidosSeguidos([P1,P1|Ps],Res) :-
  eliminaRepetidosSeguidos([P1|Ps],Res).

reset_timer :- statistics(walltime,_).
print_time :-
  statistics(walltime,[_,T]),
  write('Time: '),write(T),write('ms'),nl.


entregaEncomendas(Algoritmo,Opcao) :-
  reset_timer,
  todasEncomendas(Encomendas,Opcao,Algoritmo),
  write('Pontos de entrega: '),write(Encomendas),nl,
  camiao(_,Autonomia,_),
  pontoInicial(Ei),
  pontoFinal(Ef),
  calculaCaminho(Algoritmo,Ei,Encomendas,C,Autonomia),
  length(C,Val),
  nth1(Val,C,Ultima),
  length(Ultima,Val2),
  nth1(Val2,Ultima,UltimaEntrega),
  EncomendasF = [Ef],
  calculaCaminho(Algoritmo,UltimaEntrega,EncomendasF,Caminho,Autonomia),
  append(C,Caminho,CaminhoFinal),
  append(CaminhoFinal,CaminhoFinalFlat),
  eliminaRepetidosSeguidos(CaminhoFinalFlat,CaminhoLimpo),
  custoTotal(CaminhoLimpo,CustoFinal),
/*
  CustoFinal >= 300,
  CustoFinal =< 700,
*/
  print_time,
  write('Custo: '),write(CustoFinal),nl,
  write('Caminho: '),write(CaminhoFinal).
