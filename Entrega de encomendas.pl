camiao(Id, Autonomia, CargaMaxima).
pontoGrafo(Id, Long, Lat).
pontoInicial(Id).
pontoFinal(Id).
pontoAbastecimento(Id).
encomenda(Id, Volume, Valor, IdPontoEntrega, Cliente).
sucessor(IdPontoGrafo, IdSucessor, Custo).

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
