class_name Vinculo
extends PortaDoVinculoNaRun
## Módulo principal de Vínculo e pactos: coordena o [PerfilVinculo], o 1º pacto (V3),
## a escolha da dupla (V16/V16b), o sorteio do encontro no fluxo [code]pactos[/code] (F1),
## a entidade [MaldicaoAcuada] (V7, V8, V12), a tela de consentimento no estado [code]BENCAO[/code]
## (V9–V15), os pontos e níveis da run (V17, V19, F3, F4), a consolidação de fim de run ou saída
## (V20, V20b), a decisão Pactuar/Exorcizar no chefe Subjugado (V18) e os eventos para Telemetria (V45).
##
## Governado por ADR-0001, ADR-0002, ADR-0005, ADR-0009, ADR-0010, ADR-0013, ADR-0015 e ADR-0017.
## Sem SceneTree, sem Autoload.

const DOUTRINA_PACTOS: StringName = &"pactos"

var _perfil: PerfilVinculo
var _tuning: VinculoTuning
var _eventos: EventosDoPasso

# Colaboradores opcionais
var _orquestrador: Object = null
var _portas: Object = null
var _maldicoes: Object = null
var _chefes: Object = null
var _save: Object = null
var _acrescentar_a_dupla_cb: Callable = Callable()

# Estado de escopo de run
var _doutrina_run: StringName = &""
var _dupla_run: Array[StringName] = []
var _tela_dupla_aberta: bool = false
var _tela_consentimento_aberta: bool = false
var _tela_chefe_aberta: bool = false
var _chefe_subjugado_id: StringName = &""
var _encontro: EncontroDePacto = null
var _acumuladores: Dictionary[StringName, PontosDeVinculo.AcumuladorDaRun] = {}
var _consolidado_nesta_run: bool = false


func _init(perfil: PerfilVinculo = null, tuning: VinculoTuning = null,
		eventos: EventosDoPasso = null) -> void:
	_tuning = tuning if tuning != null else VinculoTuning.new()
	if _tuning.especie_primeiro_pacto == &"":
		_tuning.especie_primeiro_pacto = &"vulto_mudo"
	if _tuning.chance_encontro <= 0.0:
		_tuning.chance_encontro = 0.6
	if _tuning.pity_runs <= 0:
		_tuning.pity_runs = 2
	if _tuning.indices_encontro.is_empty():
		_tuning.indices_encontro = PackedInt64Array([1, 2])
	if _tuning.chance_nao_pactuada <= 0.0:
		_tuning.chance_nao_pactuada = 0.75
	if _tuning.peso_raridade.is_empty():
		_tuning.peso_raridade = PackedFloat64Array([3.0, 2.0, 1.0, 1.0])
	if _tuning.frac_vida_acuada <= 0.0:
		_tuning.frac_vida_acuada = 1.2
	if _tuning.encontros_para_consentir.is_empty():
		_tuning.encontros_para_consentir = PackedInt64Array([1, 1, 2, 2, 1])
	if _tuning.pts_camara <= 0:
		_tuning.pts_camara = 2
	if _tuning.pts_abate <= 0:
		_tuning.pts_abate = 1
	if _tuning.pts_tecnica <= 0:
		_tuning.pts_tecnica = 1
	if _tuning.pts_vitoria <= 0:
		_tuning.pts_vitoria = 8
	if _tuning.teto_abates_run <= 0:
		_tuning.teto_abates_run = 12
	if _tuning.teto_tecnicas_run <= 0:
		_tuning.teto_tecnicas_run = 6
	if _tuning.pts_reafirmar <= 0:
		_tuning.pts_reafirmar = 6
	if _tuning.pts_reafirmar_chefe <= 0:
		_tuning.pts_reafirmar_chefe = 10
	if _tuning.limiares_nivel.is_empty():
		_tuning.limiares_nivel = PackedInt64Array([20, 50, 90, 140])
	if _tuning.nivel_max <= 0:
		_tuning.nivel_max = 5
	if _tuning.pontos_teto <= 0:
		_tuning.pontos_teto = 9999
	if _tuning.bonus_vida <= 0.0:
		_tuning.bonus_vida = 0.05
	if _tuning.mult_recuperacao <= 0.0:
		_tuning.mult_recuperacao = 0.90
	if _tuning.bonus_dano_basico <= 0.0:
		_tuning.bonus_dano_basico = 0.05
	_perfil = perfil if perfil != null else PerfilVinculo.new([], _tuning)
	_eventos = eventos if eventos != null else EventosDoPasso.new()
	_encontro = EncontroDePacto.new()


# --- Injeção de colaboradores ------------------------------------------------

func configurar_orquestrador(orq: Object) -> void:
	_orquestrador = orq


func configurar_portas(portas_ref: Object) -> void:
	_portas = portas_ref


func configurar_maldicoes(maldicoes_ref: Object, acrescentar_cb: Callable = Callable()) -> void:
	_maldicoes = maldicoes_ref
	_acrescentar_a_dupla_cb = acrescentar_cb


func configurar_chefes(chefes_ref: Object) -> void:
	_chefes = chefes_ref


func configurar_save(save_ref: Object) -> void:
	_save = save_ref


# --- Consultas ---------------------------------------------------------------

func perfil() -> PerfilVinculo:
	return _perfil


func tuning() -> VinculoTuning:
	return _tuning


func encontro() -> EncontroDePacto:
	return _encontro


func acuada() -> MaldicaoAcuada:
	return _encontro.acuada


func dupla_da_run() -> Array[StringName]:
	return _dupla_run.duplicate()


func tela_dupla_aberta() -> bool:
	return _tela_dupla_aberta


func tela_consentimento_aberta() -> bool:
	return _tela_consentimento_aberta


func tela_chefe_aberta() -> bool:
	return _tela_chefe_aberta


# --- B & E. Primeiro pacto (V3) e Escolha da dupla (V16, V16b) ----------------

## Pede a dupla para a Doutrina [param doutrina] (V3, V16, V16b, AC-VP-01).
## Devolve [code]true[/code] se abriu a tela de Escolha do Pacto (≥ 2 espécies pactuadas),
## ou [code]false[/code] se respondeu [code]dupla_confirmada[/code] imediatamente (0 ou 1 espécie pactuada).
func pedir_dupla(doutrina: StringName = DOUTRINA_PACTOS) -> bool:
	_doutrina_run = doutrina
	_tela_dupla_aberta = false
	if doutrina != DOUTRINA_PACTOS:
		_dupla_run.clear()
		return false

	# V3: se primeiro_pacto_concedido é falso (ou perfil veio sem nenhuma pactuada), concede o Vulto Mudo
	var pactuadas: Array[StringName] = _perfil.especies_pactuadas_ativas()
	if not _perfil.primeiro_pacto_concedido or pactuadas.is_empty():
		var esp_inicial: StringName = _tuning.especie_primeiro_pacto if _tuning.especie_primeiro_pacto != &"" else &"vulto_mudo"
		_perfil.registrar_pacto_novo(esp_inicial)
		_perfil.primeiro_pacto_concedido = true
		_emitir_pacto(esp_inicial, &"primeiro")
		pactuadas = _perfil.especies_pactuadas_ativas()

	# V16b: com 1 espécie pactuada, a tela é pulada e responde na hora
	if pactuadas.size() <= 1:
		var unica: StringName = pactuadas[0] if not pactuadas.is_empty() else &"vulto_mudo"
		_fixar_dupla_da_run(unica, &"", false)
		return false

	# Com 2 ou mais espécies pactuadas, abre a tela de Escolha do Pacto (V16)
	_tela_dupla_aberta = true
	return true


## Confirma a dupla escolhida na tela de Escolha do Pacto (V16).
## Recusa se [param campo] não estiver pactuado ou se [param campo] == [param reserva].
func confirmar_dupla(campo: StringName, reserva: StringName = &"") -> bool:
	var pactuadas: Array[StringName] = _perfil.especies_pactuadas_ativas()
	if campo == &"" or not pactuadas.has(campo):
		return false
	if reserva != &"" and (reserva == campo or not pactuadas.has(reserva)):
		return false
	_tela_dupla_aberta = false
	_perfil.ultima_dupla = [String(campo), String(reserva)]
	_fixar_dupla_da_run(campo, reserva, true)
	return true


## Cancela a tela de Escolha do Pacto (Esc): volta à Escolha de arma sem criar seed (V16, R2-P 1b).
func cancelar_escolha_dupla() -> void:
	_tela_dupla_aberta = false


func _fixar_dupla_da_run(campo: StringName, reserva: StringName, abriu_tela: bool) -> void:
	_dupla_run = [campo, reserva]
	_iniciar_acumuladores_run()
	_eventos.emitir(EventosVinculo.EvDuplaConfirmada.new(campo, reserva, abriu_tela))
	if abriu_tela:
		_notificar_save_pendente()


# --- C. Sorteio e montagem do encontro de pacto (V4–V8, V12, F1, F2) ---------

## Planeja o encontro da run no fluxo [param fluxo_pactos] (V5, V6, F1, AC-VP-02..06).
## Só consome os 4 reais se [param doutrina] == [code]pactos[/code].
func planejar_encontro(doutrina: StringName, fluxo_pactos: FluxoRng) -> void:
	if _consolidado_nesta_run:
		_acumuladores.clear()
	_doutrina_run = doutrina
	_consolidado_nesta_run = false
	_encontro = EncontroDePacto.new()
	if _acumuladores.is_empty() and doutrina == DOUTRINA_PACTOS:
		_iniciar_acumuladores_run()
	if doutrina != DOUTRINA_PACTOS or fluxo_pactos == null:
		return
	var res: SorteioDoEncontro.ResultadoDoSorteio = SorteioDoEncontro.sortear(_perfil, _tuning, fluxo_pactos)
	_encontro.planejar(res.ocorre, res.indice_camara, res.especie_id)


## Consulta das Câmaras: devolve a espécie planejada para a câmara [param indice], ou [code]&""[/code] (V41, AC-CO-36).
func encontro_na_camara(indice: int) -> StringName:
	if _doutrina_run != DOUTRINA_PACTOS:
		return &""
	if _encontro.estado == EncontroDePacto.Estado.PLANEJADO and _encontro.indice_camara == indice:
		return _encontro.especie_id
	return &""


## Chamado pelas Câmaras na montagem da câmara [param indice] (V7, V14, AC-VP-07).
## Nasce a acuada no 1º ponto livre de [param pedras], incrementa [code]encontros_vistos[/code]
## e marca [code]primeiro_encontro_visto = true[/code]. Não consome RNG.
func ao_montar_camara(indice: int, pedras: Array[ObstaculoCircular] = []) -> Vector2:
	for acum: PontosDeVinculo.AcumuladorDaRun in _acumuladores.values():
		acum.iniciar_nova_camara()
	if _doutrina_run != DOUTRINA_PACTOS:
		return Vector2.ZERO
	if _encontro.estado != EncontroDePacto.Estado.PLANEJADO or _encontro.indice_camara != indice:
		return Vector2.ZERO
	var def: CurseDef = _perfil.definicao_de(_encontro.especie_id)
	var pos: Vector2 = _encontro.acuada.nascer(def, pedras, _tuning.frac_vida_acuada)
	_encontro.estado = EncontroDePacto.Estado.ACUADA
	var est: PerfilVinculo.EstadoEspecie = _perfil.estado_de(_encontro.especie_id)
	if est != null:
		est.encontros_vistos = mini(PerfilVinculo.MAX_ENCONTROS_VISTOS, est.encontros_vistos + 1)
	_perfil.primeiro_encontro_visto = true
	return pos


## Verdadeiro enquanto a acuada está viva no estado [code]ACUADA[/code] (V8, V44).
func acuada_atingivel() -> bool:
	return _encontro.estado == EncontroDePacto.Estado.ACUADA and _encontro.acuada.acuada_atingivel()


## Dano de inimigo na acuada (V7, V12, V44, AC-VP-08, AC-VP-11).
## Se a Vida chegar a 0, chama [method falhar_encontro] de forma síncrona.
func ferir_acuada(dano_base: float, m_atacante: float = 1.0,
		faccao_atacante: StringName = &"inimigo") -> bool:
	if _encontro.estado != EncontroDePacto.Estado.ACUADA:
		return false
	var fugiu: bool = _encontro.acuada.ferir_acuada(dano_base, m_atacante, faccao_atacante)
	if fugiu:
		falhar_encontro()
	return fugiu


## Falha síncrona do encontro quando a Vida da acuada zera (V12, AC-VP-11):
## - Estado vai a [code]FUGIU[/code];
## - [code]encontro_pendente = [especie][/code];
## - Emite [EvEncontroFalhou] e [EvEncontroPacto] com [code]resultado = &"fugiu"[/code].
func falhar_encontro() -> void:
	if _encontro.estado != EncontroDePacto.Estado.ACUADA:
		return
	_encontro.estado = EncontroDePacto.Estado.FUGIU
	_encontro.acuada.estado = MaldicaoAcuada.Estado.FUGIU
	_encontro.acuada.vida = 0
	_encontro.acuada.passos_fuga_restantes = MaldicaoAcuada.PASSOS_FUGA
	_encontro.resultado_final = &"fugiu"
	_perfil.encontro_pendente = [String(_encontro.especie_id)]
	_eventos.emitir(EventosVinculo.EvEncontroFalhou.new(_encontro.indice_camara, _encontro.especie_id))
	_eventos.emitir(EventosVinculo.EvEncontroPacto.new(_encontro.indice_camara, _encontro.especie_id, &"fugiu", 0))


## Notificação de que uma câmara foi limpa (V9, V17):
## - Contabiliza [code]pts_camara[/code] para as espécies que acertaram golpe na câmara;
## - Se era a câmara do encontro e a acuada sobreviveu ([code]vida > 0[/code]), passa a [code]AGUARDANDO[/code].
func ao_camara_limpa(indice_camara: int, tipo_camara: StringName = &"combate") -> void:
	if _doutrina_run != DOUTRINA_PACTOS:
		return
	if tipo_camara == &"combate" or tipo_camara == &"chefe":
		for acum: PontosDeVinculo.AcumuladorDaRun in _acumuladores.values():
			acum.ao_limpar_camara_combate_ou_chefe()
	if _encontro.estado == EncontroDePacto.Estado.ACUADA and _encontro.indice_camara == indice_camara:
		if _encontro.acuada.ao_limpar_camara():
			_encontro.estado = EncontroDePacto.Estado.AGUARDANDO


## Consulta das Portas no passo 2b (V9, V41, AC-PR-26..28, AC-VP-12).
func encontro_aguardando() -> bool:
	return _encontro.estado == EncontroDePacto.Estado.AGUARDANDO


# --- Consentimento no estado Bênção e crescimento da dupla (V9–V15) -----------

## Abre a tela de consentimento ao Interagir com a acuada em [code]AGUARDANDO[/code] (V9).
## Pede o estado [code]BENCAO[/code] ao orquestrador (decisão 19, ADR-0015 §3).
func interagir_com_acuada() -> Array[StringName]:
	if _encontro.estado != EncontroDePacto.Estado.AGUARDANDO:
		return []
	_tela_consentimento_aberta = true
	if _orquestrador != null and _orquestrador.has_method("pedir_estado"):
		_orquestrador.call("pedir_estado", EstadoDeJogo.Valor.BENCAO)
	return ConsentimentoPacto.opcoes_da_tela(_encontro.especie_id, _perfil, _tuning)


## Resolve a escolha feita na tela de consentimento (V10, V11, V13, V15, AC-VP-13..15):
## [param opcao] ∈ {[code]&"oferecer"[/code], [code]&"reafirmar"[/code], [code]&"deixar_ir"[/code], [code]&"ela_voltara"[/code]}.
func resolver_consentimento(opcao: StringName, substituir_slot_dupla: int = -1) -> bool:
	if _encontro.estado != EncontroDePacto.Estado.AGUARDANDO:
		return false
	var opcoes_validas: Array[StringName] = ConsentimentoPacto.opcoes_da_tela(_encontro.especie_id, _perfil, _tuning)
	if not opcoes_validas.has(opcao):
		return false

	var esp: StringName = _encontro.especie_id
	var est: PerfilVinculo.EstadoEspecie = _perfil.estado_de(esp)
	var vida_rest: int = _encontro.acuada.vida
	var resultado_ev: StringName = ConsentimentoPacto.RESULTADO_DEIXADA

	match opcao:
		ConsentimentoPacto.OPCAO_OFERECER:
			if est != null:
				est.encontros_bem_sucedidos = mini(est.encontros_vistos, est.encontros_bem_sucedidos + 1)
			_perfil.registrar_pacto_novo(esp)
			resultado_ev = ConsentimentoPacto.RESULTADO_PACTUADA
			_emitir_pacto(esp, &"encontro")
			_integrar_nova_especie_na_dupla_da_run(esp, vida_rest, substituir_slot_dupla)
		ConsentimentoPacto.OPCAO_REAFIRMAR:
			if est != null:
				est.encontros_bem_sucedidos = mini(est.encontros_vistos, est.encontros_bem_sucedidos + 1)
			_garantir_acumulador(esp).somar_extra(_tuning.pts_reafirmar)
			resultado_ev = ConsentimentoPacto.RESULTADO_REAFIRMADA
		ConsentimentoPacto.OPCAO_ELA_VOLTARA:
			if est != null:
				est.encontros_bem_sucedidos = mini(est.encontros_vistos, est.encontros_bem_sucedidos + 1)
			_perfil.encontro_pendente = [String(esp)]
			resultado_ev = ConsentimentoPacto.RESULTADO_VOLTARA
		ConsentimentoPacto.OPCAO_DEIXAR_IR:
			if est != null and not est.pactuada:
				est.encontros_bem_sucedidos = mini(est.encontros_vistos, est.encontros_bem_sucedidos + 1)
			if _perfil.encontro_pendente.has(String(esp)):
				_perfil.encontro_pendente.erase(String(esp))
			resultado_ev = ConsentimentoPacto.RESULTADO_DEIXADA

	_tela_consentimento_aberta = false
	_encontro.estado = EncontroDePacto.Estado.RESOLVIDO
	_encontro.acuada.estado = MaldicaoAcuada.Estado.RESOLVIDA
	_encontro.resultado_final = resultado_ev

	_eventos.emitir(EventosVinculo.EvEncontroPacto.new(_encontro.indice_camara, esp, resultado_ev, vida_rest))
	_eventos.emitir(EventosVinculo.EvPactoResolvido.new(esp, resultado_ev))

	if _portas != null and _portas.has_method("ao_pacto_resolvido"):
		_portas.call("ao_pacto_resolvido")
	if _orquestrador != null and _orquestrador.has_method("pedir_estado"):
		_orquestrador.call("pedir_estado", EstadoDeJogo.Valor.JOGO)
	return true


func _integrar_nova_especie_na_dupla_da_run(esp: StringName, vida_acuada: int, substituir_slot: int = -1) -> void:
	var def: CurseDef = _perfil.definicao_de(esp)
	var vida_max_base: int = int(def.vida_max) if def != null else 95
	var vida_inicial: int = mini(vida_acuada, vida_max_base)
	_garantir_acumulador(esp)

	# V15 (AC-VP-15): se a dupla tem só 1 Maldição (reserva vazia), entra na reserva agora como Pronta
	if _dupla_run.size() < 2:
		_dupla_run.append(esp)
	elif _dupla_run[1] == &"":
		_dupla_run[1] = esp
	elif substituir_slot == 0 or substituir_slot == 1:
		_dupla_run[substituir_slot] = esp
	else:
		# Dupla cheia e sem substituição pedida: vai apenas para o perfil (V15)
		return

	if _acrescentar_a_dupla_cb.is_valid():
		_acrescentar_a_dupla_cb.call(0, def, vida_inicial)
	elif _maldicoes != null and _maldicoes.has_method("acrescentar_a_dupla"):
		_maldicoes.call("acrescentar_a_dupla", 0, def, vida_inicial)


# --- F. Registro de golpes, abates, técnicas, chefe Subjugado e consolidação --

func registrar_acerto_maldicao(especie_id: StringName) -> void:
	if _doutrina_run != DOUTRINA_PACTOS or especie_id == &"":
		return
	_garantir_acumulador(especie_id).registrar_acerto_na_camara()


func registrar_abate_maldicao(especie_id: StringName) -> void:
	if _doutrina_run != DOUTRINA_PACTOS or especie_id == &"":
		return
	_garantir_acumulador(especie_id).registrar_abate()


func registrar_tecnica_combinada_com_acerto() -> void:
	if _doutrina_run != DOUTRINA_PACTOS:
		return
	for esp: StringName in _dupla_run:
		if esp != &"":
			_garantir_acumulador(esp).registrar_tecnica_com_acerto()


## Chamado quando o chefe entra em [code]Subjugado[/code] (V14, V18).
func ao_chefe_subjugado(chefe_id: StringName = &"soberano_do_limiar") -> void:
	if _doutrina_run != DOUTRINA_PACTOS:
		return
	_chefe_subjugado_id = chefe_id if chefe_id != &"" else &"soberano_do_limiar"
	var est: PerfilVinculo.EstadoEspecie = _perfil.estado_de(_chefe_subjugado_id)
	if est != null:
		est.encontros_vistos = mini(PerfilVinculo.MAX_ENCONTROS_VISTOS, est.encontros_vistos + 1)
	_perfil.primeiro_encontro_visto = true


## Abre a tela Pactuar / Exorcizar ao Interagir com o chefe ajoelhado (V18.2).
func interagir_com_chefe_subjugado() -> bool:
	if _chefe_subjugado_id == &"":
		return false
	_tela_chefe_aberta = true
	if _orquestrador != null and _orquestrador.has_method("pedir_estado"):
		_orquestrador.call("pedir_estado", EstadoDeJogo.Valor.BENCAO)
	return true


## Resolve a decisão Pactuar vs Exorcizar no chefe Subjugado (V18, V18.5, AC-VP-22, AC-VP-23).
func escolher_destino_chefe(escolha: StringName, chefe_id: StringName = &"") -> EscolhaDoChefe.ResultadoEscolhaChefe:
	var id_alvo: StringName = chefe_id if chefe_id != &"" else (_chefe_subjugado_id if _chefe_subjugado_id != &"" else &"soberano_do_limiar")
	var res: EscolhaDoChefe.ResultadoEscolhaChefe = EscolhaDoChefe.resolver(
		id_alvo, escolha, _perfil, _dupla_run, _tuning
	)
	_tela_chefe_aberta = false
	_chefe_subjugado_id = &""

	for esp_id: StringName in res.pontos_por_especie.keys():
		var pts: int = int(res.pontos_por_especie[esp_id])
		_garantir_acumulador(esp_id).somar_extra(pts)

	if res.emitiu_pacto_registrado:
		_emitir_pacto(id_alvo, &"chefe")

	_eventos.emitir(EventosVinculo.EvChefeEscolhido.new(id_alvo, escolha))
	if _chefes != null and _chefes.has_method("escolha"):
		_chefes.call("escolha", id_alvo, escolha)
	if _orquestrador != null and _orquestrador.has_method("pedir_estado"):
		_orquestrador.call("pedir_estado", EstadoDeJogo.Valor.JOGO)
	return res


## Consolida os pontos da run no perfil no fim da run ou ao sair do jogo (V20, V20b, AC-VP-16..19).
func consolidar_run(motivo: StringName, venceu: bool) -> void:
	if _doutrina_run != DOUTRINA_PACTOS or _consolidado_nesta_run:
		return
	_consolidado_nesta_run = true

	# Se havia encontro em Aguardando e a run terminou por morte ou abandono/saída (V20b, AC-VP-19):
	if _encontro.estado == EncontroDePacto.Estado.AGUARDANDO:
		_encontro.estado = EncontroDePacto.Estado.ABANDONADO
		_encontro.resultado_final = &"abandonado"
		_perfil.encontro_pendente = [String(_encontro.especie_id)]
		_eventos.emitir(EventosVinculo.EvEncontroPacto.new(
			_encontro.indice_camara, _encontro.especie_id, &"abandonado", _encontro.acuada.vida
		))
	elif _encontro.estado == EncontroDePacto.Estado.PLANEJADO:
		_encontro.estado = EncontroDePacto.Estado.NAO_ALCANCADO

	if venceu and motivo == &"vitoria":
		for esp: StringName in _dupla_run:
			if esp != &"":
				_garantir_acumulador(esp).registrar_vitoria()

	var eventos_ganho: Array[EventosVinculo.EvVinculoGanho] = []
	for sid: String in _perfil.ordem_manifesto():
		var esp_id := StringName(sid)
		if not _acumuladores.has(esp_id):
			continue
		var acum: PontosDeVinculo.AcumuladorDaRun = _acumuladores[esp_id]
		var pts_run: int = PontosDeVinculo.calcular_pontos_run(acum, _tuning)
		var subiu: bool = false
		if pts_run > 0:
			subiu = _perfil.somar_pontos_e_recalcular(esp_id, pts_run)
		var est: PerfilVinculo.EstadoEspecie = _perfil.estado_de(esp_id)
		if est != null and (_dupla_run.has(esp_id) or pts_run > 0):
			var ev := EventosVinculo.EvVinculoGanho.new(esp_id, pts_run, est.vinculo_pontos, est.nivel, subiu)
			eventos_ganho.append(ev)
			_eventos.emitir(ev)

	# V20.2: runs_pactos_sem_encontro
	if _encontro.nasceu_nesta_run():
		_perfil.runs_pactos_sem_encontro = 0
	else:
		_perfil.runs_pactos_sem_encontro = mini(PerfilVinculo.MAX_RUNS_SEM_ENCONTRO, _perfil.runs_pactos_sem_encontro + 1)

	# V20.3: runs_pactos_iniciadas += 1
	_perfil.runs_pactos_iniciadas = mini(PerfilVinculo.MAX_RUNS_INICIADAS, _perfil.runs_pactos_iniciadas + 1)

	# V20.4: emite vinculo_atualizado
	_eventos.emitir(EventosVinculo.EvVinculoAtualizado.new(eventos_ganho))
	_notificar_save_pendente()


## Atalho para `Save.pedir_saida(vinculo.consolidar_abandono)` (V20b, AC-VP-19).
func consolidar_abandono() -> void:
	consolidar_run(&"abandono", false)


## Pontos acumulados na run atual para [param especie_id].
func pontos_da_run(especie_id: StringName) -> int:
	if not _acumuladores.has(especie_id):
		return 0
	return PontosDeVinculo.calcular_pontos_run(_acumuladores[especie_id], _tuning)


## Permite somar pontos diretamente ao acumulador da run de [param especie_id] (útil em testes unitários).
func adicionar_pontos_diretos_na_run(especie_id: StringName, pontos: int) -> void:
	_garantir_acumulador(especie_id).somar_extra(pontos)


# --- Interno -----------------------------------------------------------------

func _iniciar_acumuladores_run() -> void:
	_acumuladores.clear()
	for esp: StringName in _dupla_run:
		if esp != &"":
			_acumuladores[esp] = PontosDeVinculo.AcumuladorDaRun.new(esp)


func _garantir_acumulador(especie_id: StringName) -> PontosDeVinculo.AcumuladorDaRun:
	if not _acumuladores.has(especie_id):
		_acumuladores[especie_id] = PontosDeVinculo.AcumuladorDaRun.new(especie_id)
	return _acumuladores[especie_id]


func _emitir_pacto(especie_id: StringName, origem: StringName) -> void:
	_eventos.emitir(EventosVinculo.EvPactoFormado.new(especie_id, origem))
	_eventos.emitir(EventosVinculo.EvPactoRegistrado.new(especie_id, origem))
	_notificar_save_pendente()


func _notificar_save_pendente() -> void:
	if _save != null and _save.has_method("marcar_pendente"):
		_save.call("marcar_pendente")
