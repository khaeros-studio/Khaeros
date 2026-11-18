## Formatação das linhas `oferta`, `oferta_trocada`, `bencao`, `porta` e `morte` da Telemetria local
## (GDD telemetria-local.md R4; story telemetria-local/008).
##
## Garante:
## [br]- `oferta` (`oferta_aberta`): `indice_camara`, `cartas` (`[{id, raridade}, ...]`) e `trocas`;
## [br]- `oferta_trocada`: `cartas` e `trocas` (restantes);
## [br]- `bencao` (`bencao_tomada`): `id`, `raridade` e `trocas_restantes`;
## [br]- `porta` (`porta_escolhida`): `indice_camara`, `tipo` e `opcoes`;
## [br]- `morte` (`jogador_morreu`): `indice`, `causa` (`{tipo_inimigo, ataque}` quando fornecidos pelo
## Combate, ou `null` **sem `TL3`** quando omitidos, AC-TL-10) e `vida_max`.
class_name LinhasDeEventos
extends RefCounted


## Monta a linha `oferta` a partir de `EvOfertaAberta` ou evento equivalente (AC-TL-08).
static func montar_oferta(evento: EventoDoPasso, indice_camara_atual: int,
		avisos: RelatorDeAvisosTelemetria) -> Dictionary:
	var ind: Variant = evento.get("indice_camara")
	var indice_out: int = int(ind) if ind != null else indice_camara_atual
	var cartas := _extrair_cartas(evento, &"oferta", avisos)
	var trocas: Variant = evento.get("trocas")
	if trocas == null and avisos != null:
		avisos.registrar_tl3(&"oferta", "trocas")
	return {
		"indice_camara": indice_out,
		"cartas": cartas,
		"trocas": int(trocas) if trocas != null else null,
	}


## Monta a linha `oferta_trocada` a partir de `EvOfertaTrocada` ou evento equivalente (AC-TL-08).
static func montar_oferta_trocada(evento: EventoDoPasso, avisos: RelatorDeAvisosTelemetria) -> Dictionary:
	var cartas := _extrair_cartas(evento, &"oferta_trocada", avisos)
	var trocas: Variant = evento.get("trocas")
	if trocas == null and avisos != null:
		avisos.registrar_tl3(&"oferta_trocada", "trocas")
	return {
		"cartas": cartas,
		"trocas": int(trocas) if trocas != null else null,
	}


## Monta a linha `bencao` a partir de `EvBencaoTomada` ou evento equivalente (AC-TL-08).
static func montar_bencao(evento: EventoDoPasso, ultimas_trocas: int,
		avisos: RelatorDeAvisosTelemetria) -> Dictionary:
	var id_val: Variant = evento.get("id")
	if id_val == null or String(id_val).is_empty():
		id_val = null
		if avisos != null:
			avisos.registrar_tl3(&"bencao", "id")
	var rar_val: Variant = evento.get("raridade")
	if rar_val == null and avisos != null:
		avisos.registrar_tl3(&"bencao", "raridade")
	var tr_val: Variant = evento.get("trocas_restantes")
	var trocas_out: int = int(tr_val) if tr_val != null else ultimas_trocas
	return {
		"id": String(id_val) if id_val != null else null,
		"raridade": rar_val,
		"trocas_restantes": trocas_out,
	}


## Monta a linha `porta` a partir de `EvPortaEscolhida` ou evento equivalente (AC-TL-09).
static func montar_porta(evento: EventoDoPasso, indice_camara_atual: int,
		avisos: RelatorDeAvisosTelemetria) -> Dictionary:
	var ind: Variant = evento.get("indice_camara")
	var indice_out: int = int(ind) if ind != null else indice_camara_atual
	var tipo_val: Variant = evento.get("tipo_escolhido")
	if tipo_val == null:
		tipo_val = evento.get("tipo_porta")
	if tipo_val == null or String(tipo_val).is_empty():
		tipo_val = null
		if avisos != null:
			avisos.registrar_tl3(&"porta", "tipo")
	var opcoes_val: Variant = evento.get("opcoes")
	var opcoes_out: Variant = null
	if opcoes_val is Array:
		var arr: Array = []
		for op: Variant in opcoes_val:
			arr.append(String(op))
		opcoes_out = arr
	else:
		if avisos != null:
			avisos.registrar_tl3(&"porta", "opcoes")
	return {
		"indice_camara": indice_out,
		"tipo": String(tipo_val) if tipo_val != null else null,
		"opcoes": opcoes_out,
	}


## Monta a linha `morte` a partir de `EvJogadorMorreu` ou evento equivalente (AC-TL-10).
## Se `causa_tipo_inimigo` e `causa_ataque` não forem fornecidos pelo Combate, `causa` sai `null` **sem `TL3`**.
static func montar_morte(evento: EventoDoPasso, indice_camara_atual: int,
		vida_max_atual: int) -> Dictionary:
	var ind_ev: Variant = evento.get("indice_camara")
	if ind_ev == null:
		ind_ev = evento.get("indice")
	var indice_out: int = int(ind_ev) if (ind_ev != null and int(ind_ev) >= 0) else indice_camara_atual

	var vmax_ev: Variant = evento.get("vida_max")
	var vmax_out: int = int(vmax_ev) if (vmax_ev != null and int(vmax_ev) > 0) else vida_max_atual

	var causa_out: Variant = null
	var causa_dict: Variant = evento.get("causa")
	if causa_dict is Dictionary and not (causa_dict as Dictionary).is_empty():
		var cd := causa_dict as Dictionary
		causa_out = {
			"tipo_inimigo": String(cd.get("tipo_inimigo", "")),
			"ataque": String(cd.get("ataque", "")),
		}
	else:
		var t_ini: Variant = evento.get("causa_tipo_inimigo")
		var t_atq: Variant = evento.get("causa_ataque")
		if (t_ini != null and not String(t_ini).is_empty()) or (t_atq != null and not String(t_atq).is_empty()):
			causa_out = {
				"tipo_inimigo": String(t_ini) if t_ini != null else null,
				"ataque": String(t_atq) if t_atq != null else null,
			}

	return {
		"indice": indice_out,
		"causa": causa_out,
		"vida_max": vmax_out,
	}


static func _extrair_cartas(evento: EventoDoPasso, tipo_linha: StringName,
		avisos: RelatorDeAvisosTelemetria) -> Variant:
	var cartas_ev: Variant = evento.get("cartas")
	if cartas_ev is Array:
		var out: Array = []
		for c: Variant in cartas_ev:
			if c is Dictionary:
				var cd := c as Dictionary
				out.append({"id": String(cd.get("id", "")), "raridade": cd.get("raridade", 0)})
		return out
	var ids_ev: Variant = evento.get("ids")
	var rars_ev: Variant = evento.get("raridades")
	if ids_ev is Array and rars_ev is Array:
		var ids := ids_ev as Array
		var rars := rars_ev as Array
		var n := mini(ids.size(), rars.size())
		var out: Array = []
		for i in n:
			out.append({"id": String(ids[i]), "raridade": rars[i]})
		return out
	if avisos != null:
		avisos.registrar_tl3(tipo_linha, "cartas")
	return null
