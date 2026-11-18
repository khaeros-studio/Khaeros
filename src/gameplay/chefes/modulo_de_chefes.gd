class_name ModuloDeChefes
extends RefCounted

const HITSTOP_QUEDA_PASSOS: int = 36
const QUANTIDADE_VINCULO_CHEFE: int = 6

var _tuning: ChefesTuning
var _def_chefe: EnemyDef
var _def_lacaio: EnemyDef
var _ia: ModuloDeIA
var _telegrafos: Telegrafos
var _combate: ContratosDeChefes.CombateParaChefes
var _camaras: ContratosDeChefes.CamarasParaChefes
var _vinculo: ContratosDeChefes.VinculoParaChefes

var _id_chefe_ativo: int = -1
var _doutrina_atual: StringName = &""
var _queda_registrada: bool = false
var _subjugado_na_queda: bool = false
var _passos_ate_pos_hitstop: int = -1
var _pos_hitstop_concluido: bool = false
var _escolha_processada: bool = false
var _passos_desde_queda: int = 0

var _eventos_vencido: Array[EventosDeChefes.EvChefeVencido] = []
var _eventos_subjugado: Array[EventosDeChefes.EvChefeSubjugado] = []
var _eventos_exorcizado: Array[EventosDeChefes.EvChefeExorcizado] = []
var _eventos_sonoros: Array[StringName] = []


func _init(
	tuning: ChefesTuning = null,
	ia: ModuloDeIA = null,
	telegrafos: Telegrafos = null,
	combate: ContratosDeChefes.CombateParaChefes = null,
	camaras: ContratosDeChefes.CamarasParaChefes = null,
	vinculo: ContratosDeChefes.VinculoParaChefes = null,
	def_chefe: EnemyDef = null,
	def_lacaio: EnemyDef = null
) -> void:
	_tuning = tuning if tuning != null else CatalogoChefes.criar_chefes_tuning_padrao()
	_ia = ia
	_telegrafos = telegrafos
	_combate = combate if combate != null else ContratosDeChefes.CombateParaChefesNulo.new()
	_camaras = camaras if camaras != null else ContratosDeChefes.CamarasParaChefesNula.new()
	_vinculo = vinculo if vinculo != null else ContratosDeChefes.VinculoParaChefesNulo.new()
	_def_chefe = def_chefe if def_chefe != null else CatalogoChefes.criar_soberano_do_limiar()
	_def_lacaio = def_lacaio if def_lacaio != null else CatalogoChefes.criar_eco_perdido_padrao()

	if _ia != null:
		_ia.definir_def_lacaio(_def_lacaio)


func iniciar_confronto(
	doutrina: StringName,
	pos_surgimento: Vector2 = CatalogoChefes.POS_SURGIMENTO_SOBERANO
) -> int:
	_doutrina_atual = doutrina
	_queda_registrada = false
	_subjugado_na_queda = false
	_passos_ate_pos_hitstop = -1
	_pos_hitstop_concluido = false
	_escolha_processada = false
	_passos_desde_queda = 0

	_camaras.configurar_pilares_arena(CatalogoChefes.PILARES_SOBERANO, CatalogoChefes.RAIO_PILAR_PX)

	if _ia == null:
		return -1
	var eh_pactos := (doutrina == &"pactos")
	var op := OpcoesDeNascimento.de_chefe(eh_pactos)
	_id_chefe_ativo = _ia.criar_inimigo(_def_chefe, pos_surgimento, op)
	_eventos_sonoros.append(&"chefe_surgimento")
	return _id_chefe_ativo


func chefe_vencido(id: int, subjugado: bool) -> void:
	if _queda_registrada:
		return
	# AC-CH-19: se o jogador morreu no mesmo passo, a morte do jogador prevalece
	if _combate.jogador_morreu_neste_passo():
		return

	_queda_registrada = true
	_id_chefe_ativo = id
	_subjugado_na_queda = subjugado
	_passos_desde_queda = 0
	# Em s + 37 (após 36 passos de hitstop), dispara a transição pós-hitstop
	_passos_ate_pos_hitstop = HITSTOP_QUEDA_PASSOS

	_combate.pausar_combate(HITSTOP_QUEDA_PASSOS)
	_combate.descartar_projeteis_inimigos()
	if _ia != null:
		if subjugado:
			_ia.subjugar(id)
		else:
			_ia.limpar_lacaios_invocados()
			_ia.remover_morto(id)
	if _telegrafos != null:
		_telegrafos.cancelar(id, TelegrafoTipos.CausaCancelamento.QUEDA_CHEFE)

	_eventos_vencido.append(EventosDeChefes.EvChefeVencido.new(id, subjugado))
	_eventos_sonoros.append(&"chefe_subjugado" if subjugado else &"chefe_derrotado")


func passo_vivo() -> void:
	atualizar_passo(0)


func atualizar_passo(_passo_atual: int = 0) -> void:
	if not _queda_registrada and _ia != null and _id_chefe_ativo >= 0:
		var est: EstadoDeInimigoIA = _ia.estado_de(_id_chefe_ativo)
		if est != null and (est.fase == EstadoDeInimigoIA.Fase.SUBJUGADO or est.fase == EstadoDeInimigoIA.Fase.MORTO):
			var foi_subjugado := (est.fase == EstadoDeInimigoIA.Fase.SUBJUGADO)
			chefe_vencido(_id_chefe_ativo, foi_subjugado)
			return

	if not _queda_registrada:
		return

	_passos_desde_queda += 1
	if _pos_hitstop_concluido or _passos_ate_pos_hitstop < 0:
		return

	if _combate.jogador_morreu_neste_passo():
		_passos_ate_pos_hitstop = -1
		return

	_passos_ate_pos_hitstop -= 1
	if _passos_ate_pos_hitstop < 0:
		_executar_pos_hitstop()


func _executar_pos_hitstop() -> void:
	_pos_hitstop_concluido = true
	if _subjugado_na_queda:
		# Caminho 1 (Pactos, subjugado = true): emite EvChefeSubjugado sem chamar limpar_camara_chefe()
		var especie_id: StringName = _def_chefe.id if _def_chefe != null else CatalogoChefes.ID_SOBERANO
		_eventos_subjugado.append(EventosDeChefes.EvChefeSubjugado.new(_id_chefe_ativo, especie_id))
	else:
		# Caminho 2 (fora de Pactos, subjugado = false): credita +6 Fragmentos e libera a câmara
		_vinculo.creditar(&"chefe", QUANTIDADE_VINCULO_CHEFE)
		_camaras.limpar_camara_chefe()


func escolha(id: int, p_escolha: StringName) -> void:
	# Ignora escolha se não estiver subjugado, se o id não bater ou se já foi processada (AC-CH-18)
	if not _queda_registrada or not _subjugado_na_queda or _escolha_processada:
		return
	if id != _id_chefe_ativo:
		return
	if p_escolha != &"pactuar" and p_escolha != &"exorcizar":
		return

	_escolha_processada = true
	# Ordem estrita da R9b (ADR-0018 §7):
	# 1. Combate.resolver_subjugado(id, escolha)
	_combate.resolver_subjugado(id, p_escolha)

	# 2. Se exorcizar, remove o chefe, emite EvChefeExorcizado e credita +6 Fragmentos
	if p_escolha == &"exorcizar":
		if _ia != null:
			_ia.remover_morto(id)
		_eventos_exorcizado.append(EventosDeChefes.EvChefeExorcizado.new(id))
		_vinculo.creditar(&"chefe", QUANTIDADE_VINCULO_CHEFE)

	# 3. Camaras.limpar_camara_chefe() por último
	_camaras.limpar_camara_chefe()


func obter_vista_barra() -> VistaBarraDeChefe:
	if _ia == null or _id_chefe_ativo < 0:
		return VistaBarraDeChefe.new()
	var est: EstadoDeInimigoIA = _ia.estado_de(_id_chefe_ativo)
	return VistaBarraDeChefe.construir_de_estado(est, _tuning, _passos_desde_queda)


func id_chefe_ativo() -> int:
	return _id_chefe_ativo


func drenar_eventos_vencido() -> Array[EventosDeChefes.EvChefeVencido]:
	var copia: Array[EventosDeChefes.EvChefeVencido] = _eventos_vencido.duplicate()
	_eventos_vencido.clear()
	return copia


func drenar_eventos_subjugado() -> Array[EventosDeChefes.EvChefeSubjugado]:
	var copia: Array[EventosDeChefes.EvChefeSubjugado] = _eventos_subjugado.duplicate()
	_eventos_subjugado.clear()
	return copia


func drenar_eventos_exorcizado() -> Array[EventosDeChefes.EvChefeExorcizado]:
	var copia: Array[EventosDeChefes.EvChefeExorcizado] = _eventos_exorcizado.duplicate()
	_eventos_exorcizado.clear()
	return copia


func drenar_eventos_sonoros() -> Array[StringName]:
	var copia: Array[StringName] = _eventos_sonoros.duplicate()
	_eventos_sonoros.clear()
	return copia
