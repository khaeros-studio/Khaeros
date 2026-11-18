class_name AplicadorDeEfeitos
extends RefCounted
## Transforma [EffectDef]s em uma [FonteDeModificador] (GDD modificadores-e-atributos R5,
## R8, F5, R10; ADR-0009 §3 "AplicadorDeEfeitos"). Função pura: aplica a escala de
## raridade ao [code]valor[/code] só se [code]escala_com_raridade[/code]; os
## [code]params[/code] nunca escalam. Tipo desconhecido ou param de condição ausente vai ao
## relator e é ignorado (AC-28). Também monta as fontes de spawn [code]elite[/code],
## [code]chefe[/code] e [code]profundidade[/code] (R10).
##
## Exemplo:
## [codeblock]
## var f := AplicadorDeEfeitos.fonte_de(&"bencao:preco_com_nome", boon.efeitos, 1.5)
## portador.aplicar_fonte(f)
## [/codeblock]


## Fonte [param id] com os efeitos escalados por [param escala] (F5).
static func fonte_de(id: StringName, efeitos: Array[EffectDef], escala: float,
		duracao_passos: int = FonteDeModificador.PERMANENTE, relator: RelatorDeErros = null) -> FonteDeModificador:
	var mods: Array[Modificador] = []
	var gats: Array[GatilhoAtivo] = []
	for e: EffectDef in efeitos:
		var l := TabelaDeEfeitos.linha(e.tipo)
		if l == null:
			_relatar(relator, e.tipo, "tipo de efeito fora da R5")
			continue
		var v: float = valor_escalado(e, escala)
		if l.gera_modificador():
			var param: float = 0.0
			if l.param_condicao != &"":
				if not e.params.has(l.param_condicao):
					_relatar(relator, e.tipo, "param %s ausente" % l.param_condicao)
					continue
				param = e.params[l.param_condicao]
			var mv: float = (1.0 + v) if l.multiplicador_um_mais() else v
			mods.append(Modificador.new(l.atributo, l.operacao, mv, l.condicao, param, l.slots))
		if l.gera_gatilho():
			gats.append(GatilhoAtivo.new(e.tipo, v, e.params))
	return FonteDeModificador.new(id, mods, gats, duracao_passos)


## F5: [code]valor × (escala_com_raridade ? escala : 1)[/code].
static func valor_escalado(e: EffectDef, escala: float) -> float:
	return e.valor * (escala if e.escala_com_raridade else 1.0)


## Fonte [code]elite[/code] (R10) com as constantes de [EliteRules] (dona: IA).
## [code]resistencia_empurrao[/code] é lido como o multiplicador de [code]fator_empurrao[/code].
static func fonte_elite(regras: EliteRules) -> FonteDeModificador:
	const MU := Modificador.Operacao.MULTIPLICADOR
	return FonteDeModificador.new(&"elite", [
		Modificador.new(Atributos.VIDA_MAX, MU, regras.mult_vida),
		Modificador.new(Atributos.DANO_TODO, MU, regras.mult_dano),
		Modificador.new(Atributos.RAIO, MU, regras.mult_raio),
		Modificador.new(Atributos.FATOR_EMPURRAO, MU, regras.resistencia_empurrao),
	])


## Fonte [code]chefe[/code] (R10): [code]fator_empurrao × fator_empurrao_chefe[/code].
static func fonte_chefe(tuning: ModifiersTuning) -> FonteDeModificador:
	return FonteDeModificador.new(&"chefe", [Modificador.new(Atributos.FATOR_EMPURRAO,
			Modificador.Operacao.MULTIPLICADOR, tuning.fator_empurrao_chefe)])


## Fonte [code]profundidade[/code] (R10): percentual de Vida já calculado pela IA (F2 dela,
## [code]depth_hp_bonus[/code]). Não usar em chefe.
static func fonte_profundidade(bonus_vida_pct: float) -> FonteDeModificador:
	return FonteDeModificador.new(&"profundidade", [Modificador.new(Atributos.VIDA_MAX,
			Modificador.Operacao.PERCENTUAL, bonus_vida_pct)])


static func _relatar(relator: RelatorDeErros, chave: StringName, motivo: String) -> void:
	if relator != null:
		relator.relatar(RelatorDeErros.Entrada.new(&"modificador", chave, "modificadores: %s" % motivo))
