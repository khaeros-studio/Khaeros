## Formatação das linhas `run_iniciada` e `run_encerrada` (Schema 2) da Telemetria local
## (GDD telemetria-local.md R4, R4-P, R12; stories telemetria-local/006 e 009).
##
## Garante:
## [br]- `run_iniciada` traz `seed` (texto), `impressao` (64 hex), `regiao` e `estado_inicial`
## com `arma`, `doutrina`, `oficina` (vazia no MVP), `dupla` (lista de ids de `CurseDef`,
## vazia fora de Pactos) e `pactos` (objeto com `especies` = lista de `{id, nivel}`,
## `encontro_pendente`, `primeiro_encontro_visto`, `runs_pactos_sem_encontro`, ou `null` fora de Pactos);
## [br]- `run_encerrada` traz o resumo da Run R7 / R7-P (os 10 campos base por nome, mais
## `desfecho_chefe` e `dupla` no Schema 2 = 12 campos), o `caminho` em ordem e
## `fragmentos_por_origem` (soma dos `delta > 0` de `saldo_mudou` por `origem` na run);
## [br]- qualquer campo obrigatório ausente vira `null` e registra `TL3` uma única vez por tipo (AC-TL-24).
class_name LinhasDeRun
extends RefCounted

const DOUTRINA_PACTOS: String = "pactos"

## Os 10 campos obrigatórios do resumo da Run R7.
const CAMPOS_RESUMO_10: PackedStringArray = [
	"motivo",
	"seed",
	"arma",
	"camaras_limpas",
	"bencoes_tomadas",
	"fragmentos_coletados",
	"bonus_vitoria",
	"total_fragmentos",
	"abates",
	"duracao_s",
]

## Os 12 campos do resumo ampliado da Run R7-P (Schema 2).
const CAMPOS_RESUMO_12: PackedStringArray = [
	"motivo",
	"seed",
	"arma",
	"camaras_limpas",
	"bencoes_tomadas",
	"fragmentos_coletados",
	"bonus_vitoria",
	"total_fragmentos",
	"abates",
	"duracao_s",
	"desfecho_chefe",
	"dupla",
]


## Monta o payload de `run_iniciada` (R4, R4-P, AC-TL-04, AC-TL-34).
static func montar_run_iniciada(evento: EventoDoPasso, avisos: RelatorDeAvisosTelemetria) -> Dictionary:
	var seed_txt: Variant = _ler_campo(evento, ["seed_texto", "seed"], avisos, &"run_iniciada", "seed")
	var impressao: Variant = _ler_campo(evento, ["impressao"], avisos, &"run_iniciada", "impressao")
	var regiao: Variant = _ler_campo(evento, ["regiao"], avisos, &"run_iniciada", "regiao")
	var est_bruto: Variant = _ler_campo(evento, ["estado_inicial"], avisos, &"run_iniciada", "estado_inicial")

	var estado_out: Variant = null
	if est_bruto is Dictionary:
		estado_out = normalizar_estado_inicial(est_bruto as Dictionary, avisos)

	return {
		"seed": String(seed_txt) if seed_txt != null else null,
		"impressao": String(impressao) if impressao != null else null,
		"regiao": String(regiao) if regiao != null else null,
		"estado_inicial": estado_out,
	}


## Normaliza `estado_inicial` para conter `arma`, `doutrina`, `oficina`, `dupla` e `pactos` (AC-TL-04, AC-TL-34).
static func normalizar_estado_inicial(est: Dictionary, avisos: RelatorDeAvisosTelemetria) -> Dictionary:
	var arma: Variant = est.get("arma", null)
	if arma == null and avisos != null:
		avisos.registrar_tl3(&"run_iniciada", "estado_inicial.arma")
	var doutrina: Variant = est.get("doutrina", null)
	if doutrina == null and avisos != null:
		avisos.registrar_tl3(&"run_iniciada", "estado_inicial.doutrina")

	var oficina: Array = []
	if est.has("oficina") and est["oficina"] is Array:
		oficina = (est["oficina"] as Array).duplicate(true)
	elif est.has("melhorias") and est["melhorias"] is Array:
		oficina = (est["melhorias"] as Array).duplicate(true)

	var eh_pactos := String(doutrina) == DOUTRINA_PACTOS
	var dupla_out: Array = []
	if eh_pactos and est.has("dupla") and est["dupla"] is Array:
		for item: Variant in est["dupla"]:
			dupla_out.append(String(item))

	var pactos_out: Variant = null
	var fonte_pactos: Variant = est.get("pactos", est.get("perfil_vinculo", null))
	if eh_pactos and fonte_pactos is Dictionary:
		var fp := fonte_pactos as Dictionary
		var especies_norm: Array = []
		var lista_esp: Variant = fp.get("especies", fp.get("especies_pactuadas", []))
		if lista_esp is Array:
			for esp: Variant in lista_esp:
				if esp is Dictionary:
					var ed := esp as Dictionary
					var id_esp: String = String(ed.get("id", ed.get("especie", "")))
					especies_norm.append({
						"id": id_esp,
						"nivel": int(ed.get("nivel", 1)),
					})
		pactos_out = {
			"especies": especies_norm,
			"encontro_pendente": fp.get("encontro_pendente", []),
			"primeiro_encontro_visto": bool(fp.get("primeiro_encontro_visto", false)),
			"runs_pactos_sem_encontro": int(fp.get("runs_pactos_sem_encontro", 0)),
		}

	return {
		"arma": String(arma) if arma != null else null,
		"doutrina": String(doutrina) if doutrina != null else null,
		"oficina": oficina,
		"dupla": dupla_out,
		"pactos": pactos_out,
	}


## Monta o payload de `run_encerrada` (R4, R4-P, AC-TL-11, AC-TL-35).
static func montar_run_encerrada(evento: EventoDoPasso, fragmentos_por_origem: Dictionary,
		caminho_acumulado: Array, avisos: RelatorDeAvisosTelemetria) -> Dictionary:
	var resumo_bruto: Variant = _ler_campo(evento, ["resumo"], avisos, &"run_encerrada", "resumo")
	var resumo_out: Dictionary = {}
	if resumo_bruto is Dictionary:
		var rb := resumo_bruto as Dictionary
		for campo: String in CAMPOS_RESUMO_10:
			if rb.has(campo):
				resumo_out[campo] = rb[campo]
			else:
				resumo_out[campo] = null
				if avisos != null:
					avisos.registrar_tl3(&"run_encerrada", "resumo." + campo)
		# Campos de Schema 2 (R7-P): desfecho_chefe e dupla
		resumo_out["desfecho_chefe"] = String(rb.get("desfecho_chefe", "nenhum"))
		var dupla_arr: Array = []
		if rb.has("dupla") and rb["dupla"] is Array:
			for item: Variant in rb["dupla"]:
				dupla_out_append(dupla_arr, item)
		resumo_out["dupla"] = dupla_arr
	else:
		for campo: String in CAMPOS_RESUMO_12:
			resumo_out[campo] = null

	var caminho_ev: Variant = evento.get("caminho")
	var caminho_final: Array = []
	if caminho_ev is Array and not (caminho_ev as Array).is_empty():
		caminho_final = (caminho_ev as Array).duplicate(true)
	else:
		caminho_final = caminho_acumulado.duplicate(true)

	var saida: Dictionary = resumo_out.duplicate(true)
	saida["resumo"] = resumo_out
	saida["caminho"] = caminho_final
	saida["fragmentos_por_origem"] = fragmentos_por_origem.duplicate(true)
	return saida


static func dupla_out_append(arr: Array, item: Variant) -> void:
	arr.append(String(item))


static func _ler_campo(ev: Object, nomes: Array[String], avisos: RelatorDeAvisosTelemetria,
		tipo_ev: StringName, nome_canonico: String) -> Variant:
	if ev != null:
		for n: String in nomes:
			var v: Variant = ev.get(n)
			if v != null:
				return v
	if avisos != null:
		avisos.registrar_tl3(tipo_ev, nome_canonico)
	return null
