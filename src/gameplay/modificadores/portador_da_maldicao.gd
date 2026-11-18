class_name PortadorDaMaldicao
extends RefCounted
## Montagem do portador de uma Maldição da dupla (GDD modificadores-e-atributos R2 emenda,
## R14; ADR-0009 Emenda; ADR-0017). É um [Portador] de espécie MALDICAO (lista restrita
## [constant Atributos.DA_MALDICAO]) com base do [CurseDef] + fonte
## [code]vinculo:<curse_id>[/code] + fonte [code]especie:<curse_id>[/code] + espelhos.
## O portador persiste na Exaustão e na reserva; o módulo de Maldições (épico maldicoes)
## decide quando criar. Não guarda Vida (recurso das Maldições).
##
## Exemplo:
## [codeblock]
## var p := PortadorDaMaldicao.criar(id, 0, baluarte, tuning, especie, vinculo, espelho)
## [/codeblock]


## Cria o portador de [param curse] e o põe na dupla de [param espelho] (se não null).
## [param fonte_especie]/[param fonte_vinculo] podem ser null.
static func criar(id_combatente: int, player_id: int, curse: CurseDef, tuning: ModifiersTuning,
		fonte_especie: FonteDeModificador, fonte_vinculo: FonteDeModificador,
		espelho: EspelhoDeFontes, relator: RelatorDeErros = null) -> Portador:
	var bases: Dictionary[StringName, float] = {
		Atributos.VIDA_MAX: curse.vida_max,
		Atributos.VELOCIDADE: curse.velocidade,
		Atributos.RAIO: curse.raio_px,
	}
	var p := Portador.new(id_combatente, player_id, Atributos.Especie.MALDICAO, bases, tuning, relator)
	if fonte_especie != null:
		p.aplicar_fonte(fonte_especie)
	if fonte_vinculo != null:
		p.aplicar_fonte(fonte_vinculo)
	if espelho != null:
		espelho.adicionar_maldicao(p)
	return p


## Criação no passo de um pacto (R14, R24): null se a dupla já está cheia
## ([param tamanho_dupla] ≥ [param tamanho_maximo], valor do dono Maldições).
static func criar_no_pacto(tamanho_dupla: int, tamanho_maximo: int, id_combatente: int, player_id: int,
		curse: CurseDef, tuning: ModifiersTuning, fonte_especie: FonteDeModificador,
		fonte_vinculo: FonteDeModificador, espelho: EspelhoDeFontes, relator: RelatorDeErros = null) -> Portador:
	if tamanho_dupla >= tamanho_maximo:
		return null
	return criar(id_combatente, player_id, curse, tuning, fonte_especie, fonte_vinculo, espelho, relator)


## Vida da Maldição criada no pacto: [code]min(Vida_acuada, vida_max)[/code] (R14).
static func vida_ao_nascer_no_pacto(vida_acuada: float, vida_max: int) -> float:
	return minf(vida_acuada, float(vida_max))
