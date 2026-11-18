class_name ModuloDeMaldicoes
extends ConsultaDaMaldicao
## Fachada principal das Maldições aliadas (item 6.1 do passo vivo;
## GDD maldicoes.md R1–R24, F1–F7; ADR-0017, ADR-0003, ADR-0009, ADR-0010, ADR-0018).

const TAMANHO_MAXIMO_DUPLA: int = 2
const REDUCAO_EXAUSTA_VINCULO_INQUEBRAVEL: float = 0.20
const FATOR_ANDAR_PRESENCA_DO_LIMIAR: float = 0.80

var _tuning: MaldicoesTuning = null
var _mod_tuning: ModifiersTuning = null
var _catalogo_especies: Dictionary[StringName, CurseDef] = {}
var _ia: ModuloDeIA = null
var _combate_aliado: ContextoDaTecnica.CombateAliado = null
var _status_aliado: ContextoDaTecnica.StatusAliado = null
var _eventos: EventosDoPasso = null
var _gerador_ids: GeradorDeIds = null
var _espelho_dupla: EspelhoDaDupla = null
var _geometria: GeometriaDeMovimento = null
var _respiro_atracao_passos: int = 30

var _pactos: Array[EstadoDoPacto] = []
var _por_id: Dictionary[int, MaldicaoRef] = {}
var _pos_jogadores: Dictionary[int, Vector2] = {0: Vector2(960.0, 930.0)}
var _mira_jogadores: Dictionary[int, Vector2] = {0: Vector2.RIGHT}


## Cria o módulo validando o tuning; devolve null se `tuning` for nulo ou inválido (ADR-0017 §1).
static func criar(p_tuning: MaldicoesTuning, p_especies: Dictionary[StringName, CurseDef] = {},
		p_ia: ModuloDeIA = null, p_combate: ContextoDaTecnica.CombateAliado = null,
		p_status: ContextoDaTecnica.StatusAliado = null, p_eventos: EventosDoPasso = null,
		p_gerador_ids: GeradorDeIds = null, p_mod_tuning: ModifiersTuning = null,
		p_espelho: EspelhoDaDupla = null, p_geometria: GeometriaDeMovimento = null) -> ModuloDeMaldicoes:
	if p_tuning == null or p_tuning.alcance_fio_px <= p_tuning.distancia_seguir_px:
		return null
	var m := ModuloDeMaldicoes.new()
	m.configurar(p_tuning, p_especies, p_ia, p_combate, p_status, p_eventos,
		p_gerador_ids, p_mod_tuning, p_espelho, p_geometria)
	return m


func configurar(p_tuning: MaldicoesTuning = null, p_especies: Dictionary[StringName, CurseDef] = {},
		p_ia: ModuloDeIA = null, p_combate: ContextoDaTecnica.CombateAliado = null,
		p_status: ContextoDaTecnica.StatusAliado = null, p_eventos: EventosDoPasso = null,
		p_gerador_ids: GeradorDeIds = null, p_mod_tuning: ModifiersTuning = null,
		p_espelho: EspelhoDaDupla = null, p_geometria: GeometriaDeMovimento = null) -> void:
	_tuning = p_tuning.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as MaldicoesTuning if p_tuning != null else CatalogoMaldicoes.tuning_de_fabrica()
	_mod_tuning = _normalizar_mod_tuning(p_mod_tuning)
	_catalogo_especies = p_especies.duplicate() if not p_especies.is_empty() else CatalogoMaldicoes.especies_mvp()
	_ia = p_ia
	_combate_aliado = p_combate
	_status_aliado = p_status if p_status != null else ContextoDaTecnica.StatusNulo.new()
	_eventos = p_eventos
	_gerador_ids = p_gerador_ids if p_gerador_ids != null else GeradorDeIds.new()
	_espelho_dupla = p_espelho if p_espelho != null else EspelhoDaDupla.new()
	_geometria = p_geometria


func definir_posicao_jogador(player_id: int, pos: Vector2, mira: Vector2 = Vector2.RIGHT) -> void:
	_pos_jogadores[player_id] = pos
	if mira.length_squared() > 0.0:
		_mira_jogadores[player_id] = mira.normalized()


func espelho_da_dupla() -> EspelhoDaDupla:
	return _espelho_dupla


## Monta a dupla inicial do jogador antes da expedição (R2, R24, AC-ML-03, AC-ML-34; ADR-0017 §2, §12).
func iniciar_dupla(player_id: int, especies_ids: Array[StringName],
		niveis_vinculo: Dictionary[StringName, int] = {},
		vinculo_tuning: VinculoTuning = null) -> void:
	var pacto := _garantir_pacto(player_id)
	pacto.campo = null
	pacto.reserva = null
	pacto.todas.clear()
	pacto.recarga_troca = 0
	pacto.recarga_troca_total = Unidades.duracao_para_passos(_tuning.recarga_troca_s)
	pacto.marca_virote = -1
	pacto.chamado_pendente = false
	pacto.ids_atraidos.clear()
	pacto.ids_imobilizados.clear()
	pacto.ids_marcados_saida.clear()

	var pos_jog: Vector2 = _pos_jogadores.get(player_id, Vector2(960.0, 930.0))
	for idx in mini(TAMANHO_MAXIMO_DUPLA, especies_ids.size()):
		var esp_id: StringName = especies_ids[idx]
		var def: CurseDef = _catalogo_especies.get(esp_id, null)
		if def == null:
			continue
		var nivel: int = int(niveis_vinculo.get(esp_id, 1))
		var m_ref: MaldicaoRef = _criar_maldicao_ref(player_id, def, nivel, vinculo_tuning)
		pacto.todas.append(m_ref)
		if idx == 0:
			m_ref.estado = MaldicaoRef.Estado.SEGUINDO
			m_ref.pos = Vector2(pos_jog.x, pos_jog.y + _tuning.distancia_seguir_px)
			if _ia != null:
				m_ref.pos = _ia.conter(m_ref.pos, m_ref.raio_px())
			pacto.campo = m_ref
		else:
			m_ref.estado = MaldicaoRef.Estado.PRONTA
			m_ref.acum_regen = 0.0
			pacto.reserva = m_ref


func _criar_maldicao_ref(player_id: int, def: CurseDef, nivel_vinculo: int = 1,
		vt: VinculoTuning = null) -> MaldicaoRef:
	var id_novo := _gerador_ids.proximo()
	var m := MaldicaoRef.new()
	m.id = id_novo
	m.player_id = player_id
	m.especie_id = def.id
	m.def = def
	m.nivel_vinculo = maxi(1, nivel_vinculo)

	# Fontes do portador: especie:<id> (Carapaça Ancorada +15% redução de dano) e vinculo:<id> (nível >= 2: +5% vida_max)
	var mods_esp: Array[Modificador] = []
	if def.passivas.has(&"carapaca_ancorada"):
		mods_esp.append(Modificador.new(Atributos.REDUCAO_DANO, Modificador.Operacao.PLANO, 0.15))
	var fonte_esp := FonteDeModificador.new(StringName("especie:%s" % def.id), mods_esp) if not mods_esp.is_empty() else null

	var fonte_vinc: FonteDeModificador = null
	var bonus_vida := vt.bonus_vida if vt != null else 0.05
	var mult_rec := vt.mult_recuperacao if vt != null else 0.90
	var bonus_atk := vt.bonus_dano_basico if vt != null else 0.05
	if m.nivel_vinculo >= 2:
		fonte_vinc = FonteDeModificador.new(StringName("vinculo:%s" % def.id), [
			Modificador.new(Atributos.VIDA_MAX, Modificador.Operacao.PERCENTUAL, bonus_vida),
		])
	if m.nivel_vinculo >= 3:
		m.mult_recuperacao_vinculo = mult_rec
	if m.nivel_vinculo >= 4:
		m.bonus_dano_basico_vinculo = bonus_atk

	var espelho_jog := _espelho_dupla.espelho_de(player_id) if _espelho_dupla != null else null
	m.portador = PortadorDaMaldicao.criar(id_novo, player_id, def, _mod_tuning, fonte_esp, fonte_vinc, espelho_jog)
	m.vida = m.vida_max()
	_por_id[id_novo] = m
	return m


## R24 / AC-ML-33: Acrescenta uma 2ª Maldição à dupla no meio da run (quando a dupla tinha 1 só).
func acrescentar_a_dupla(player_id: int, def: CurseDef, vida_acuada: float,
		nivel_vinculo: int = 1, vt: VinculoTuning = null) -> MaldicaoRef:
	if def == null:
		return null
	var pacto := _garantir_pacto(player_id)
	if pacto.todas.size() >= TAMANHO_MAXIMO_DUPLA:
		return null
	var m := _criar_maldicao_ref(player_id, def, nivel_vinculo, vt)
	var v_max := m.vida_max()
	var vida_inicial := int(PortadorDaMaldicao.vida_ao_nascer_no_pacto(vida_acuada, v_max))
	m.vida = clampi(vida_inicial, 1, v_max)
	m.estado = MaldicaoRef.Estado.PRONTA
	m.acum_regen = 0.0
	pacto.todas.append(m)
	pacto.reserva = m
	return m


# --- Item 6.1 do passo vivo: 8 sub-passos na ordem canônica da R23 (ADR-0017 §3) -

func passo_maldicoes(comandos: Array[ComandosDoPasso] = []) -> void:
	for player_id in _pactos.size():
		var pacto := _pactos[player_id]
		if pacto == null:
			continue
		var cmd: ComandosDoPasso = comandos[player_id] if player_id < comandos.size() else null
		_executar_6_1_jogador(pacto, cmd)


func passo_jogador(player_id: int, quer_troca_manual: bool = false) -> void:
	var pacto := _garantir_pacto(player_id)
	_executar_6_1_interno(pacto, quer_troca_manual)


func _executar_6_1_jogador(pacto: EstadoDoPacto, cmd: ComandosDoPasso) -> void:
	var quer_troca := false
	if cmd != null and cmd.quer(&"troca"):
		cmd.consumir(&"troca")
		quer_troca = true
	_executar_6_1_interno(pacto, quer_troca)


func _executar_6_1_interno(pacto: EstadoDoPacto, quer_troca_manual: bool) -> void:
	var ctx := _montar_contexto(pacto)

	# Sub-passo 1: Fins de atração e imobilização do passo anterior (R20)
	_subpasso_1_fins_de_controle(pacto)

	# Sub-passo 2: Contadores (`recarga_troca -1`, `restante_exausta -1`, regeneração F2, `portador.avancar(1)`)
	_subpasso_2_contadores_e_regeneracao(pacto)

	# Sub-passo 3: Campo vazio e uma Pronta -> entra sem técnica (`maldicao_entrou(retorno)`)
	_subpasso_3_reentrada_campo_vazio(pacto, ctx)

	# Sub-passo 4: Chamado pedido no item 5 -> começa o salto (`Saltando`, `chamado_salto`)
	var iniciou_salto_neste_passo := false
	if pacto.chamado_pendente:
		pacto.chamado_pendente = false
		if pacto.campo != null and pacto.campo.estado != MaldicaoRef.Estado.SALTANDO:
			ChamadoDoPacto.iniciar_salto(
				pacto.campo, ctx, pacto.chamado_ponto,
				pacto.chamado_dano, pacto.chamado_m, _geometria)
			iniciou_salto_neste_passo = true

	# Sub-passo 5: Troca manual do buffer -> testa R11 (recusada com `saltando` se o passo 4 começou o salto, AC-ML-32)
	if quer_troca_manual:
		TrocaDeMaldicao.tentar_troca_manual(ctx)

	# Sub-passo 6: Salto em curso avança; no passo de pouso aplica golpe, imobilização, atração e efeito próprio
	if pacto.campo != null and pacto.campo.estado == MaldicaoRef.Estado.SALTANDO and not iniciou_salto_neste_passo:
		ChamadoDoPacto.avancar_salto(pacto.campo, ctx)

	# Sub-passo 7: Fio (F1), alvo (R4), passivas condicionais (R22) e movimento
	if pacto.campo != null and pacto.campo.em_campo() and pacto.campo.estado != MaldicaoRef.Estado.SALTANDO:
		IADeAliado.passo(pacto.campo, ctx)

	# Sub-passo 8: Ataque básico por fases (o impacto vai pela R20 do Combate)
	if pacto.campo != null and pacto.campo.em_campo() and pacto.campo.estado != MaldicaoRef.Estado.SALTANDO:
		AtaqueDaMaldicao.passo(pacto.campo, ctx)


func _subpasso_1_fins_de_controle(pacto: EstadoDoPacto) -> void:
	if _ia == null:
		return
	var ainda_atraidos: Array[int] = []
	for id_in: int in pacto.ids_atraidos:
		if _ia.esta_atraido(id_in):
			ainda_atraidos.append(id_in)
		elif _eventos != null:
			_eventos.emitir(EventosMaldicoes.EvAtracaoFim.new(id_in))
	pacto.ids_atraidos = ainda_atraidos

	var ainda_imob: Array[int] = []
	for id_in: int in pacto.ids_imobilizados:
		if _ia.esta_imobilizado(id_in):
			ainda_imob.append(id_in)
		elif _eventos != null:
			_eventos.emitir(EventosMaldicoes.EvImobilizacaoFim.new(id_in))
	pacto.ids_imobilizados = ainda_imob


func _subpasso_2_contadores_e_regeneracao(pacto: EstadoDoPacto) -> void:
	if pacto.recarga_troca > 0:
		pacto.recarga_troca = maxi(0, pacto.recarga_troca - 1)
	for m: MaldicaoRef in pacto.todas:
		if m.portador != null:
			m.portador.avancar(1)
		if m.estado == MaldicaoRef.Estado.EXAUSTA:
			m.restante_exausta = maxi(0, m.restante_exausta - 1)
			if m.restante_exausta == 0:
				# F2: passa a Pronta com Vida_retorno = clamp(round(vida_max * vida_retorno_frac), 1, vida_max) e acum_regen = 0
				m.estado = MaldicaoRef.Estado.PRONTA
				var v_max := m.vida_max()
				var v_ret := Unidades.arredondar_meio_longe_do_zero(float(v_max) * _tuning.vida_retorno_frac)
				m.vida = clampi(v_ret, 1, v_max)
				m.acum_regen = 0.0
				if _eventos != null:
					_eventos.emitir(EventosMaldicoes.EvMaldicaoPronta.new(m.id))
		elif m.estado == MaldicaoRef.Estado.PRONTA and m == pacto.reserva:
			# F2: regeneração fracionária na reserva
			var v_max := m.vida_max()
			if m.vida < v_max:
				m.acum_regen += (float(v_max) * _tuning.regen_reserva_frac_s) / float(Unidades.TICK_RATE)
				var ganho := int(floor(m.acum_regen + 1e-9))
				if ganho > 0:
					m.vida = mini(v_max, m.vida + ganho)
					m.acum_regen = 0.0 if m.vida >= v_max else maxf(0.0, m.acum_regen - float(ganho))
			else:
				m.acum_regen = 0.0


func _subpasso_3_reentrada_campo_vazio(pacto: EstadoDoPacto, ctx: ContextoDaTecnica) -> void:
	if pacto.campo != null:
		return
	# Escolhe a Pronta que ficou Exausta primeiro (menor ordem_exaustao)
	var candidata: MaldicaoRef = null
	for m: MaldicaoRef in pacto.todas:
		if m.estado == MaldicaoRef.Estado.PRONTA:
			if candidata == null or m.ordem_exaustao < candidata.ordem_exaustao:
				candidata = m
	if candidata == null:
		return
	if pacto.reserva == candidata:
		# A outra continua na reserva (se existir)
		var outra: MaldicaoRef = null
		for m: MaldicaoRef in pacto.todas:
			if m != candidata:
				outra = m
				break
		pacto.reserva = outra
	pacto.campo = candidata
	candidata.estado = MaldicaoRef.Estado.SEGUINDO
	candidata.estourou_fio = false
	candidata.alvo_id = -1
	candidata.pos = _ia.conter(ctx.pos_jogador, candidata.raio_px()) if _ia != null else ctx.pos_jogador
	if _eventos != null:
		_eventos.emitir(EventosMaldicoes.EvMaldicaoEntrou.new(candidata.id, &"retorno"))


# --- Contratos com o Combate (R3.1, R8, R9, R21, R22; ADR-0010 §11, ADR-0017 §3, §6, §7) -

func pode_chamar(player_id: int) -> bool:
	var pacto := _pacto_de(player_id)
	return pacto != null and pacto.campo != null \
		and pacto.campo.em_campo() \
		and pacto.campo.vida > 0 \
		and pacto.campo.estado != MaldicaoRef.Estado.SALTANDO


func pedir_chamado(player_id: int, ponto_mirado: Vector2, dano_golpe: float, m_chamado: float) -> void:
	if not pode_chamar(player_id):
		return
	var pacto := _garantir_pacto(player_id)
	pacto.chamado_pendente = true
	pacto.chamado_ponto = ponto_mirado
	pacto.chamado_dano = dano_golpe
	pacto.chamado_m = m_chamado


## Marca o inimigo atingido pelo Virote do dono (R4.1, R20, AC-ML-05, AC-ML-29).
func registrar_acerto_virote(player_id: int, inimigo_id: int) -> void:
	var pacto := _garantir_pacto(player_id)
	if pacto.marca_virote != inimigo_id:
		pacto.marca_virote = inimigo_id
		if _eventos != null:
			_eventos.emitir(EventosMaldicoes.EvMarcaViroteMudou.new(player_id, inimigo_id))


## R8 / R21 / F7: Recebe golpe inimigo travado na Maldição (`ferir_maldicao`), sem invulnerabilidade e sem hitstop.
func ferir_maldicao(maldicao_id: int, dano_base: float, m_atacante: float = 1.0) -> int:
	if not maldicao_atingivel(maldicao_id):
		return 0
	var m := _por_id[maldicao_id]
	var teto_red := _mod_tuning.teto_reducao_dano if _mod_tuning != null else 0.60
	var dano_int := FormulasDeModificadores.dano_recebido(dano_base * m_atacante, m.reducao_dano(), teto_red, 1.0)
	var vida_rest := descontar_vida(maldicao_id, dano_int)
	if _eventos != null:
		_eventos.emitir(EventosMaldicoes.EvMaldicaoFerida.new(maldicao_id, dano_int, vida_rest))
	if vida_rest <= 0:
		if _eventos != null:
			_eventos.emitir(EventosMaldicoes.EvMaldicaoExausta.new(maldicao_id))
		exaurir(maldicao_id)
	return dano_int


func descontar_vida(maldicao_id: int, dano: int) -> int:
	var m: MaldicaoRef = _por_id.get(maldicao_id, null)
	if m == null:
		return 0
	m.vida = maxi(0, m.vida - maxi(0, dano))
	return m.vida


## R9 / R21 / ADR-0017 §3: Exaustão síncrona nos itens 7/8!
## Zera Vida, fixa `total_exausta = restante_exausta`, avisa `maldicao_saiu_de_campo` à IA no mesmo passo
## e executa a troca automática para a reserva Pronta (sem técnica e sem gastar recarga).
func exaurir(maldicao_id: int) -> void:
	var m: MaldicaoRef = _por_id.get(maldicao_id, null)
	if m == null:
		return
	var pacto: EstadoDoPacto = _garantir_pacto(m.player_id)
	m.vida = 0
	m.estado = MaldicaoRef.Estado.EXAUSTA
	m.alvo_id = -1
	m.estourou_fio = false
	IADeAliado.limpar_passivas_condicionais(m)

	# Passiva 2 Vínculo Inquebrável (Soberano): reduz tempo de Exausta em 20% (600 -> 480; nível >= 3: 540 / 432)
	var red_esp: float = REDUCAO_EXAUSTA_VINCULO_INQUEBRAVEL if (m.def != null and m.def.passivas.has(&"vinculo_inquebravel")) else 0.0
	var s_efetivo: float = _tuning.recuperacao_exausta_s * m.mult_recuperacao_vinculo * (1.0 - red_esp)
	var passos_ex: int = Unidades.duracao_para_passos(s_efetivo)
	m.total_exausta = passos_ex
	m.restante_exausta = passos_ex
	pacto.seq_exaustao += 1
	m.ordem_exaustao = pacto.seq_exaustao

	# Avisa a IA de forma síncrona no mesmo passo (AC-ML-11, AC-ML-30)
	if _ia != null:
		_ia.maldicao_saiu_de_campo(pacto.player_id)
	if _eventos != null:
		for id_atr: int in pacto.ids_atraidos:
			_eventos.emitir(EventosMaldicoes.EvAtracaoFim.new(id_atr))
	pacto.ids_atraidos.clear()

	if pacto.campo == m:
		if pacto.reserva != null and pacto.reserva.estado == MaldicaoRef.Estado.PRONTA:
			var entra: MaldicaoRef = pacto.reserva
			pacto.campo = entra
			pacto.reserva = m
			var pos_jog: Vector2 = _pos_jogadores.get(pacto.player_id, Vector2(960.0, 930.0))
			entra.pos = _ia.conter(pos_jog, entra.raio_px()) if _ia != null else pos_jog
			entra.estado = MaldicaoRef.Estado.SEGUINDO
			entra.alvo_id = -1
			entra.estourou_fio = false
			if _eventos != null:
				_eventos.emitir(EventosMaldicoes.EvMaldicaoTrocada.new(
					pacto.player_id, &"automatica", m.id, entra.id))
		else:
			pacto.campo = null
			if pacto.reserva == null:
				pacto.reserva = m


# --- Implementação de ConsultaDaMaldicao (para a IA) --------------------------

func maldicao_em_campo(player_id: int) -> int:
	var pacto: EstadoDoPacto = _pacto_de(player_id)
	if pacto == null or pacto.campo == null or not pacto.campo.em_campo():
		return -1
	return pacto.campo.id


func maldicao_atingivel(maldicao_id: int) -> bool:
	var m: MaldicaoRef = _por_id.get(maldicao_id, null)
	if m == null:
		return false
	var pacto: EstadoDoPacto = _pacto_de(m.player_id)
	if pacto == null or pacto.campo != m:
		return false
	return m.em_campo() and m.vida > 0 and m.estado != MaldicaoRef.Estado.SALTANDO


func posicao_e_raio(maldicao_id: int) -> Vector3:
	var m: MaldicaoRef = _por_id.get(maldicao_id, null)
	if m == null:
		return Vector3.ZERO
	return Vector3(m.pos.x, m.pos.y, m.raio_px())


func portador_de(maldicao_id: int) -> ConsultaDeAtributos:
	var m: MaldicaoRef = _por_id.get(maldicao_id, null)
	return m.portador if m != null else null


func ref_de(maldicao_id: int) -> MaldicaoRef:
	return _por_id.get(maldicao_id, null)


## R21 / Catálogo Soberano: `fator_andar_atraido` = 0,80 se a espécie em campo tem `presenca_do_limiar`, senão 1,0.
func fator_andar_atraido(player_id: int) -> float:
	var pacto := _pacto_de(player_id)
	if pacto == null or pacto.campo == null or pacto.campo.def == null:
		return 1.0
	if pacto.campo.def.passivas.has(&"presenca_do_limiar"):
		return FATOR_ANDAR_PRESENCA_DO_LIMIAR
	return 1.0


# --- Câmaras, leitura do HUD e apresentação (R14, R19, R20; AC-ML-19, AC-ML-28, AC-ML-35) -

## Ponto canônico da troca de câmara: `(960 ; min(930 + distancia_seguir_px, 1080 - raio_px))` (R14 emenda, AC-ML-35).
static func calcular_ponto_reposicionamento_camara(raio_maldicao_px: float,
		distancia_seguir_px: float = 105.0, entrada_jogador: Vector2 = Vector2(960.0, 930.0),
		altura_camara_px: float = 1080.0) -> Vector2:
	return Vector2(entrada_jogador.x, minf(entrada_jogador.y + distancia_seguir_px, altura_camara_px - raio_maldicao_px))


func reposicionar_maldicao(player_id: int, pos: Vector2) -> void:
	var pacto := _pacto_de(player_id)
	if pacto == null:
		return
	if pacto.campo != null:
		var m := pacto.campo
		IADeAliado.limpar_passivas_condicionais(m)
		m.pos = pos
		m.estado = MaldicaoRef.Estado.SEGUINDO
		m.estourou_fio = false
		m.alvo_id = -1
		m.timer_fase = 0
		m.salto_restante = 0
	pacto.chamado_pendente = false
	if pacto.marca_virote != -1:
		pacto.marca_virote = -1
		if _eventos != null:
			_eventos.emitir(EventosMaldicoes.EvMarcaViroteMudou.new(player_id, -1))
	else:
		if _eventos != null:
			_eventos.emitir(EventosMaldicoes.EvMarcaViroteMudou.new(player_id, -1))
	if _ia != null:
		_ia.maldicao_saiu_de_campo(player_id)
	if _eventos != null:
		for id_atr: int in pacto.ids_atraidos:
			_eventos.emitir(EventosMaldicoes.EvAtracaoFim.new(id_atr))
		for id_imob: int in pacto.ids_imobilizados:
			_eventos.emitir(EventosMaldicoes.EvImobilizacaoFim.new(id_imob))
	pacto.ids_atraidos.clear()
	pacto.ids_imobilizados.clear()
	pacto.ids_marcados_saida.clear()


## R19 / AC-ML-28: Leitura imutável sem efeito colateral para o HUD (idêntica em Jogo e na Pausa).
func estado_pacto(player_id: int = 0) -> EstadoPactoLeitura:
	var out := EstadoPactoLeitura.new()
	var pacto := _pacto_de(player_id)
	if pacto == null:
		return out
	out.recarga_troca_passos = pacto.recarga_troca
	out.recarga_troca_total = pacto.recarga_troca_total
	out.troca_disponivel = TrocaDeMaldicao.troca_disponivel(pacto)
	if pacto.campo != null:
		out.campo = _montar_slot_leitura(pacto.campo)
	if pacto.reserva != null:
		out.reserva = _montar_slot_leitura(pacto.reserva)
	return out


func publicar_vista_apresentacao(player_id: int, saida: VistaDeMaldicao) -> void:
	if saida == null:
		return
	var pacto: EstadoDoPacto = _pacto_de(player_id)
	var pos_jog: Vector2 = _pos_jogadores.get(player_id, Vector2.ZERO)
	saida.pos_jogador = pos_jog
	saida.usa_telegrafo_de_chao = false
	if pacto == null or pacto.campo == null or not pacto.campo.em_campo():
		saida.em_campo = false
		saida.estado_fio = VistaDeMaldicao.EstadoFio.OCULTO
		saida.inimigo_marcado_virote_id = pacto.marca_virote if pacto != null else -1
		return
	var m := pacto.campo
	saida.em_campo = true
	saida.especie_id = m.especie_id
	saida.pos_maldicao = m.pos
	saida.distancia_fio_px = (m.pos - pos_jog).length()
	saida.estado_fio = VistaDeMaldicao.calcular_estado_fio(
		true, saida.distancia_fio_px, m.estourou_fio, _tuning.alcance_fio_px)
	saida.inimigo_marcado_virote_id = pacto.marca_virote


func _montar_slot_leitura(m: MaldicaoRef) -> EstadoPactoLeitura.SlotLeitura:
	var s := EstadoPactoLeitura.SlotLeitura.new()
	s.especie_id = m.especie_id
	s.vida = m.vida
	s.vida_max = m.vida_max()
	s.estado = m.estado_hud()
	s.restante_exausta = m.restante_exausta if m.estado == MaldicaoRef.Estado.EXAUSTA else 0
	s.total_exausta = m.total_exausta if m.estado == MaldicaoRef.Estado.EXAUSTA else 0
	return s


func _garantir_pacto(player_id: int) -> EstadoDoPacto:
	while _pactos.size() <= player_id:
		var novo := EstadoDoPacto.new()
		novo.player_id = _pactos.size()
		_pactos.append(novo)
	return _pactos[player_id]


func _pacto_de(player_id: int) -> EstadoDoPacto:
	if player_id < 0 or player_id >= _pactos.size():
		return null
	return _pactos[player_id]


func _montar_contexto(pacto: EstadoDoPacto) -> ContextoDaTecnica:
	var ctx := ContextoDaTecnica.new()
	ctx.pacto = pacto
	ctx.tuning = _tuning
	ctx.ia = _ia
	ctx.combate = _combate_aliado
	ctx.status = _status_aliado
	ctx.eventos = _eventos
	ctx.pos_jogador = _pos_jogadores.get(pacto.player_id, Vector2.ZERO)
	ctx.mira_jogador = _mira_jogadores.get(pacto.player_id, Vector2.RIGHT)
	ctx.respiro_atracao_passos = _respiro_atracao_passos
	return ctx


static func _normalizar_mod_tuning(p_mod: ModifiersTuning) -> ModifiersTuning:
	var t := p_mod if p_mod != null else ModifiersTuning.new()
	if t.piso_vida_jogador <= 0.0:
		t.piso_vida_jogador = 20.0
	if t.piso_vida_inimigo <= 0.0:
		t.piso_vida_inimigo = 1.0
	if t.piso_vida_maldicao <= 0.0:
		t.piso_vida_maldicao = 20.0
	if t.teto_reducao_dano <= 0.0:
		t.teto_reducao_dano = 0.60
	if t.teto_multiplicador_dano <= 0.0:
		t.teto_multiplicador_dano = 4.0
	if t.fator_empurrao_chefe <= 0.0:
		t.fator_empurrao_chefe = 0.12
	if t.tipos_propagados_maldicao.is_empty():
		t.tipos_propagados_maldicao = [&"dano_todo_pct", &"velocidade_pct"]
	if t.fator_propagacao_maldicao <= 0.0:
		t.fator_propagacao_maldicao = 1.0
	return t
