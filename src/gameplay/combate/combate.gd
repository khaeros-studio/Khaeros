class_name Combate
extends RefCounted
## Combate núcleo: fachada de lógica pura com estado próprio e colaboradores injetados
## (GDD design/gdd/combate-nucleo.md R1–R25, F1–F13; ADR-0010 §1–§11).
##
## Sem Node, sem relógio da engine, sem singleton, sem [code]Engine.time_scale[/code]. Tudo
## vem de [DependenciasDoCombate]; o [CombatTuning] e os [AttackDef] são copiados por
## [code]duplicate_deep(Resource.DEEP_DUPLICATE_ALL)[/code] (ADR-0004) e convertidos para
## passos aqui (R15). Sem tuning ou sem AttackDef o Combate não se cria
## ([method criar] devolve null e [member DependenciasDoCombate.erro] nomeia o motivo).
##
## Itens do passo vivo chamados pelo orquestrador (R1): [method inicio_do_passo] (3),
## [method golpe_do_jogador] (5), [method impacto_do_inimigo] (7), [method projeteis] (8),
## [method varredura_de_mortes] (9); item 2: [method hitstop_ativo] e
## [method passo_congelado_do_combate].

## Erros nomeados de construção (AC-04).
const ERRO_SEM_TUNING := &"COMBATE_SEM_COMBAT_TUNING"
const ERRO_SEM_JOGADOR := &"COMBATE_SEM_JOGADOR"
const ERRO_SEM_PORTADOR := &"COMBATE_SEM_PORTADOR"
const ERRO_SEM_ATTACKDEF := &"COMBATE_SEM_ATTACKDEF"
const ERRO_SEM_MOVIMENTO := &"COMBATE_SEM_MOVIMENTO"

var _p: ParametrosDoCombate
var _movimento: MovimentoParaCombate
var _maldicoes: MaldicoesParaCombate
var _ia: ContratosDoCombate.IAParaCombate
var _camaras: ContratosDoCombate.CamarasParaCombate
var _selo: ContratosDoCombate.SeloParaCombate
var _status: ContratosDoCombate.StatusParaCombate
var _telegrafos: ContratosDoCombate.TelegrafosParaCombate
var _vinculo: ContratosDoCombate.VinculoParaCombate
var _eventos: EventosDoPasso
var _pedir_estado: Callable
var _teto_reducao_dano: float = 0.6

var _portadores: Array[Portador] = []
var _ataques: Array[AtaqueConvertido] = []
var _especiais: Array[AtaqueConvertido] = []
var _recursos: Array[RecursosDoJogador] = []
var _projeteis: Array[ProjetilRegistro] = []
var _proximo_id_projetil: int = 1
var _hitstop: int = 0
var _disparos: Array[EstadoDeGolpe] = []
## Pedidos de hitstop feitos no passo corrente (para inspeção em testes).
var _pedidos_hitstop_passo: Array[int] = []


## Cria o Combate ou devolve null com [member DependenciasDoCombate.erro] preenchido.
static func criar(d: DependenciasDoCombate) -> Combate:
	d.erro = _erro_das_dependencias(d)
	if d.erro != &"":
		return null
	return Combate.new(d)


static func _erro_das_dependencias(d: DependenciasDoCombate) -> StringName:
	if d.tuning == null:
		return ERRO_SEM_TUNING
	if d.movimento == null:
		return ERRO_SEM_MOVIMENTO
	if d.jogadores.is_empty():
		return ERRO_SEM_JOGADOR
	for j in d.jogadores:
		if j == null or j.portador == null:
			return ERRO_SEM_PORTADOR
		if j.ataque == null or j.especial == null:
			return ERRO_SEM_ATTACKDEF
	return &""


## Use [method criar]; o construtor presume dependências já conferidas.
func _init(d: DependenciasDoCombate) -> void:
	_p = ParametrosDoCombate.de(d.tuning.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as CombatTuning)
	_movimento = d.movimento
	_maldicoes = d.maldicoes
	_ia = d.ia if d.ia != null else ContratosDoCombate.IAParaCombate.new()
	_camaras = d.camaras if d.camaras != null else ContratosDoCombate.CamarasParaCombate.new()
	_selo = d.selo if d.selo != null else ContratosDoCombate.SeloParaCombate.new()
	_status = d.status if d.status != null else ContratosDoCombate.StatusParaCombate.new()
	_telegrafos = d.telegrafos if d.telegrafos != null else ContratosDoCombate.TelegrafosParaCombate.new()
	_vinculo = d.vinculo if d.vinculo != null else ContratosDoCombate.VinculoParaCombate.new()
	_eventos = d.eventos if d.eventos != null else EventosDoPasso.new()
	_pedir_estado = d.pedir_estado
	_teto_reducao_dano = d.teto_reducao_dano
	for i in d.jogadores.size():
		var j := d.jogadores[i]
		_portadores.append(j.portador)
		_ataques.append(AtaqueConvertido.de(j.ataque.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as AttackDef))
		_especiais.append(AtaqueConvertido.de(j.especial.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as AttackDef))
		var rec_morte := j.portador.inteiro(Atributos.RECUSAS_MORTE)
		var gat_rec := j.portador.gatilhos(&"recusas_morte")
		if gat_rec.total > 0.0:
			rec_morte = maxi(rec_morte, FormulasDeModificadores.arredondar_meio_longe_do_zero(gat_rec.total))
		_recursos.append(RecursosDoJogador.new(i, j.portador.inteiro(Atributos.VIDA_MAX), rec_morte))


# --- Consultas ---------------------------------------------------------------

## Parâmetros convertidos (só leitura).
func parametros() -> ParametrosDoCombate:
	return _p


## Recursos do jogador [param player_id] (só leitura fora do Combate).
func recursos(player_id: int = 0) -> RecursosDoJogador:
	return _recursos[player_id]


## Ataque ([param slot] 0) ou Especial (1) convertido do jogador.
func ataque_do_slot(player_id: int, slot: int) -> AtaqueConvertido:
	return _ataques[player_id] if slot == RecursosDoJogador.SLOT_ATAQUE else _especiais[player_id]


## Disparos (e recusas do Chamado) do último item 5, em ordem.
func disparos_do_passo() -> Array[EstadoDeGolpe]:
	return _disparos


## Projéteis em voo, na ordem de criação (só leitura).
func projeteis_em_voo() -> Array[ProjetilRegistro]:
	return _projeteis


## Canal de eventos do passo usado por esta instância.
func eventos() -> EventosDoPasso:
	return _eventos


## Pedidos de hitstop acumulados no último passo vivo.
func pedidos_hitstop_do_passo() -> Array[int]:
	return _pedidos_hitstop_passo


## Verdadeiro se o inimigo [param inimigo_id] é atingível (R9: Vida > 0, não surgindo, não subjugado).
func atingivel(inimigo_id: int) -> bool:
	var ini := _ia.obter_inimigo(inimigo_id)
	return _inimigo_atingivel(ini)


static func _inimigo_atingivel(ini: ContratosDoCombate.InimigoCombate) -> bool:
	return ini != null and ini.vida > 0.0 and not ini.surgindo and not ini.subjugado


## Verdadeiro se o inimigo [param inimigo_id] está cambaleando (R12).
func cambaleando(inimigo_id: int) -> bool:
	var ini := _ia.obter_inimigo(inimigo_id)
	return ini != null and ini.cambaleio > 0


## Verdadeiro se o jogador [param player_id] morreu sem recusa (R13.7, R14).
func jogador_morto(player_id: int = 0) -> bool:
	return _recursos[player_id].morto


# --- Item 2: hitstop (R10; ADR-0010 §5) -------------------------------------

## Verdadeiro se o próximo passo é congelado.
func hitstop_ativo() -> bool:
	return _hitstop > 0


## Passos de hitstop pendentes.
func hitstop_restante() -> int:
	return _hitstop


## Item 2 de um passo congelado: desconta 1. Nada mais do Combate desconta.
func passo_congelado_do_combate() -> void:
	if _hitstop > 0:
		_hitstop -= 1


## Contrato com Câmaras/Run (R10): a avaliação de câmara limpa só pode rodar com hitstop 0.
func pode_avaliar_camara_limpa() -> bool:
	return _hitstop == 0


## Ação 1 do quadro da metade do wipe: zera hitstop, investida e recuperação e limpa status (TR-status-008).
## Recargas, combo, janelas, guarda e invulnerabilidade passam como estão.
func camara_nova() -> void:
	_hitstop = 0
	for r in _recursos:
		r.investida = 0
		r.deslocamento_investida = Vector2.ZERO
		r.atingidos_investida.clear()
		r.recuperacao = 0
	_status.limpar_todos()


## Pedido de hitstop: vale o maior (R10). Só o próprio Combate chama.
func _pedir_hitstop(n: int) -> void:
	if n <= 0:
		return
	_pedidos_hitstop_passo.append(n)
	_hitstop = maxi(_hitstop, n)


func _emitir(ev: EventoDoPasso) -> void:
	if _eventos != null:
		_eventos.emitir(ev)


# --- Item 3 (R2) ------------------------------------------------------------

## Descontos do início do passo, por jogador em ordem de player_id: portador.avancar(1),
## depois invulnerabilidade, recargas, guarda, apos_esquiva, recuperação e janelas de combo.
func inicio_do_passo() -> void:
	_pedidos_hitstop_passo.clear()
	for r in _recursos:
		_portadores[r.player_id].avancar(1)
		r.invulneravel = maxi(0, r.invulneravel - 1)
		r.recarga[0] = maxi(0, r.recarga[0] - 1)
		r.recarga[1] = maxi(0, r.recarga[1] - 1)
		r.guarda = maxi(0, r.guarda - 1)
		r.apos_esquiva = maxi(0, r.apos_esquiva - 1)
		r.recuperacao = maxi(0, r.recuperacao - 1)
		for s in 2:
			if r.janela_combo[s] > 0:
				r.janela_combo[s] -= 1
				if r.janela_combo[s] == 0:
					r.passo_combo[s] = 0


# --- Item 5 (R3, R3.1, R4, R5, R6) ------------------------------------------

## Mira e ponto mirado do passo (entregues pelo adaptador a partir da amostra do Input).
func definir_mira(player_id: int, mira: Vector2, ponto: Vector2 = Vector2.ZERO) -> void:
	var r := _recursos[player_id]
	if mira != Vector2.ZERO:
		r.mira = mira.normalized()
	r.ponto_mirado = ponto


## Item 5: investida em curso e disparo. [param comandos] indexado por player_id.
func golpe_do_jogador(comandos: Array[ComandosDoPasso]) -> void:
	_disparos.clear()
	for r in _recursos:
		var tinha_cmd := r.player_id < comandos.size() and comandos[r.player_id] != null
		var cmd: ComandosDoPasso = comandos[r.player_id] if tinha_cmd else null
		# (a0) lê "investida ativa" antes do disparo e guarda para o Selo (TR-selo-004).
		r.investida_ativa_no_item_5 = r.investida > 0
		# (a) se há investida ativa, testa os alvos na posição atual (F6), pede hitstop pesado no 1º alvo
		# e leve nos seguintes, e desconta 1 do contador.
		if r.investida > 0:
			_testar_alvos_investida(r)
			r.investida -= 1
			if r.investida == 0:
				r.deslocamento_investida = Vector2.ZERO
				r.atingidos_investida.clear()
		# (b) testa o disparo (R3: em esquiva ou investida bloqueia; Especial antes do Ataque; um por passo).
		if tinha_cmd and not _movimento.em_esquiva(r.player_id) and r.investida == 0:
			if not _tentar_slot(r, cmd, RecursosDoJogador.SLOT_ESPECIAL, Acoes.ESPECIAL):
				_tentar_slot(r, cmd, RecursosDoJogador.SLOT_ATAQUE, Acoes.ATAQUE)
		# (h) entrega ao Selo o valor guardado em (a0), uma vez por jogador, antes do item 6.
		_selo.receber_investida(r.player_id, r.investida_ativa_no_item_5)


func _testar_alvos_investida(r: RecursosDoJogador) -> void:
	var pos_j := _movimento.posicao(r.player_id)
	var a := ataque_do_slot(r.player_id, r.slot_investida)
	var raio_inv := a.param(&"raio_px")
	var dir_inv := r.deslocamento_investida.normalized() if r.deslocamento_investida != Vector2.ZERO else r.mira
	for ini in _ia.inimigos():
		if not _inimigo_atingivel(ini):
			continue
		if r.atingidos_investida.has(ini.id):
			continue
		if GeometriaDeAcerto.circulo_toca(pos_j, raio_inv, ini.posicao, ini.raio):
			r.atingidos_investida[ini.id] = true
			var era_primeiro := not r.primeiro_alvo_investida_atingido
			r.primeiro_alvo_investida_atingido = true
			var peso_vis: StringName = &"pesado" if era_primeiro else &"leve"
			_ferir_inimigo_interno(
				ini, r.player_id, r.dano_golpe_investida, r.dano_congelado_investida,
				dir_inv, r.empurrao_investida, r.status_investida, true, false,
				_nome_slot(r.slot_investida), AtaqueConvertido.FORMA_AVANCO,
				peso_vis, false)
			_pedir_hitstop(_p.hitstop_pesado if era_primeiro else _p.hitstop_leve)


func _tentar_slot(r: RecursosDoJogador, cmd: ComandosDoPasso, slot: int, acao: StringName) -> bool:
	if r.recarga[slot] > 0 or not cmd.quer(acao):
		return false
	var a := ataque_do_slot(r.player_id, slot)
	if a.forma == AtaqueConvertido.FORMA_CHAMADO and (_maldicoes == null or not _maldicoes.chamado_disponivel(r.player_id)):
		# R3.1: recusa não é disparo; o evento sai só por toque novo (buffer), não segurando.
		if cmd.consumir(acao):
			var e := EstadoDeGolpe.new()
			e.passo = cmd.id_passo()
			e.player_id = r.player_id
			e.slot = slot
			e.ataque = a
			e.recusa_chamado = true
			_disparos.append(e)
			var motivo := _maldicoes.motivo_indisponivel(r.player_id) if _maldicoes != null else &"sem_maldicao"
			_emitir(EventosDoCombate.EvChamadoIndisponivel.new(r.player_id, motivo))
		return false
	cmd.consumir(acao)
	_disparar(r, slot, a, cmd.id_passo())
	return true


func _disparar(r: RecursosDoJogador, slot: int, a: AtaqueConvertido, passo: int) -> void:
	var t := _p.tuning
	var e := EstadoDeGolpe.new()
	e.passo = passo
	e.player_id = r.player_id
	e.slot = slot
	e.ataque = a
	# 1. Combo por slot.
	if not a.combo.is_empty():
		var n := a.combo.size()
		e.mult = a.combo[r.passo_combo[slot] % n]
		r.passo_combo[slot] = (r.passo_combo[slot] + 1) % n
		r.janela_combo[slot] = _p.janela_combo
	# 2. M no disparo; fecha a janela apos_esquiva.
	var slot_mod := Modificador.Slot.ATAQUE if slot == RecursosDoJogador.SLOT_ATAQUE else Modificador.Slot.ESPECIAL
	e.dano_congelado = _portadores[r.player_id].congelar_dano(slot_mod, ContextoDeDano.new(float(r.vida), r.apos_esquiva > 0))
	e.m_sem = e.dano_congelado.m_no_impacto(0)
	r.apos_esquiva = 0
	# 3. Dano do golpe.
	e.dano_golpe = a.dano * e.mult
	# 4. Recarga.
	r.recarga[slot] = a.recarga
	if a.forma == AtaqueConvertido.FORMA_CHAMADO:
		# R3.1: sem guarda, finalizador, recuperação, hitbox ou hitstop.
		e.empurrao = a.empurrao
		var pos_j := _movimento.posicao(r.player_id)
		if _maldicoes != null:
			_maldicoes.pedir_chamado(r.player_id, r.ponto_mirado, e.dano_golpe, e.m_sem)
		_emitir(EventosDoCombate.EvChamado.new(r.player_id, pos_j, r.ponto_mirado))
		_disparos.append(e)
		return
	# 5. Guarda.
	if a.guarda > 0:
		r.guarda = a.guarda
	# 6. Finalizador (F3).
	e.finalizador = e.mult > t.limiar_finalizador
	e.empurrao = maxf(a.empurrao * e.mult, t.empurrao_pesado) if e.finalizador else a.empurrao
	e.pesado = e.finalizador or e.empurrao >= t.empurrao_pesado
	# 7. Recuperação (F2), fora da investida.
	if a.forma == AtaqueConvertido.FORMA_AVANCO:
		r.investida = a.passos_avanco
		r.slot_investida = slot
		r.atingidos_investida.clear()
		r.primeiro_alvo_investida_atingido = false
		r.dano_golpe_investida = e.dano_golpe
		r.dano_congelado_investida = e.dano_congelado
		r.empurrao_investida = a.empurrao
		r.status_investida = a.def.status
		if a.passos_avanco > 0:
			r.deslocamento_investida = r.mira * (a.param(&"distancia_px") / float(a.passos_avanco))
		garantir_invulneravel(r.player_id, a.passos_avanco + _p.invuln_extra_investida)
		_emitir(EventosDoCombate.EvInvestida.new(
			r.player_id, _movimento.posicao(r.player_id), r.mira, a.passos_avanco))
	else:
		r.recuperacao = mini(_p.recuperacao_max,
			FormulasDeModificadores.arredondar_meio_longe_do_zero(float(a.recarga) * t.fator_recuperacao_golpe))
	# 8. Forma (R4, R5, R6).
	if a.forma == AtaqueConvertido.FORMA_ARCO:
		_executar_forma_arco(r, e, a)
	elif a.forma == AtaqueConvertido.FORMA_CIRCULO:
		_executar_forma_circulo(r, e, a)
	elif a.forma == AtaqueConvertido.FORMA_PROJETIL:
		_executar_forma_projetil(r, e, a)
	_disparos.append(e)


func _executar_forma_arco(r: RecursosDoJogador, e: EstadoDeGolpe, a: AtaqueConvertido) -> void:
	var t := _p.tuning
	var pos_j := _movimento.posicao(r.player_id)
	var raio_j := _movimento.raio(r.player_id)
	var alcance := a.param(&"alcance_px")
	var meio_ang := a.param(&"meio_angulo_graus")
	var raio_encostado := raio_j + t.folga_encostado_px
	var golpe_pede_pesado := e.finalizador or e.slot == RecursosDoJogador.SLOT_ESPECIAL or e.empurrao >= t.empurrao_pesado
	var n_alvos := 0
	for ini in _ia.inimigos():
		if not _inimigo_atingivel(ini):
			continue
		if GeometriaDeAcerto.arco_do_golpe(pos_j, r.mira, a.cos_meio, alcance, raio_encostado, ini.posicao, ini.raio):
			n_alvos += 1
			var delta := ini.posicao - pos_j
			var u := r.mira if delta == Vector2.ZERO else delta.normalized()
			_ferir_inimigo_interno(
				ini, r.player_id, e.dano_golpe, e.dano_congelado,
				u, e.empurrao, a.def.status, true, e.finalizador,
				_nome_slot(e.slot), AtaqueConvertido.FORMA_ARCO,
				&"pesado" if golpe_pede_pesado else &"leve", false)
	_emitir(EventosDoCombate.EvGolpe.new(
		r.player_id, pos_j, r.mira, _nome_slot(e.slot), alcance, meio_ang, golpe_pede_pesado, n_alvos))
	if n_alvos >= 1:
		_pedir_hitstop(_p.hitstop_pesado if golpe_pede_pesado else _p.hitstop_leve)
	# Passo de apoio por último (R4).
	_movimento.deslocar(r.player_id, r.mira * t.passo_apoio_px)


func _executar_forma_circulo(r: RecursosDoJogador, e: EstadoDeGolpe, a: AtaqueConvertido) -> void:
	var t := _p.tuning
	var pos_j := _movimento.posicao(r.player_id)
	var raio_c := a.param(&"raio_px")
	var desloc := a.param(&"deslocamento_px")
	var centro := pos_j + r.mira * desloc
	var golpe_pede_pesado := e.finalizador or e.slot == RecursosDoJogador.SLOT_ESPECIAL or e.empurrao >= t.empurrao_pesado
	var n_alvos := 0
	for ini in _ia.inimigos():
		if not _inimigo_atingivel(ini):
			continue
		if GeometriaDeAcerto.circulo_toca(centro, raio_c, ini.posicao, ini.raio):
			n_alvos += 1
			var delta := ini.posicao - pos_j
			var u := r.mira if delta == Vector2.ZERO else delta.normalized()
			_ferir_inimigo_interno(
				ini, r.player_id, e.dano_golpe, e.dano_congelado,
				u, e.empurrao, a.def.status, true, e.finalizador,
				_nome_slot(e.slot), AtaqueConvertido.FORMA_CIRCULO,
				&"pesado" if golpe_pede_pesado else &"leve", false)
	_emitir(EventosDoCombate.EvArea.new(
		r.player_id, centro, raio_c, _nome_slot(e.slot), golpe_pede_pesado, n_alvos))
	if n_alvos >= 1:
		_pedir_hitstop(_p.hitstop_pesado if golpe_pede_pesado else _p.hitstop_leve)


func _executar_forma_projetil(r: RecursosDoJogador, e: EstadoDeGolpe, a: AtaqueConvertido) -> void:
	var t := _p.tuning
	var pos_j := _movimento.posicao(r.player_id)
	var indices: PackedFloat64Array = a.def.leque if not a.def.leque.is_empty() else PackedFloat64Array([0.0])
	var dir_primeiro := r.mira
	for idx_f: float in indices:
		var k := int(idx_f)
		var graus := FormulasDeCombate.angulo_leque_graus(k, t.giro_leque_graus)
		var dir_p := GeometriaDeAcerto.girar_graus(r.mira, graus).normalized()
		if k == int(indices[0]):
			dir_primeiro = dir_p
		var p_reg := ProjetilRegistro.new()
		p_reg.id = _proximo_id_projetil
		_proximo_id_projetil += 1
		p_reg.do_jogador = true
		p_reg.player_id = r.player_id
		p_reg.posicao = pos_j + dir_p * t.nascimento_projetil_px
		p_reg.direcao = dir_p
		p_reg.passo_px = a.passo_projetil_px
		p_reg.raio_px = a.param(&"raio_px")
		p_reg.vida_restante = a.vida_projetil
		p_reg.atravessa = a.def.atravessa
		p_reg.dano_golpe = e.dano_golpe
		p_reg.dano_congelado = e.dano_congelado
		p_reg.m_disparo = e.m_sem
		p_reg.empurrao = e.empurrao
		p_reg.status = a.def.status
		p_reg.finalizador = e.finalizador
		p_reg.pesado = e.pesado
		p_reg.slot_origem = e.slot
		_projeteis.append(p_reg)
	_emitir(EventosDoCombate.EvDisparo.new(r.player_id, pos_j, dir_primeiro, &"jogador"))


static func _nome_slot(slot: int) -> StringName:
	return &"ataque" if slot == RecursosDoJogador.SLOT_ATAQUE else &"especial"


# --- R8: Impacto em inimigo (_ferir_inimigo) ---------------------------------

## Caminho público de ferir inimigo (para Selo, testes diretos, etc.). Nunca pede hitstop (ADR-0010 §5).
func ferir_inimigo(alvo_id: int, dano: float, direcao: Vector2 = Vector2.RIGHT,
		empurrao: float = 0.0, status: StringName = &"", de_arma: bool = false,
		pesado_entrada: bool = false, origem: StringName = &"selo",
		autor_player_id: int = 0) -> void:
	var ini := _ia.obter_inimigo(alvo_id)
	if not _inimigo_atingivel(ini):
		return
	var emitir_ev_acerto := origem != &"selo"
	_ferir_inimigo_escalar(ini, autor_player_id, dano, direcao, empurrao, status,
		de_arma, pesado_entrada, &"nenhum", origem, &"pesado" if pesado_entrada else &"leve",
		emitir_ev_acerto)


## Caminho silencioso para dano por passo do Status e do Selo (R8: só itens 1 e 3).
func ferir_inimigo_de_status(alvo_id: int, dano: float, autor_player_id: int = 0) -> void:
	var ini := _ia.obter_inimigo(alvo_id)
	if not _inimigo_atingivel(ini):
		return
	var dano_ef := 0.0 if ini.invulneravel_por_fase else dano
	ini.vida -= dano_ef
	ini.autor_player_id = autor_player_id
	if ini.chefe and dano_ef > 0.0:
		_ia.notificar_dano_no_chefe(ini.id)


func _ferir_inimigo_interno(
		ini: ContratosDoCombate.InimigoCombate,
		player_id: int,
		dano_golpe: float,
		dano_congelado: DanoCongelado,
		direcao: Vector2,
		empurrao: float,
		status: StringName,
		de_arma: bool,
		pesado_entrada: bool,
		slot_nome: StringName,
		forma_nome: StringName,
		peso_visual_base: StringName,
		do_item_8: bool) -> void:
	if not _inimigo_atingivel(ini):
		return
	var t := _p.tuning
	var r := _recursos[player_id]
	var enesimo := false
	var dano_final := dano_golpe
	# 2. Golpe de arma
	if de_arma:
		r.contador_acertos += 1
		if dano_congelado != null:
			var m_sem := dano_congelado.m_no_impacto(0)
			var m_imp := dano_congelado.m_no_impacto(r.contador_acertos)
			enesimo = _eh_multiplo_enesimo(_portadores[player_id], r.contador_acertos)
			dano_final = dano_golpe * (m_imp if enesimo else m_sem)
	var pesado_impacto := pesado_entrada or enesimo or empurrao >= t.empurrao_pesado
	if de_arma:
		_emitir(EventosDoCombate.EvAcertoDeArma.new(player_id, ini.id, slot_nome, enesimo, pesado_impacto))
		if do_item_8:
			_selo.creditar_acerto_tardio(player_id, ini.id, enesimo, pesado_impacto)
	# 3. Vida -= dano (0 se invulnerável por TransicaoFase)
	var dano_aplicado := 0.0 if ini.invulneravel_por_fase else dano_final
	ini.vida -= dano_aplicado
	ini.autor_player_id = player_id
	if ini.chefe and dano_aplicado > 0.0:
		_ia.notificar_dano_no_chefe(ini.id)
	# 4 & 5. Evento acerto e peso_visual (R17)
	var peso_vis := peso_visual_base
	if forma_nome == AtaqueConvertido.FORMA_PROJETIL:
		peso_vis = &"pesado" if pesado_entrada else &"leve"
	elif enesimo and (forma_nome == AtaqueConvertido.FORMA_ARCO or forma_nome == AtaqueConvertido.FORMA_CIRCULO or forma_nome == AtaqueConvertido.FORMA_AVANCO):
		peso_vis = &"pesado"
	_emitir(EventosDoCombate.EvAcerto.new(
		ini.id, ini.posicao, direcao, dano_aplicado, pesado_impacto, enesimo, de_arma,
		slot_nome, forma_nome, peso_vis, _p.flash_acerto))
	_aplicar_empurrao_cambaleio_status(ini, direcao, empurrao, pesado_impacto, status)


func _ferir_inimigo_escalar(
		ini: ContratosDoCombate.InimigoCombate,
		autor_player_id: int,
		dano: float,
		direcao: Vector2,
		empurrao: float,
		status: StringName,
		de_arma: bool,
		pesado_entrada: bool,
		slot_nome: StringName,
		forma_nome: StringName,
		peso_visual_base: StringName,
		emitir_acerto: bool = true) -> void:
	var t := _p.tuning
	var dano_aplicado := 0.0 if ini.invulneravel_por_fase else dano
	ini.vida -= dano_aplicado
	ini.autor_player_id = autor_player_id
	if ini.chefe and dano_aplicado > 0.0:
		_ia.notificar_dano_no_chefe(ini.id)
	var pesado_impacto := pesado_entrada or empurrao >= t.empurrao_pesado
	var peso_vis := &"pesado" if (forma_nome == &"maldicao" and pesado_impacto) else peso_visual_base
	if emitir_acerto:
		_emitir(EventosDoCombate.EvAcerto.new(
			ini.id, ini.posicao, direcao, dano_aplicado, pesado_impacto, false, de_arma,
			slot_nome, forma_nome, peso_vis, _p.flash_acerto))
	_aplicar_empurrao_cambaleio_status(ini, direcao, empurrao, pesado_impacto, status)


func _aplicar_empurrao_cambaleio_status(
		ini: ContratosDoCombate.InimigoCombate,
		direcao: Vector2,
		empurrao: float,
		pesado_impacto: bool,
		status: StringName) -> void:
	# 6. Empurrão
	var fator_emp := _fator_empurrao_do_inimigo(ini)
	var dir_norm := Vector2.RIGHT if direcao == Vector2.ZERO else direcao.normalized()
	ini.vel_empurrao += dir_norm * (empurrao * fator_emp)
	# 7. Cambaleio e "Quebrou!" (só se não é chefe nem elite e empurrão de entrada > 0)
	if not ini.chefe and not ini.elite and empurrao > 0.0:
		ini.cambaleio = maxi(ini.cambaleio, _p.cambaleio)
		if pesado_impacto and ini.em_preparacao and ini.vida > 0.0:
			ini.em_preparacao = false
			_ia.pedir_recuperacao(ini.id, _p.quebrou_recuperacao)
			_telegrafos.quebrar(ini.id)
			_emitir(EventosDoCombate.EvQuebrou.new(ini.id, ini.posicao))
	# 8. Status síncrono
	if status != &"":
		_status.aplicar_status(ini.id, status, 1.0)


func _fator_empurrao_do_inimigo(ini: ContratosDoCombate.InimigoCombate) -> float:
	if ini.portador != null:
		return ini.portador.valor(Atributos.FATOR_EMPURRAO)
	if ini.chefe:
		return 0.12
	if ini.elite:
		return 0.4
	return 1.0


static func _eh_multiplo_enesimo(portador: Portador, contador: int) -> bool:
	if contador <= 0 or portador == null:
		return false
	for id_f in portador.ids_de_fontes():
		var f := portador.fonte_ativa(id_f)
		for m: Modificador in f.modificadores:
			if m.condicao == Modificador.Condicao.ENESIMO_ACERTO:
				var ac := FormulasDeModificadores.arredondar_meio_longe_do_zero(m.param)
				if ac > 0 and (contador % ac) == 0:
					return true
	return false


# --- Item 7: Impacto do inimigo e parede (R11, R12) --------------------------

## Item 7: aplica deslocamento de empurrão, colisão contra parede/obstáculos e desconta cambaleio.
## Com Vida <= 0 ou Subjugado, retorna sem fazer nada (R14: morto não age).
func impacto_do_inimigo(inimigo_id: int) -> void:
	var ini := _ia.obter_inimigo(inimigo_id)
	if ini == null or ini.vida <= 0.0 or ini.subjugado:
		return
	var t := _p.tuning
	var v := ini.vel_empurrao.length()
	if v > 0.0:
		var pos_tentativa := ini.posicao + ini.vel_empurrao / float(Unidades.TICK_RATE)
		var geo := _camaras.geometria()
		var res := Colisao.resolver_colisao_informando(pos_tentativa, ini.raio, geo)
		ini.posicao = res.pos
		if res.corrigida and v >= t.parede_vel_min:
			var normal_parede := (res.pos - pos_tentativa).normalized() if res.pos != pos_tentativa else -ini.vel_empurrao.normalized()
			ini.vel_empurrao = Vector2.ZERO
			_emitir(EventosDoCombate.EvParede.new(ini.id, ini.posicao, normal_parede))
			# Dano de parede: parede_dano * M_parede (grupo Ataque, Vida atual do jogador 0)
			var r0 := _recursos[0]
			var m_parede := _portadores[0].multiplicador_de_dano(
				Modificador.Slot.ATAQUE, ContextoDeDano.new(float(r0.vida), false))
			var pos_j := _movimento.posicao(0)
			var delta_ji := ini.posicao - pos_j
			var dir_ji := Vector2.RIGHT if delta_ji == Vector2.ZERO else delta_ji.normalized()
			_ferir_inimigo_escalar(
				ini, 0, t.parede_dano * m_parede, dir_ji, 0.0, &"",
				false, false, &"nenhum", &"parede", &"leve", true)
			_pedir_hitstop(_p.hitstop_leve)
	if ini.vel_empurrao != Vector2.ZERO:
		ini.vel_empurrao *= t.queda_empurrao
		if ini.vel_empurrao.length() < t.empurrao_zero:
			ini.vel_empurrao = Vector2.ZERO
	if ini.cambaleio > 0:
		ini.cambaleio -= 1


# --- Item 8: Projéteis em voo (R7, R22) --------------------------------------

## Cria um projétil de inimigo em voo e emite EvDisparo com dono "inimigo" (R7, R22, AC-32, AC-93).
func disparar_projetil(
		dono_inimigo_id: int,
		pos: Vector2,
		dir: Vector2,
		vel_pxs: float,
		raio: float,
		vida_s: float,
		dano_base: float,
		m_disparo: float,
		atravessa: bool = false,
		alvo_faccao: ContratosDoCombate.Faccao = ContratosDoCombate.Faccao.JOGADOR,
		alvo_id: int = 0,
		alvo_curse_id: StringName = &"",
		ataque_id: StringName = &"") -> ProjetilRegistro:
	var dir_n := Vector2.LEFT if dir == Vector2.ZERO else dir.normalized()
	var p_reg := ProjetilRegistro.new()
	p_reg.id = _proximo_id_projetil
	_proximo_id_projetil += 1
	p_reg.do_jogador = false
	p_reg.dono_inimigo_id = dono_inimigo_id
	p_reg.posicao = pos
	p_reg.direcao = dir_n
	p_reg.passo_px = vel_pxs / float(Unidades.TICK_RATE)
	p_reg.raio_px = raio
	p_reg.vida_restante = Unidades.duracao_para_passos(vida_s)
	p_reg.atravessa = atravessa
	p_reg.dano_golpe = dano_base
	p_reg.m_disparo = m_disparo
	p_reg.alvo_faccao = alvo_faccao
	p_reg.alvo_id = alvo_id
	p_reg.alvo_curse_id = alvo_curse_id
	p_reg.ataque_id = ataque_id
	_projeteis.append(p_reg)
	_emitir(EventosDoCombate.EvDisparo.new(-1, pos, dir_n, &"inimigo"))
	return p_reg


## Item 8: move projéteis, desconta vida, verifica retângulo/obstáculos e testa acerto (R7).
func projeteis() -> void:
	if _projeteis.is_empty():
		return
	var t := _p.tuning
	var geo := _camaras.geometria()
	var sobreviventes: Array[ProjetilRegistro] = []
	for p_reg in _projeteis:
		# 1. Move
		p_reg.posicao += p_reg.direcao * p_reg.passo_px
		# 2. Vida
		p_reg.vida_restante -= 1
		if p_reg.vida_restante <= 0:
			continue
		# 3. Retângulo e obstáculo
		if not _dentro_do_retangulo(p_reg.posicao, geo.jogavel):
			continue
		if _toca_obstaculo_projetil(p_reg, geo.obstaculos(), t.fator_raio_obstaculo_projetil):
			continue
		# 4. Acerto
		var sumiu := _testar_acerto_projetil(p_reg)
		if not sumiu:
			sobreviventes.append(p_reg)
	_projeteis = sobreviventes


static func _dentro_do_retangulo(pos: Vector2, r: Rect2) -> bool:
	return pos.x >= r.position.x and pos.x <= r.end.x and pos.y >= r.position.y and pos.y <= r.end.y


static func _toca_obstaculo_projetil(p_reg: ProjetilRegistro, obstaculos: Array[ObstaculoCircular],
		fator_raio: float) -> bool:
	var r_ef := p_reg.raio_px * fator_raio
	for o in obstaculos:
		var soma := o.raio + r_ef
		if p_reg.posicao.distance_squared_to(o.centro) < soma * soma:
			return true
	return false


func _testar_acerto_projetil(p_reg: ProjetilRegistro) -> bool:
	if p_reg.do_jogador:
		for ini in _ia.inimigos():
			if not _inimigo_atingivel(ini):
				continue
			if p_reg.atingidos.has(ini.id):
				continue
			if GeometriaDeAcerto.circulo_toca(p_reg.posicao, p_reg.raio_px, ini.posicao, ini.raio):
				p_reg.atingidos[ini.id] = true
				_ferir_inimigo_interno(
					ini, p_reg.player_id, p_reg.dano_golpe, p_reg.dano_congelado,
					p_reg.direcao, p_reg.empurrao, p_reg.status, true, p_reg.finalizador,
					_nome_slot(p_reg.slot_origem), AtaqueConvertido.FORMA_PROJETIL,
					&"pesado" if p_reg.finalizador else &"leve", true)
				if not p_reg.atravessa:
					return true
		return false
	# Projétil de inimigo (R7, R22, R25): só testa o seu alvo travado.
	match p_reg.alvo_faccao:
		ContratosDoCombate.Faccao.JOGADOR:
			var pid := p_reg.alvo_id
			if pid < 0 or pid >= _recursos.size():
				return false
			var r := _recursos[pid]
			var pos_j := _movimento.posicao(pid)
			var raio_j := _movimento.raio(pid)
			if GeometriaDeAcerto.circulo_toca(p_reg.posicao, p_reg.raio_px, pos_j, raio_j):
				if r.invulneravel > 0 or not _camaras.em_combate():
					# Jogador invulnerável ou fora de combate: atravessa e continua (R7, R13.1).
					return false
				if p_reg.atingidos.has(pid):
					return false
				p_reg.atingidos[pid] = true
				_ferir_jogador_interno(pid, p_reg.dano_golpe, p_reg.m_disparo, -1, p_reg.direcao, &"", p_reg.ataque_id)
				return not p_reg.atravessa
		ContratosDoCombate.Faccao.ALIADO:
			if _maldicoes == null or p_reg.alvo_curse_id == &"":
				return false
			var cid := p_reg.alvo_curse_id
			if not _maldicoes.maldicao_em_campo(cid):
				# Saiu de campo: voa até sumir sem ferir ninguém (R22).
				return false
			var pos_m := _maldicoes.posicao_maldicao(cid)
			var raio_m := _maldicoes.raio_maldicao(cid)
			if GeometriaDeAcerto.circulo_toca(p_reg.posicao, p_reg.raio_px, pos_m, raio_m):
				if _maldicoes.maldicao_saltando(cid) or not _maldicoes.maldicao_atingivel(cid) or not _camaras.em_combate():
					return false
				if p_reg.atingidos.has(cid):
					return false
				p_reg.atingidos[cid] = true
				ferir_maldicao(cid, p_reg.dano_golpe, p_reg.m_disparo, -1, p_reg.ataque_id, p_reg.direcao)
				return not p_reg.atravessa
		ContratosDoCombate.Faccao.ACUADA:
			if _vinculo == null or not _vinculo.acuada_atingivel():
				return false
			var pos_a := _vinculo.posicao_acuada()
			var raio_a := _vinculo.raio_acuada()
			if GeometriaDeAcerto.circulo_toca(p_reg.posicao, p_reg.raio_px, pos_a, raio_a):
				if not _camaras.em_combate():
					return false
				if p_reg.atingidos.has(&"acuada"):
					return false
				p_reg.atingidos[&"acuada"] = true
				ferir_acuada(p_reg.dano_golpe, p_reg.m_disparo, -1, p_reg.ataque_id)
				return not p_reg.atravessa
	return false


# --- R13: Dano no jogador (ferir_jogador) ------------------------------------

## Aplica dano ao jogador [param player_id] (R13, F10). [param atacante_id] = -1 para projétil (sem reflexo).
func ferir_jogador(player_id: int, dano_base: float, m_atacante: float = 1.0,
		atacante_id: int = -1, ataque_id: StringName = &"",
		atacante_tipo: StringName = &"") -> void:
	var dir_golpe := Vector2.LEFT
	if atacante_id >= 0:
		var ini := _ia.obter_inimigo(atacante_id)
		if ini != null:
			var delta := _movimento.posicao(player_id) - ini.posicao
			dir_golpe = Vector2.LEFT if delta == Vector2.ZERO else delta.normalized()
			if atacante_tipo == &"":
				atacante_tipo = ini.tipo_id
	_ferir_jogador_interno(player_id, dano_base, m_atacante, atacante_id, dir_golpe, atacante_tipo, ataque_id)


func _ferir_jogador_interno(player_id: int, dano_base: float, m_atacante: float,
		atacante_id: int, dir_ao_jogador: Vector2, atacante_tipo: StringName,
		ataque_id: StringName) -> void:
	var r := _recursos[player_id]
	# 1. Nada acontece se invulnerável ou fora de combate.
	if r.invulneravel > 0 or not _camaras.em_combate():
		return
	var t := _p.tuning
	var port := _portadores[player_id]
	# 2. Fórmula F10 / F3 do Modificadores (1 único arredondamento).
	var fator_g := t.fator_guarda if r.guarda > 0 else 1.0
	var reducao := port.valor(Atributos.REDUCAO_DANO)
	var dano := FormulasDeModificadores.dano_recebido(
		dano_base * m_atacante, reducao, _teto_reducao_dano, fator_g)
	# 3. Escudo absorve até dano.
	var v_perdida := FormulasDeModificadores.vida_perdida(dano, r.escudo)
	r.escudo = FormulasDeModificadores.escudo_restante(dano, r.escudo)
	# 4. Vida -= vida_perdida; invulnerabilidade mesmo com absorção total.
	r.vida -= v_perdida
	r.invulneravel = maxi(r.invulneravel, _p.invuln_atingido)
	r.ultimo_atacante_tipo = atacante_tipo
	r.ultimo_ataque_id = ataque_id
	# 5. Hitstop de jogador atingido e evento jogador_atingido.
	_pedir_hitstop(_p.hitstop_atingido)
	var inversao := _p.hitstop_atingido + _p.extra_inversao
	_emitir(EventosDoCombate.EvJogadorAtingido.new(
		player_id, v_perdida, dir_ao_jogador, inversao, r.invulneravel, atacante_id, ataque_id))
	# 6. Refletir (antes do teste de morte): atacante corpo a corpo e vida_perdida > 0.
	if atacante_id >= 0 and v_perdida > 0:
		var gat_ref := port.gatilhos(&"refletir_dano")
		if gat_ref.total > 0.0:
			var ini_at := _ia.obter_inimigo(atacante_id)
			if _inimigo_atingivel(ini_at):
				var pos_j := _movimento.posicao(player_id)
				var delta_ja := ini_at.posicao - pos_j
				var dir_ja := Vector2.RIGHT if delta_ja == Vector2.ZERO else delta_ja.normalized()
				_ferir_inimigo_escalar(
					ini_at, player_id, float(v_perdida) * gat_ref.total, dir_ja, 0.0, &"",
					false, false, &"nenhum", &"reflexo", &"leve", true)
	# 7. Morte ou recusa.
	if r.vida <= 0:
		var gat_rec := port.gatilhos(&"recusas_morte")
		if r.recusas > 0:
			var vida_ao_voltar: float = gat_rec.params.get(&"vida_ao_voltar", 0.4)
			var invuln_rec_s: float = gat_rec.params.get(&"invuln_s", 2.0)
			var v_max := port.inteiro(Atributos.VIDA_MAX)
			r.vida = maxi(1, FormulasDeModificadores.arredondar_meio_longe_do_zero(float(v_max) * vida_ao_voltar))
			var inv_rec := Unidades.duracao_para_passos(invuln_rec_s)
			r.invulneravel = maxi(r.invulneravel, inv_rec)
			r.recusas -= 1
			_pedir_hitstop(_p.hitstop_recusa)
			_emitir(EventosDoCombate.EvRecusouMorte.new(
				player_id, r.vida, _p.hitstop_recusa, r.invulneravel))
		else:
			r.vida = 0
			r.morto = true
			r.morto_neste_passo = true
			var causa: Variant = null
			if r.ultimo_atacante_tipo != &"" or r.ultimo_ataque_id != &"":
				causa = {"atacante_tipo": r.ultimo_atacante_tipo, "ataque_id": r.ultimo_ataque_id}
			_emitir(EventosDoCombate.EvJogadorMorreu.new(player_id, causa))


# --- Item 9: Varredura de mortes (R14, R24) ----------------------------------

## Item 9: até passes_varredura passes com retrato no início de cada passe.
func varredura_de_mortes() -> void:
	var max_passes := _p.tuning.passes_varredura
	for _passe in max_passes:
		var retrato: Array[ContratosDoCombate.InimigoCombate] = []
		for ini in _ia.inimigos():
			if ini.vida <= 0.0 and not ini.subjugado:
				retrato.append(ini)
		if retrato.is_empty():
			break
		for m in retrato:
			_processar_morto_no_passe(m)
	# No fim do item 9, se algum jogador morreu sem recusa, pede estado MORTE (ADR-0010 §2, §4).
	for r in _recursos:
		if r.morto_neste_passo:
			r.morto_neste_passo = false
			if _pedir_estado.is_valid():
				_pedir_estado.call(EstadoDeJogo.Valor.MORTE)


func _processar_morto_no_passe(m: ContratosDoCombate.InimigoCombate) -> void:
	var autor_id := clampi(m.autor_player_id, 0, _recursos.size() - 1)
	var r_autor := _recursos[autor_id]
	var port_autor := _portadores[autor_id]
	if m.chefe:
		# R24: queda do chefe (com ou sem subjugavel) pede hitstop 36, zera outros inimigos,
		# remove projéteis inimigos e emite chefe_vencido.
		_pedir_hitstop(_p.hitstop_abate_chefe)
		for outro in _ia.inimigos():
			if outro.id != m.id and outro.vida > 0.0 and not outro.subjugado:
				outro.vida = 0.0
				outro.autor_player_id = autor_id
				if outro.invocado_pelo_chefe:
					outro.limpo_pelo_chefe = true
		_remover_projeteis_inimigos()
		_emitir(EventosDoCombate.EvChefeVencido.new(
			m.id, m.posicao, m.subjugavel, autor_id, _p.impact_chefe))
		if m.subjugavel:
			m.vida = 0.0
			m.subjugado = true
			_ia.subjugar(m.id)
			return
	# Remoção da lista da IA preservando a ordem.
	_ia.remover_morto(m.id)
	if m.limpo_pelo_chefe:
		# Lacaio zerado pela queda do chefe: sai sem abate +1, sem cura, sem explosão e sem hitstop próprio.
		_emitir(EventosDoCombate.EvInimigoMorreu.new(
			m.id, m.posicao, m.elite, m.chefe, m.vel_empurrao, 0, autor_id, true))
		return
	r_autor.abates += 1
	var impact := _p.impact_chefe if m.chefe else 0
	_emitir(EventosDoCombate.EvInimigoMorreu.new(
		m.id, m.posicao, m.elite, m.chefe, m.vel_empurrao, impact, autor_id, false))
	if m.chefe:
		_pedir_hitstop(_p.hitstop_abate_chefe)
	elif m.elite:
		_pedir_hitstop(_p.hitstop_pesado)
	else:
		_pedir_hitstop(_p.hitstop_abate)
	# cura_ao_abater (exceto se o jogador já está morto neste passo, R14).
	if not r_autor.morto:
		var gat_cura := port_autor.gatilhos(&"cura_ao_abater")
		if gat_cura.total > 0.0:
			var v_max := port_autor.inteiro(Atributos.VIDA_MAX)
			var cura_int := FormulasDeModificadores.arredondar_meio_longe_do_zero(gat_cura.total)
			r_autor.vida = mini(v_max, r_autor.vida + cura_int)
	# explosao_ao_abater: dano sem M em todo inimigo atingível a <= raio_px + r_alvo.
	var gat_exp := port_autor.gatilhos(&"explosao_ao_abater")
	if gat_exp.total > 0.0:
		var raio_exp: float = gat_exp.params.get(&"raio_px", 60.0)
		var emp_exp: float = gat_exp.params.get(&"empurrao", 0.0)
		_emitir(EventosDoCombate.EvExplosao.new(m.posicao, raio_exp))
		for alvo in _ia.inimigos():
			if not _inimigo_atingivel(alvo):
				continue
			if GeometriaDeAcerto.circulo_toca(m.posicao, raio_exp, alvo.posicao, alvo.raio):
				var delta := alvo.posicao - m.posicao
				var dir_e := Vector2.RIGHT if delta == Vector2.ZERO else delta.normalized()
				_ferir_inimigo_escalar(
					alvo, autor_id, gat_exp.total, dir_e, emp_exp, &"",
					false, false, &"nenhum", &"explosao", &"leve", true)


func _remover_projeteis_inimigos() -> void:
	var do_jogador: Array[ProjetilRegistro] = []
	for p_reg in _projeteis:
		if p_reg.do_jogador:
			do_jogador.append(p_reg)
	_projeteis = do_jogador


# --- R20, R21, R24, R25: Pactos (Maldição, acuada e chefe Subjugado) ---------

## R20: Golpe da Maldição aliada no item 6.1 (sem arma, sem hitstop, autor = dono).
func aplicar_golpe_maldicao(
		player_id: int,
		_curse_id: StringName,
		alvos_ids: Array[int],
		dano_golpe: float,
		m_maldicao: float,
		direcao: Vector2,
		empurrao: float,
		status: StringName = &"",
		pesado: bool = false,
		_ataque_id: StringName = &"") -> void:
	for alvo_id in alvos_ids:
		var ini := _ia.obter_inimigo(alvo_id)
		if not _inimigo_atingivel(ini):
			continue
		var dir_ef := direcao
		if dir_ef == Vector2.ZERO and _maldicoes != null:
			var delta := ini.posicao - _maldicoes.posicao_maldicao(_curse_id)
			dir_ef = Vector2.RIGHT if delta == Vector2.ZERO else delta.normalized()
		_ferir_inimigo_escalar(
			ini, player_id, dano_golpe * m_maldicao, dir_ef, empurrao, status,
			false, pesado, &"nenhum", &"maldicao",
			&"pesado" if (pesado or empurrao >= _p.tuning.empurrao_pesado) else &"leve",
			true)


## R21 / F12: Dano na Maldição em campo, com Exaustão síncrona se Vida <= 0.
func ferir_maldicao(
		curse_id: StringName,
		dano_base: float,
		m_atacante: float = 1.0,
		atacante_id: int = -1,
		ataque_id: StringName = &"",
		direcao_voo: Vector2 = Vector2.ZERO) -> void:
	if _maldicoes == null or not _maldicoes.maldicao_atingivel(curse_id) or not _camaras.em_combate():
		return
	var port_m := _maldicoes.portador_maldicao(curse_id)
	var red_m := port_m.valor(Atributos.REDUCAO_DANO) if port_m != null else 0.0
	var dano_m := FormulasDeCombate.dano_na_maldicao(dano_base, m_atacante, red_m, _teto_reducao_dano)
	var vida_ant := _maldicoes.vida_maldicao(curse_id)
	var vida_nova := maxi(0, vida_ant - dano_m)
	_maldicoes.definir_vida_maldicao(curse_id, vida_nova)
	var dono_id := _maldicoes.dono_maldicao(curse_id)
	var pos_m := _maldicoes.posicao_maldicao(curse_id)
	var dir_ev := direcao_voo
	if dir_ev == Vector2.ZERO and atacante_id >= 0:
		var ini_at := _ia.obter_inimigo(atacante_id)
		if ini_at != null:
			var delta := pos_m - ini_at.posicao
			dir_ev = Vector2.LEFT if delta == Vector2.ZERO else delta.normalized()
	_emitir(EventosDoCombate.EvMaldicaoAtingida.new(
		dono_id, curse_id, dano_m, vida_nova, dir_ev, atacante_id, ataque_id))
	if vida_nova <= 0:
		_maldicoes.exaurir(curse_id)
		_emitir(EventosDoCombate.EvMaldicaoExausta.new(
			dono_id, curse_id, pos_m, atacante_id, ataque_id))


## R25 / F13: Dano na Maldição acuada do encontro de pacto, com falha síncrona se Vida <= 0.
func ferir_acuada(
		dano_base: float,
		m_atacante: float = 1.0,
		atacante_id: int = -1,
		ataque_id: StringName = &"") -> void:
	if _vinculo == null or not _vinculo.acuada_atingivel() or not _camaras.em_combate():
		return
	var dano_a := FormulasDeCombate.dano_na_acuada(dano_base, m_atacante)
	var vida_ant := _vinculo.vida_acuada()
	var vida_nova := maxi(0, vida_ant - dano_a)
	_vinculo.definir_vida_acuada(vida_nova)
	_emitir(EventosDoCombate.EvAcuadaAtingida.new(dano_a, vida_nova, atacante_id, ataque_id))
	if vida_nova <= 0:
		_vinculo.falhar_encontro()
		_emitir(EventosDoCombate.EvEncontroFalhou.new(atacante_id, ataque_id))


## R24: Resolve o chefe em estado Subjugado (&"exorcizar" ou &"pactuar").
func resolver_subjugado(inimigo_id: int, escolha: StringName) -> void:
	var ini := _ia.obter_inimigo(inimigo_id)
	if ini == null or not ini.subjugado:
		return
	_ia.remover_morto(ini.id)
	if escolha == &"exorcizar":
		var autor_id := clampi(ini.autor_player_id, 0, _recursos.size() - 1)
		var r_autor := _recursos[autor_id]
		var port_autor := _portadores[autor_id]
		r_autor.abates += 1
		_emitir(EventosDoCombate.EvInimigoMorreu.new(
			ini.id, ini.posicao, ini.elite, ini.chefe, ini.vel_empurrao, 0, autor_id, false))
		if not r_autor.morto:
			var gat_cura := port_autor.gatilhos(&"cura_ao_abater")
			if gat_cura.total > 0.0:
				var v_max := port_autor.inteiro(Atributos.VIDA_MAX)
				var cura_int := FormulasDeModificadores.arredondar_meio_longe_do_zero(gat_cura.total)
				r_autor.vida = mini(v_max, r_autor.vida + cura_int)


# --- Contrato do Movimento (R18; ADR-0008) -----------------------------------

## "Em recuperação" = recuperação > 0 (Movimento R4).
func em_recuperacao(player_id: int) -> bool:
	return _recursos[player_id].recuperacao > 0


## Investida ativa (contador > 0).
func investida_ativa(player_id: int) -> bool:
	return _recursos[player_id].investida > 0


## Deslocamento por passo da investida (zero sem investida).
func deslocamento_investida(player_id: int) -> Vector2:
	return _recursos[player_id].deslocamento_investida


## Vida atual do jogador como float (consulta contexto_de_dano do Movimento R8).
func vida_atual(player_id: int) -> float:
	return float(_recursos[player_id].vida)


## [code]cancelar[/code] (R18): zera investida e recuperação.
func cancelar(player_id: int) -> void:
	var r := _recursos[player_id]
	r.investida = 0
	r.deslocamento_investida = Vector2.ZERO
	r.atingidos_investida.clear()
	r.recuperacao = 0


## Invulnerabilidade por máximo (contrato da F4 do Movimento).
func garantir_invulneravel(player_id: int, n: int) -> void:
	var r := _recursos[player_id]
	r.invulneravel = maxi(r.invulneravel, n)


## Início da esquiva: se o portador tem [code]apos_esquiva[/code], reinicia a janela inteira
## para [code]passos(janela_s)[/code] (GDD R18: "Uma esquiva nova reinicia a janela inteira").
func esquiva_iniciada(player_id: int) -> void:
	var port := _portadores[player_id]
	var janela_s := 0.0
	for id in port.ids_de_fontes():
		for m: Modificador in port.fonte_ativa(id).modificadores:
			if m.condicao == Modificador.Condicao.APOS_ESQUIVA:
				janela_s = maxf(janela_s, m.param)
	var r := _recursos[player_id]
	if janela_s > 0.0:
		r.apos_esquiva = Unidades.duracao_para_passos(janela_s)


## [code]aplicar_corte[/code] (R18): chama a R8 com o dano pronto (Movimento já aplicou M),
## [code]de_arma[/code] falso e [code]pesado[/code] falso. Não pede hitstop.
func aplicar_corte(player_id: int, alvo_id: int, dano: float, dir: Vector2,
		empurrao: float, sangramento: float) -> void:
	var ini := _ia.obter_inimigo(alvo_id)
	if not _inimigo_atingivel(ini):
		return
	var status_corte: StringName = &"sangramento" if sangramento > 0.0 else &""
	var t := _p.tuning
	var pesado_imp := empurrao >= t.empurrao_pesado
	_ferir_inimigo_escalar(
		ini, player_id, dano, dir, empurrao, status_corte,
		false, false, &"nenhum", &"corte",
		&"pesado" if pesado_imp else &"leve", true)
	if sangramento > 1.0:
		_status.aplicar_status(ini.id, &"sangramento", sangramento - 1.0)
