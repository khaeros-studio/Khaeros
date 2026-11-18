class_name Portador
extends ConsultaDeAtributos
## Portador de atributos de um combatente (GDD modificadores-e-atributos R1–R11; ADR-0009).
##
## Guarda bases, fontes ativas (com duração restante por instância) e os agregados.
## Toda escrita ([method aplicar_fonte], [method remover_fonte], expiração em
## [method avancar]) reconstrói o cache inteiro no mesmo método, percorrendo as fontes em
## ordem canônica (texto do id, depois a ordem dos efeitos): leitura O(1)/O(k ≤ 3), sem
## bandeira de sujo (R7). Nunca guarda recursos (Vida, escudo, cargas restantes, contador
## de acertos, janela pós-esquiva) e nunca executa gatilho. Não tem referência de volta
## ao combatente ([InimigoRef]/[JogadorRef] apontam para ele, não o contrário).
##
## Exemplo:
## [codeblock]
## var p := Portador.new(1, 0, Atributos.Especie.JOGADOR, {Atributos.VIDA_MAX: 130.0}, tuning)
## p.aplicar_fonte(FonteDeModificador.new(&"bencao:muro_de_pedras",
##         [Modificador.new(Atributos.VIDA_MAX, Modificador.Operacao.PLANO, 25.0)]))
## p.inteiro(Atributos.VIDA_MAX)  # 155
## [/codeblock]

const _SOLICITANTE: String = "modificadores"

## Id do combatente ([GeradorDeIds]); somente leitura.
var id_combatente: int
## Índice do jogador (0 no solo); −1 em inimigo. Somente leitura.
var player_id: int
## Espécie do portador (pisos de Vida).
var especie: Atributos.Especie

var _tuning: ModifiersTuning
var _relator: RelatorDeErros
var _ouvinte: OuvinteDeAtributos
var _bases: Dictionary[StringName, float] = {}

# Estado vivo: fontes por id e duração restante por id (−1 = permanente).
var _fontes: Dictionary[StringName, FonteDeModificador] = {}
var _restante: Dictionary[StringName, int] = {}
# Ids em ordem canônica (mantida na escrita).
var _ordem: Array[StringName] = []

# Cache (reconstruído só na escrita).
var _valores: Dictionary[StringName, float] = {}
var _inteiros: Dictionary[StringName, int] = {}
var _p_todo: float = 0.0
var _p_ataque: float = 0.0
var _p_especial: float = 0.0
var _p_selo: float = 0.0
var _mult_incond: float = 1.0
var _dano_no_uso: Array[Modificador] = []
var _gatilhos: Dictionary[StringName, ResumoDeGatilho] = {}


## [param p_bases]: base por atributo (vida_max, velocidade, cargas_esquiva, raio vêm do
## dado; os demais usam [method Atributos.base_padrao]). [param p_relator]: recebe
## modificadores recusados (AC-28). [param p_ouvinte]: avisos de R9 (pode ser null).
func _init(p_id_combatente: int, p_player_id: int, p_especie: Atributos.Especie,
		p_bases: Dictionary[StringName, float], p_tuning: ModifiersTuning,
		p_relator: RelatorDeErros = null, p_ouvinte: OuvinteDeAtributos = null) -> void:
	id_combatente = p_id_combatente
	player_id = p_player_id
	especie = p_especie
	_tuning = p_tuning
	_relator = p_relator
	_ouvinte = p_ouvinte
	for a: StringName in Atributos.DERIVADOS:
		_bases[a] = p_bases.get(a, Atributos.base_padrao(a))
	_reconstruir(false)


## Troca o ouvinte de R9 (o Main injeta o despachante uma vez; null desliga).
func definir_ouvinte(ouvinte: OuvinteDeAtributos) -> void:
	_ouvinte = ouvinte


# --- Escrita ---------------------------------------------------------------

## Aplica [param fonte]. Se o id já existe, substitui os valores (sem somar) e a duração
## vira [code]max(restante, nova)[/code]; permanente vence (R6, AC-15, AC-17).
func aplicar_fonte(fonte: FonteDeModificador) -> void:
	var nova: int = fonte.duracao_passos
	if _fontes.has(fonte.id):
		var atual: int = _restante[fonte.id]
		if atual == FonteDeModificador.PERMANENTE or nova == FonteDeModificador.PERMANENTE:
			nova = FonteDeModificador.PERMANENTE
		else:
			nova = maxi(atual, nova)
	else:
		_inserir_ordenado(fonte.id)
	_fontes[fonte.id] = fonte
	_restante[fonte.id] = nova
	_reconstruir(true)


## Remove a fonte e todos os seus modificadores e gatilhos. Idempotente e silencioso
## (AC-13, AC-14).
func remover_fonte(id_fonte: StringName) -> void:
	if not _fontes.has(id_fonte):
		return
	_retirar(id_fonte)
	_reconstruir(true)


## Desconta [param passos] das fontes com duração, em ordem canônica, e expira as que
## chegaram a 0, reconstruindo o cache na mesma chamada (R6, AC-17). Só em passo vivo.
func avancar(passos: int) -> void:
	if passos <= 0:
		return
	var expiradas: Array[StringName] = []
	for id: StringName in _ordem:
		var r: int = _restante[id]
		if r == FonteDeModificador.PERMANENTE:
			continue
		r -= passos
		_restante[id] = r
		if r <= 0:
			expiradas.append(id)
	if expiradas.is_empty():
		return
	for id: StringName in expiradas:
		_retirar(id)
	_reconstruir(true)


# --- Leitura ---------------------------------------------------------------

## Passos que faltam à fonte; −1 se permanente; 0 se não existe (ADR-0009, ADR-0017).
func duracao_restante(id_fonte: StringName) -> int:
	return _restante.get(id_fonte, 0)


## Verdadeiro se a fonte está ativa.
func tem_fonte(id_fonte: StringName) -> bool:
	return _fontes.has(id_fonte)


## Fonte ativa com [param id_fonte]; null se não existe (espelho da Maldição, R14).
func fonte_ativa(id_fonte: StringName) -> FonteDeModificador:
	return _fontes.get(id_fonte, null)


## Ids das fontes ativas, em ordem canônica (cópia).
func ids_de_fontes() -> Array[StringName]:
	return _ordem.duplicate()


func valor(atributo: StringName) -> float:
	if not _valores.has(atributo):
		_relatar(atributo, "valor() só para atributos derivados (dano_* usa multiplicador_de_dano)")
		return 0.0
	return _valores[atributo]


func inteiro(atributo: StringName) -> int:
	if not _inteiros.has(atributo):
		_relatar(atributo, "inteiro() só para os 5 atributos inteiros")
		return 0
	return _inteiros[atributo]


func congelar_dano(slot: Modificador.Slot, ctx: ContextoDeDano) -> DanoCongelado:
	var p_todo: float = _p_todo
	var mult: float = _mult_incond
	var a_cada := PackedInt32Array()
	var mult_enesimo := PackedFloat64Array()
	for m: Modificador in _dano_no_uso:
		if not m.vale_no_slot(slot):
			continue
		match m.condicao:
			Modificador.Condicao.NENHUMA:
				if m.operacao == Modificador.Operacao.PERCENTUAL:
					p_todo += m.valor
				else:
					mult *= m.valor
			Modificador.Condicao.VIDA_ABAIXO:
				if ctx.vida_atual < m.param * _valores[Atributos.VIDA_MAX]:
					if m.operacao == Modificador.Operacao.PERCENTUAL:
						p_todo += m.valor
					else:
						mult *= m.valor
			Modificador.Condicao.APOS_ESQUIVA:
				if ctx.apos_esquiva:
					if m.operacao == Modificador.Operacao.PERCENTUAL:
						p_todo += m.valor
					else:
						mult *= m.valor
			Modificador.Condicao.ENESIMO_ACERTO:
				if m.operacao == Modificador.Operacao.MULTIPLICADOR:
					a_cada.append(FormulasDeModificadores.arredondar_meio_longe_do_zero(m.param))
					mult_enesimo.append(m.valor)
	var fator: float = FormulasDeModificadores.multiplicador_f2(p_todo, _p_do_slot(slot), mult)
	return DanoCongelado.new(fator, a_cada, mult_enesimo, _tuning.teto_multiplicador_dano)


func multiplicador_de_dano(slot: Modificador.Slot, ctx: ContextoDeDano) -> float:
	return congelar_dano(slot, ctx).m_no_impacto(0)


func gatilhos(tipo: StringName) -> ResumoDeGatilho:
	return _gatilhos.get(tipo, ResumoDeGatilho.vazio())


# --- Interno ---------------------------------------------------------------

func _p_do_slot(slot: Modificador.Slot) -> float:
	match slot:
		Modificador.Slot.ATAQUE:
			return _p_ataque
		Modificador.Slot.ESPECIAL:
			return _p_especial
		Modificador.Slot.SELO:
			return _p_selo
	return 0.0


func _inserir_ordenado(id: StringName) -> void:
	var texto := String(id)
	var i: int = 0
	while i < _ordem.size() and String(_ordem[i]) < texto:
		i += 1
	_ordem.insert(i, id)


func _retirar(id: StringName) -> void:
	_fontes.erase(id)
	_restante.erase(id)
	_ordem.erase(id)


func _relatar(chave: StringName, motivo: String) -> void:
	if _relator != null:
		_relator.relatar(RelatorDeErros.Entrada.new(&"modificador", chave, "%s: %s" % [_SOLICITANTE, motivo]))


## Reconstrói todos os agregados em ordem canônica; avisa o ouvinte dos inteiros que mudaram.
func _reconstruir(avisar: bool) -> void:
	var antigos: Dictionary[StringName, int] = _inteiros.duplicate()
	var planos: Dictionary[StringName, float] = {}
	var pcts: Dictionary[StringName, float] = {}
	var mults: Dictionary[StringName, float] = {}
	for a: StringName in Atributos.DERIVADOS:
		planos[a] = 0.0
		pcts[a] = 0.0
		mults[a] = 1.0
	var p_todo: float = 0.0
	var p_ataque: float = 0.0
	var p_especial: float = 0.0
	var p_selo: float = 0.0
	var mult_incond: float = 1.0
	var no_uso: Array[Modificador] = []
	var resumos: Dictionary[StringName, ResumoDeGatilho] = {}

	for id: StringName in _ordem:
		var fonte: FonteDeModificador = _fontes[id]
		for m: Modificador in fonte.modificadores:
			var motivo := m.motivo_invalido()
			if motivo.is_empty() and especie == Atributos.Especie.MALDICAO \
					and not Atributos.DA_MALDICAO.has(m.atributo):
				motivo = "atributo fora da lista do portador da Maldição (R14): %s" % m.atributo
			if not motivo.is_empty():
				_relatar(id, motivo)
				continue
			if Atributos.eh_dano(m.atributo):
				if m.atributo == Atributos.DANO_TODO:
					if m.condicao != Modificador.Condicao.NENHUMA or m.slots != 0:
						no_uso.append(m)
					elif m.operacao == Modificador.Operacao.PERCENTUAL:
						p_todo += m.valor
					else:
						mult_incond *= m.valor
				elif m.atributo == Atributos.DANO_ATAQUE:
					p_ataque += m.valor
				elif m.atributo == Atributos.DANO_ESPECIAL:
					p_especial += m.valor
				else:
					p_selo += m.valor
				continue
			match m.operacao:
				Modificador.Operacao.PLANO:
					planos[m.atributo] += m.valor
				Modificador.Operacao.PERCENTUAL:
					pcts[m.atributo] += m.valor
				Modificador.Operacao.MULTIPLICADOR:
					mults[m.atributo] *= m.valor
		for g: GatilhoAtivo in fonte.gatilhos:
			var r: ResumoDeGatilho = resumos.get(g.tipo)
			if r == null:
				r = ResumoDeGatilho.new(g.tipo)
				r.params = g.params
				resumos[g.tipo] = r
			r.total += g.valor
			r.entradas.append(ResumoDeGatilho.Entrada.new(g.valor, g.params, id))

	var valores: Dictionary[StringName, float] = {}
	var inteiros: Dictionary[StringName, int] = {}
	for a: StringName in Atributos.DERIVADOS:
		var v: float = FormulasDeModificadores.valor_f1(_bases[a], planos[a], pcts[a], mults[a],
				Atributos.piso(a, especie, _tuning), Atributos.teto(a, _tuning))
		if Atributos.eh_inteiro(a):
			var n: int = FormulasDeModificadores.arredondar_meio_longe_do_zero(v)
			inteiros[a] = n
			v = float(n)
		valores[a] = v
	for r: ResumoDeGatilho in resumos.values():
		r.entradas.make_read_only()

	_valores = valores
	_inteiros = inteiros
	_p_todo = p_todo
	_p_ataque = p_ataque
	_p_especial = p_especial
	_p_selo = p_selo
	_mult_incond = mult_incond
	_dano_no_uso = no_uso
	_gatilhos = resumos

	if avisar and _ouvinte != null:
		for a: StringName in Atributos.INTEIROS:
			if antigos[a] != inteiros[a]:
				_ouvinte.atributo_mudou(id_combatente, player_id, a, antigos[a], inteiros[a])
