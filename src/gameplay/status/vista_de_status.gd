class_name VistaDeStatus
extends RefCounted
## Adaptador puro de consulta de status para HUD/VFX (`design/gdd/efeitos-de-status.md` R8;
## ADR-0011 §8, Story 006): lê `estado(inimigo_id)` e devolve os sinais visuais ativos
## (até 3 por inimigo em condições normais, ou reduzido a 1 sinal — o de maior acúmulo —
## quando mais de 9 inimigos estão simultaneamente marcados na câmara).

const LIMIAR_INIMIGOS_MARCADOS: int = 9


## Devolve os sinais visuais para `inimigo_id`: lista ordenada de dicionários
## `{id: StringName, acumulos: int, restante: int}` (máx. 3; ou máx. 1 quando
## `total_inimigos_marcados > 9`).
static func sinais_visuais(est: Dictionary, total_inimigos_marcados: int = 1) -> Array[Dictionary]:
	var ativos: Array[Dictionary] = []
	var s: Dictionary = est.get(&"sangramento", {})
	var s_rest: int = int(s.get(&"restante", 0))
	var s_acum: int = int(s.get(&"acumulos", 0))
	if s_rest > 0 and s_acum > 0:
		ativos.append({&"id": &"sangramento", &"acumulos": s_acum, &"restante": s_rest})

	var q: Dictionary = est.get(&"queimadura", {})
	var q_rest: int = int(q.get(&"restante", 0))
	var q_acum: int = int(q.get(&"acumulos", 0))
	if q_rest > 0 and q_acum > 0:
		ativos.append({&"id": &"queimadura", &"acumulos": q_acum, &"restante": q_rest})

	var a: Dictionary = est.get(&"abalo", {})
	var a_rest: int = int(a.get(&"restante", 0))
	var a_ativo: bool = bool(a.get(&"ativo", false))
	if a_ativo and a_rest > 0:
		ativos.append({&"id": &"abalo", &"acumulos": 1, &"restante": a_rest})

	if ativos.size() <= 1 or total_inimigos_marcados <= LIMIAR_INIMIGOS_MARCADOS:
		return ativos

	# Redução sob carga (> 9 inimigos marcados): mantém apenas o de maior acúmulo
	# (desempate por maior restante, depois ordem fixa sangramento -> queimadura -> abalo).
	var melhor: Dictionary = ativos[0]
	for i in range(1, ativos.size()):
		var cand: Dictionary = ativos[i]
		var c_ac: int = int(cand[&"acumulos"])
		var m_ac: int = int(melhor[&"acumulos"])
		if c_ac > m_ac or (c_ac == m_ac and int(cand[&"restante"]) > int(melhor[&"restante"])):
			melhor = cand
	return [melhor]
