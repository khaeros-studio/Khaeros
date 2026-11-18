extends RefCounted
## Fábrica em memória dos testes de Modificadores (GDD modificadores-e-atributos,
## cabeçalho dos AC: "portadores vêm de uma fábrica em memória"). Fixtures com os valores
## iniciais da R2/ModifiersTuning e das bênçãos citadas nos oráculos; não lê o catálogo.

const OP := Modificador.Operacao
const COND := Modificador.Condicao
const TOL: float = 1e-6


## ModifiersTuning com os valores iniciais da tabela da R2.
static func tuning() -> ModifiersTuning:
	var t := ModifiersTuning.new()
	t.piso_vida_jogador = 20.0
	t.piso_vida_inimigo = 1.0
	t.teto_reducao_dano = 0.6
	t.teto_multiplicador_dano = 4.0
	t.fator_empurrao_chefe = 0.12
	t.piso_vida_maldicao = 20.0
	t.tipos_propagados_maldicao = [&"dano_todo_pct", &"velocidade_pct"]
	t.fator_propagacao_maldicao = 1.0
	return t


static func jogador(vida_max: float = 130.0, extras: Dictionary[StringName, float] = {},
		t: ModifiersTuning = null, relator: RelatorDeErros = null,
		ouvinte: OuvinteDeAtributos = null) -> Portador:
	var bases: Dictionary[StringName, float] = {Atributos.VIDA_MAX: vida_max}
	bases.merge(extras, true)
	return Portador.new(1, 0, Atributos.Especie.JOGADOR, bases, t if t != null else tuning(), relator, ouvinte)


static func inimigo(vida_max: float, ouvinte: OuvinteDeAtributos = null) -> Portador:
	var bases: Dictionary[StringName, float] = {Atributos.VIDA_MAX: vida_max, Atributos.RAIO: 10.0}
	return Portador.new(7, -1, Atributos.Especie.INIMIGO, bases, tuning(), null, ouvinte)


static func fonte(id: StringName, mods: Array[Modificador], duracao: int = FonteDeModificador.PERMANENTE,
		gat: Array[GatilhoAtivo] = []) -> FonteDeModificador:
	return FonteDeModificador.new(id, mods, gat, duracao)


static func mod(atributo: StringName, op: Modificador.Operacao, v: float) -> Modificador:
	return Modificador.new(atributo, op, v)


# --- Bênçãos dos oráculos (valores Comum do GDD) ---

static func muro_de_pedras(v: float = 25.0) -> FonteDeModificador:
	return fonte(&"bencao:muro_de_pedras", [mod(Atributos.VIDA_MAX, OP.PLANO, v)])


static func vigor(nivel_vezes_valor: float) -> FonteDeModificador:
	return fonte(&"oficina:vigor", [mod(Atributos.VIDA_MAX, OP.PLANO, nivel_vezes_valor)])


static func preco_com_nome(dano: float = 0.2) -> FonteDeModificador:
	return fonte(&"bencao:preco_com_nome", [
		mod(Atributos.DANO_TODO, OP.PERCENTUAL, dano),
		mod(Atributos.VIDA_MAX, OP.PLANO, -10.0),
	])


static func impeto(v: float = 0.15) -> FonteDeModificador:
	return fonte(&"oficina:impeto", [mod(Atributos.DANO_TODO, OP.PERCENTUAL, v)])


static func traco_unico(v: float = 0.25) -> FonteDeModificador:
	return fonte(&"bencao:traco_unico", [mod(Atributos.DANO_ATAQUE, OP.PERCENTUAL, v)])


static func fundo_do_poco(v: float = 0.4) -> FonteDeModificador:
	return fonte(&"bencao:fundo_do_poco", [
		Modificador.new(Atributos.DANO_TODO, OP.PERCENTUAL, v, COND.VIDA_ABAIXO, 0.5)])


static func linha_contada(v: float = 1.6) -> FonteDeModificador:
	return fonte(&"bencao:linha_contada", [Modificador.new(Atributos.DANO_TODO, OP.MULTIPLICADOR, v,
		COND.ENESIMO_ACERTO, 4.0, Modificador.MASCARA_ATAQUE | Modificador.MASCARA_ESPECIAL)])


static func penumbra(v: float = 1.5) -> FonteDeModificador:
	return fonte(&"bencao:penumbra", [Modificador.new(Atributos.DANO_TODO, OP.MULTIPLICADOR, v,
		COND.APOS_ESQUIVA, 1.5, Modificador.MASCARA_ATAQUE | Modificador.MASCARA_ESPECIAL)])


static func abalo() -> FonteDeModificador:
	return fonte(&"status:abalo", [mod(Atributos.DANO_TODO, OP.MULTIPLICADOR, 0.7)])


static func velocidade_pct(id: StringName, v: float, duracao: int = FonteDeModificador.PERMANENTE) -> FonteDeModificador:
	return fonte(id, [mod(Atributos.VELOCIDADE, OP.PERCENTUAL, v)], duracao)


## Ouvinte espião: registra cada aviso.
class Espiao:
	extends OuvinteDeAtributos
	var chamadas: Array[Array] = []

	func atributo_mudou(id_combatente: int, player_id: int, atributo: StringName, antigo: int, novo: int) -> void:
		chamadas.append([id_combatente, player_id, atributo, antigo, novo])
