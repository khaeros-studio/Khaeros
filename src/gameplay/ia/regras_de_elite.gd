class_name RegrasDeElite
extends RefCounted
## Regras de sorteio e atributos de Elites (GDD ia-de-inimigos-e-elites.md R10, F1, F2; ADR-0018 §9).
## A IA é a dona única do `depth_hp_bonus` (+5%/profundidade) e das constantes de elite.

const BONUS_VIDA_POR_PROFUNDIDADE_PADRAO: float = 0.05
const MULT_VIDA_ELITE_PADRAO: float = 2.4
const MULT_DANO_ELITE_PADRAO: float = 1.25
const MULT_RAIO_ELITE_PADRAO: float = 1.2
const RESISTENCIA_EMPURRAO_ELITE_PADRAO: float = 0.4


static func de_fabrica() -> EliteRules:
	var r := EliteRules.new()
	r.id = &"elite_rules"
	r.mult_vida = MULT_VIDA_ELITE_PADRAO
	r.mult_dano = MULT_DANO_ELITE_PADRAO
	r.mult_raio = MULT_RAIO_ELITE_PADRAO
	r.resistencia_empurrao = RESISTENCIA_EMPURRAO_ELITE_PADRAO
	r.profundidade_minima = 3
	r.max_elites_onda = 1
	var c := LinearCurveDef.new()
	c.x_min = 3.0
	c.base = 0.05
	c.slope = 0.02
	c.y_floor = 0.0
	c.y_cap = 0.25
	c.sem_teto = false
	r.curva_chance = c
	return r


## F1: chance de elite na profundidade `p` (0 se p < profundidade_minima; senão min(0,25 ; 0,05 + 0,02 * p)).
static func chance_elite(profundidade: int, regras: EliteRules = null) -> float:
	var reg := regras if regras != null else de_fabrica()
	if profundidade < reg.profundidade_minima:
		return 0.0
	if reg.curva_chance != null:
		return CurvaLinear.avaliar(reg.curva_chance, float(profundidade))
	return minf(0.25, 0.05 + 0.02 * float(profundidade))


## R10 / F1: consome SEMPRE 1 real do `fluxo_elites` (RNG R4b), independente da profundidade ou de `ja_ha_elite`.
static func sortear_elite(profundidade: int, ja_ha_elite: bool, fluxo_elites: FluxoRng,
		regras: EliteRules = null, eh_chefe: bool = false) -> bool:
	var r := fluxo_elites.real_unitario() if fluxo_elites != null else 1.0
	if eh_chefe or ja_ha_elite:
		return false
	var chance := chance_elite(profundidade, regras)
	if chance <= 0.0:
		return false
	return r < chance - 1e-9


## F2: Vida máxima calculada de um inimigo (comuns ganham +5%/p, elite * 2,4 arredondada; chefe e lacaios não escalam por p).
static func calcular_vida_max(vida_base: float, profundidade: int, elite: bool,
		eh_chefe: bool = false, invocado_pelo_chefe: bool = false,
		regras: EliteRules = null, bonus_prof: float = BONUS_VIDA_POR_PROFUNDIDADE_PADRAO) -> float:
	if eh_chefe or invocado_pelo_chefe:
		return float(Unidades.arredondar_meio_longe_do_zero(vida_base))
	var reg := regras if regras != null else de_fabrica()
	var escala_prof := 1.0 + bonus_prof * float(maxi(0, profundidade))
	var mult_el := reg.mult_vida if elite else 1.0
	return float(Unidades.arredondar_meio_longe_do_zero(vida_base * escala_prof * mult_el))


## F2: Dano base escalado (elite * 1,25).
static func calcular_dano_base(dano_base: float, elite: bool, regras: EliteRules = null) -> float:
	if not elite:
		return dano_base
	var reg := regras if regras != null else de_fabrica()
	return dano_base * reg.mult_dano


## F2: Raio escalado (elite * 1,2).
static func calcular_raio(raio_base: float, elite: bool, regras: EliteRules = null) -> float:
	if not elite:
		return raio_base
	var reg := regras if regras != null else de_fabrica()
	return raio_base * reg.mult_raio


## F2: Fator de empurrão (comum = 1,0; elite = 0,4; chefe = 0,12).
static func calcular_fator_empurrao(elite: bool, eh_chefe: bool, regras: EliteRules = null) -> float:
	if eh_chefe:
		return 0.12
	if elite:
		var reg := regras if regras != null else de_fabrica()
		return reg.resistencia_empurrao
	return 1.0


## Cria as fontes de modificador (`profundidade`, `elite`, `chefe`) para o Portador do inimigo (ADR-0009 R10, TR-ia-007).
static func aplicar_fontes_no_portador(portador: Portador, profundidade: int,
		elite: bool, eh_chefe: bool, invocado_pelo_chefe: bool = false,
		regras: EliteRules = null, bonus_prof: float = BONUS_VIDA_POR_PROFUNDIDADE_PADRAO) -> void:
	if portador == null:
		return
	var reg := regras if regras != null else de_fabrica()
	if not eh_chefe and not invocado_pelo_chefe and profundidade > 0:
		portador.aplicar_fonte(FonteDeModificador.new(&"profundidade", [
			Modificador.new(Atributos.VIDA_MAX, Modificador.Operacao.PERCENTUAL, bonus_prof * float(profundidade)),
		]))
	if elite and not eh_chefe:
		portador.aplicar_fonte(FonteDeModificador.new(&"elite", [
			Modificador.new(Atributos.VIDA_MAX, Modificador.Operacao.MULTIPLICADOR, reg.mult_vida),
			Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.MULTIPLICADOR, reg.mult_dano),
			Modificador.new(Atributos.RAIO, Modificador.Operacao.MULTIPLICADOR, reg.mult_raio),
			Modificador.new(Atributos.FATOR_EMPURRAO, Modificador.Operacao.MULTIPLICADOR, reg.resistencia_empurrao),
		]))
	elif eh_chefe:
		portador.aplicar_fonte(FonteDeModificador.new(&"chefe", [
			Modificador.new(Atributos.FATOR_EMPURRAO, Modificador.Operacao.MULTIPLICADOR, 0.12),
		]))
