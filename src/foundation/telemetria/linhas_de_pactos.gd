## Formatação das linhas `encontro_pacto`, `pacto` e `vinculo_fim_run` (Schema 2) da Telemetria local
## (GDD telemetria-local.md R4-P; story telemetria-local/009).
##
## Garante:
## [br]- `encontro_pacto`: `indice_camara`, `especie`, `resultado` e `vida_restante`; se `resultado`
## não pertencer a `{pactuada, reafirmada, deixada, voltara, fugiu, abandonado}`, sai como está e
## registra `TL3` uma única vez (AC-TL-36);
## [br]- `pacto` (`pacto_registrado`): `especie` e `origem` (`primeiro`, `encontro` ou `chefe`, AC-TL-37);
## [br]- `vinculo_fim_run` (`vinculo_atualizado`): `especies` com `id`, `pontos_run`, `vinculo_pontos`,
## `nivel` e `subiu_nivel` (AC-TL-38).
class_name LinhasDePactos
extends RefCounted

const RESULTADOS_ENCONTRO_VALIDOS: PackedStringArray = [
	"pactuada",
	"reafirmada",
	"deixada",
	"voltara",
	"fugiu",
	"abandonado",
]

const ORIGENS_PACTO_VALIDAS: PackedStringArray = [
	"primeiro",
	"encontro",
	"chefe",
]


## Monta a linha `encontro_pacto` (R4-P, AC-TL-36).
static func montar_encontro_pacto(evento: EventoDoPasso, indice_camara_atual: int,
		avisos: RelatorDeAvisosTelemetria) -> Dictionary:
	var ind: Variant = evento.get("indice_camara")
	var indice_out: int = int(ind) if ind != null else indice_camara_atual
	var esp: Variant = evento.get("especie")
	if esp == null:
		esp = evento.get("especie_id")
	var esp_str: Variant = String(esp) if (esp != null and not String(esp).is_empty()) else null
	if esp_str == null and avisos != null:
		avisos.registrar_tl3(&"encontro_pacto", "especie")

	var res: Variant = evento.get("resultado")
	var res_str: Variant = String(res) if (res != null and not String(res).is_empty()) else null
	if res_str == null:
		if avisos != null:
			avisos.registrar_tl3(&"encontro_pacto", "resultado")
	elif not RESULTADOS_ENCONTRO_VALIDOS.has(String(res_str)):
		if avisos != null:
			avisos.registrar_tl3(&"encontro_pacto", "resultado_desconhecido")

	var vida: Variant = evento.get("vida_restante")
	if vida == null and avisos != null:
		avisos.registrar_tl3(&"encontro_pacto", "vida_restante")

	return {
		"indice_camara": indice_out,
		"especie": esp_str,
		"resultado": res_str,
		"vida_restante": int(vida) if vida != null else null,
	}


## Monta a linha `pacto` a partir de `pacto_registrado` ou `pacto` (R4-P, AC-TL-37).
static func montar_pacto(evento: EventoDoPasso, avisos: RelatorDeAvisosTelemetria) -> Dictionary:
	var esp: Variant = evento.get("especie")
	if esp == null:
		esp = evento.get("especie_id")
	var esp_str: Variant = String(esp) if (esp != null and not String(esp).is_empty()) else null
	if esp_str == null and avisos != null:
		avisos.registrar_tl3(&"pacto", "especie")

	var orig: Variant = evento.get("origem")
	var orig_str: Variant = String(orig) if (orig != null and not String(orig).is_empty()) else null
	if orig_str == null:
		if avisos != null:
			avisos.registrar_tl3(&"pacto", "origem")
	elif not ORIGENS_PACTO_VALIDAS.has(String(orig_str)):
		if avisos != null:
			avisos.registrar_tl3(&"pacto", "origem_desconhecida")

	return {
		"especie": esp_str,
		"origem": orig_str,
	}


## Monta a linha `vinculo_fim_run` a partir de `vinculo_atualizado` ou `vinculo_fim_run` (R4-P, AC-TL-38).
static func montar_vinculo_fim_run(evento: EventoDoPasso, avisos: RelatorDeAvisosTelemetria) -> Dictionary:
	var especies_ev: Variant = evento.get("especies")
	var lista_out: Array = []
	if especies_ev is Array:
		for item: Variant in especies_ev:
			if item is Dictionary:
				var d := item as Dictionary
				lista_out.append({
					"id": String(d.get("id", d.get("especie", ""))),
					"pontos_run": int(d.get("pontos_run", 0)),
					"vinculo_pontos": int(d.get("vinculo_pontos", 0)),
					"nivel": int(d.get("nivel", 1)),
					"subiu_nivel": bool(d.get("subiu_nivel", false)),
				})
	else:
		if avisos != null:
			avisos.registrar_tl3(&"vinculo_fim_run", "especies")
	return {
		"especies": lista_out,
	}
