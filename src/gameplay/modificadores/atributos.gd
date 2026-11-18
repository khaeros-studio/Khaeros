class_name Atributos
extends RefCounted
## Esquema da lista fechada de atributos (GDD modificadores-e-atributos R2; ADR-0009 §3).
##
## É esquema em código, não tuning: nomes, quais são inteiros por natureza, quais são
## acumuladores de dano e os limites estruturais da tabela R2 ("≥ 0", "≥ 1", "0 – 1").
## Os pisos/tetos ajustáveis (Vida por espécie de portador, teto da redução) vêm do
## [ModifiersTuning] injetado.
##
## Exemplo:
## [codeblock]
## var piso := Atributos.piso(Atributos.VIDA_MAX, Atributos.Especie.JOGADOR, tuning)
## assert(Atributos.eh_inteiro(Atributos.VIDA_MAX))
## [/codeblock]

## Espécie do portador; decide o piso de [code]vida_max[/code] e a lista de atributos usada.
enum Especie { JOGADOR, INIMIGO, MALDICAO }

const VIDA_MAX: StringName = &"vida_max"
const VELOCIDADE: StringName = &"velocidade"
const DANO_ATAQUE: StringName = &"dano_ataque"
const DANO_ESPECIAL: StringName = &"dano_especial"
const DANO_SELO: StringName = &"dano_selo"
const DANO_TODO: StringName = &"dano_todo"
const REDUCAO_DANO: StringName = &"reducao_dano"
const CARGAS_ESQUIVA: StringName = &"cargas_esquiva"
const ESCUDO_SALA: StringName = &"escudo_sala"
const TROCAS_OFERTA: StringName = &"trocas_oferta"
const RECUSAS_MORTE: StringName = &"recusas_morte"
const RAIO: StringName = &"raio"
const FATOR_EMPURRAO: StringName = &"fator_empurrao"

## Atributos que passam pela F1, em ordem fixa (também a ordem dos avisos ao ouvinte).
const DERIVADOS: Array[StringName] = [
	VIDA_MAX, VELOCIDADE, REDUCAO_DANO, CARGAS_ESQUIVA, ESCUDO_SALA,
	TROCAS_OFERTA, RECUSAS_MORTE, RAIO, FATOR_EMPURRAO,
]
## Os cinco inteiros por natureza (R2), na ordem fixa dos avisos do [OuvinteDeAtributos].
const INTEIROS: Array[StringName] = [
	VIDA_MAX, ESCUDO_SALA, CARGAS_ESQUIVA, RECUSAS_MORTE, TROCAS_OFERTA,
]
## Acumuladores lidos só pela F2 ([method Portador.multiplicador_de_dano]).
const DANO: Array[StringName] = [DANO_ATAQUE, DANO_ESPECIAL, DANO_SELO, DANO_TODO]
## Atributos aceitos pelo portador da Maldição (R2, emenda Pactos 2026-11-15; R14).
const DA_MALDICAO: Array[StringName] = [VIDA_MAX, VELOCIDADE, DANO_TODO, REDUCAO_DANO, RAIO]

# Limites estruturais da tabela R2 (não são knobs: a R2 os fixa como forma da regra).
# reducao_dano tem piso 0 (Divergências: "um debuff futuro não vira dano extra").
const _PISO_ZERO: float = 0.0
const _PISO_CARGAS: float = 1.0      # R2 / Edge Cases: "o jogador sempre tem uma esquiva (P3)"
const _TETO_EMPURRAO: float = 1.0    # R2: fator_empurrao 0 – 1


## Verdadeiro se [param atributo] está na lista fechada R2 (derivados ou dano).
static func existe(atributo: StringName) -> bool:
	return DERIVADOS.has(atributo) or DANO.has(atributo)


## Verdadeiro se [param atributo] é um dos 5 inteiros por natureza (AC-05).
static func eh_inteiro(atributo: StringName) -> bool:
	return INTEIROS.has(atributo)


## Verdadeiro se [param atributo] é acumulador de dano (só F2).
static func eh_dano(atributo: StringName) -> bool:
	return DANO.has(atributo)


## Base implícita quando o dado não informa (R2: "Base 0"; fator_empurrao "1").
## Atributos com base vinda do dado ([code]vida_max[/code], [code]velocidade[/code],
## [code]cargas_esquiva[/code], [code]raio[/code]) devolvem 0 se faltarem.
static func base_padrao(atributo: StringName) -> float:
	if atributo == FATOR_EMPURRAO:
		return _TETO_EMPURRAO
	return _PISO_ZERO


## Piso do atributo para a espécie (R2). [code]-INF[/code] se não há piso.
static func piso(atributo: StringName, especie: Especie, tuning: ModifiersTuning) -> float:
	match atributo:
		VIDA_MAX:
			match especie:
				Especie.JOGADOR:
					return tuning.piso_vida_jogador
				Especie.INIMIGO:
					return tuning.piso_vida_inimigo
				_:
					return tuning.piso_vida_maldicao
		CARGAS_ESQUIVA:
			return _PISO_CARGAS
		VELOCIDADE, REDUCAO_DANO, ESCUDO_SALA, TROCAS_OFERTA, RECUSAS_MORTE, RAIO, FATOR_EMPURRAO:
			return _PISO_ZERO
	return -INF


## Teto do atributo (R2). [code]INF[/code] se não há teto.
static func teto(atributo: StringName, tuning: ModifiersTuning) -> float:
	match atributo:
		REDUCAO_DANO:
			return tuning.teto_reducao_dano
		FATOR_EMPURRAO:
			return _TETO_EMPURRAO
	return INF
