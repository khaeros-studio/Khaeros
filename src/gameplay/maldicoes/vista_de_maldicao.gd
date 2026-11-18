class_name VistaDeMaldicao
extends RefCounted
## Vista imutável da apresentação de Maldições: fio de vínculo (curvo / tensionado tracejado / estourado),
## marca do Virote e ganchos de áudio `sfx_maldicao_*` (máx. 1 por gancho por passo;
## GDD maldicoes.md §Visual/Audio Requirements ML-V1–ML-V5, ML-A1; ADR-0011, ADR-0016, ADR-0017).

enum EstadoFio {
	OCULTO,
	CURVO_NORMAL,
	TENSIONADO_TRACEJADO,
	ESTOURADO_PULSANDO,
}

const COR_TINTA_HEX: String = "#0D0E14"
const COR_OSSO_HEX: String = "#E6DFCF"
const COR_OSSO_AMARRAS_HEX: String = "#CFC6B4"

const GANCHO_ATAQUE: StringName = &"sfx_maldicao_ataque"
const GANCHO_CHAMADO_SALTO: StringName = &"sfx_maldicao_chamado_salto"
const GANCHO_CHAMADO_POUSO: StringName = &"sfx_maldicao_chamado_pouso"
const GANCHO_TROCA_TECNICA: StringName = &"sfx_maldicao_troca_tecnica"
const GANCHO_EXAUSTA: StringName = &"sfx_maldicao_exausta"
const GANCHO_PRONTA: StringName = &"sfx_maldicao_pronta"
const GANCHO_RECUSA: StringName = &"sfx_maldicao_recusa"

var em_campo: bool = false
var especie_id: StringName = &""
var pos_maldicao: Vector2 = Vector2.ZERO
var pos_jogador: Vector2 = Vector2.ZERO
var distancia_fio_px: float = 0.0
var estado_fio: EstadoFio = EstadoFio.OCULTO
var largura_fio_px: float = 2.0
var usa_telegrafo_de_chao: bool = false # ML-V4: sempre false!
var inimigo_marcado_virote_id: int = -1
var flash_atingida_passos: int = 0
var dissolucao_exausta_passos: int = 0


## Calcula o estado visual do fio de vínculo (ML-V2: > 0,85 * alcance_fio_px = 408 px tensiona; > 480 px estoura).
static func calcular_estado_fio(em_campo_ativo: bool, d_jog: float, estourou: bool,
		alcance_fio_px: float = 480.0) -> EstadoFio:
	if not em_campo_ativo:
		return EstadoFio.OCULTO
	if estourou or d_jog > alcance_fio_px + 1e-5:
		return EstadoFio.ESTOURADO_PULSANDO
	if d_jog > 0.85 * alcance_fio_px + 1e-5:
		return EstadoFio.TENSIONADO_TRACEJADO
	return EstadoFio.CURVO_NORMAL


## Traduz os eventos do passo nos ganchos `sfx_maldicao_*` deduplicados (no máximo 1 por gancho por passo; ML-A1).
static func extrair_ganchos_de_som(eventos: Array[EventoDoPasso]) -> Array[StringName]:
	var emitidos: Dictionary[StringName, bool] = {}
	var ordem: Array[StringName] = []
	for e: EventoDoPasso in eventos:
		if e == null:
			continue
		var gancho: StringName = &""
		match e.tipo():
			EventosMaldicoes.EvMaldicaoGolpe.TIPO:
				gancho = GANCHO_ATAQUE
			EventosMaldicoes.EvChamadoSalto.TIPO:
				gancho = GANCHO_CHAMADO_SALTO
			EventosMaldicoes.EvChamadoPouso.TIPO:
				gancho = GANCHO_CHAMADO_POUSO
			EventosMaldicoes.EvTecnicaCombinada.TIPO:
				gancho = GANCHO_TROCA_TECNICA
			EventosMaldicoes.EvMaldicaoExausta.TIPO:
				gancho = GANCHO_EXAUSTA
			EventosMaldicoes.EvMaldicaoPronta.TIPO:
				gancho = GANCHO_PRONTA
			EventosMaldicoes.EvTrocaIndisponivel.TIPO:
				gancho = GANCHO_RECUSA
		if gancho != &"" and not emitidos.has(gancho):
			emitidos[gancho] = true
			ordem.append(gancho)
	return ordem
