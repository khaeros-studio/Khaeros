class_name Portas
extends RefCounted
## Módulo de Portas e recompensas: dono da [RewardTable], do sorteio das portas livres (F2),
## das portas forçadas ([code]santuario[/code], [code]chefe[/code], [code]ultima[/code]),
## da concessão da recompensa da câmara atual ([code]bencao[/code], [code]fragmentos[/code],
## [code]cura[/code]) e da máquina de estados pós-limpeza
## ([code]COMBATE -> RECOMPENSA / AGUARDANDO_BENCAO -> AGUARDANDO_PACTO -> PORTAS_ABERTAS / FIM_DA_REGIAO[/code]).
##
## Governado por ADR-0001, ADR-0002, ADR-0005, ADR-0009 e ADR-0015.
## Sem SceneTree, sem Autoload.

enum Estado {
	COMBATE,
	CONCEDENDO_RECOMPENSA,
	AGUARDANDO_BENCAO,
	AGUARDANDO_PACTO,
	PORTAS_ABERTAS,
	PORTA_ESCOLHIDA,
	FIM_DA_REGIAO,
}

const TIPO_BENCAO: StringName = &"bencao"
const TIPO_FRAGMENTOS: StringName = &"fragmentos"
const TIPO_CURA: StringName = &"cura"
const TIPO_PROVACAO: StringName = &"provacao"
const TIPO_SANTUARIO: StringName = &"santuario"
const TIPO_CHEFE: StringName = &"chefe"
const TIPO_ULTIMA: StringName = &"ultima"
const FIM_DA_RUN: StringName = &"fim_da_run"

const PORTAS_SEM_RECOMPENSA: Array[StringName] = [TIPO_SANTUARIO, TIPO_CHEFE, TIPO_ULTIMA]

## Tabela explícita de transições de estado (Code Standards).
const TRANSICOES: Dictionary = {
	Estado.COMBATE: [Estado.CONCEDENDO_RECOMPENSA, Estado.AGUARDANDO_BENCAO, Estado.AGUARDANDO_PACTO, Estado.PORTAS_ABERTAS, Estado.FIM_DA_REGIAO],
	Estado.CONCEDENDO_RECOMPENSA: [Estado.AGUARDANDO_BENCAO, Estado.AGUARDANDO_PACTO, Estado.PORTAS_ABERTAS],
	Estado.AGUARDANDO_BENCAO: [Estado.AGUARDANDO_PACTO, Estado.PORTAS_ABERTAS],
	Estado.AGUARDANDO_PACTO: [Estado.PORTAS_ABERTAS],
	Estado.PORTAS_ABERTAS: [Estado.PORTA_ESCOLHIDA, Estado.COMBATE],
	Estado.PORTA_ESCOLHIDA: [Estado.COMBATE],
	Estado.FIM_DA_REGIAO: [],
}

var _tabela: RewardTable
var _fluxos: FluxosDePortas
var _conta: ContaFragmentos
var _bencaos: Bencaos
var _eventos: EventosDoPasso
var _room_tuning: RoomTuning

# Colaboradores injetados (podem ser objetos ou Callables)
var _run: Object = null
var _camaras: Object = null
var _vinculo: Object = null
var _orquestrador: Object = null
var _portador_jogador: Portador = null
var _vida_getter: Callable = Callable()
var _vida_setter: Callable = Callable()
var _encontro_aguardando_cb: Callable = Callable()

var _estado: Estado = Estado.COMBATE
var _recompensa_pendente: StringName = TIPO_BENCAO
var _portas_atuais: Array[StringName] = []
var _vistas_atuais: Array[VistaDePorta] = []
var _tela_bencao_fechada: bool = false
var _pacto_resolvido_lembrado: bool = false
var _ultimo_p_limpo: int = 0
var _ultimo_indice_limpo: int = 0
var _regiao_idx_atual: int = 0
var _regiao_id_atual: StringName = &"limiar"


func _init(tabela: RewardTable, fluxos: FluxosDePortas = null, conta: ContaFragmentos = null,
		bencaos: Bencaos = null, eventos: EventosDoPasso = null, room_tuning: RoomTuning = null) -> void:
	_tabela = tabela if tabela != null else RewardTable.new()
	if _tabela.primeira_recompensa != &"":
		_recompensa_pendente = _tabela.primeira_recompensa
	else:
		_recompensa_pendente = TIPO_BENCAO
	_fluxos = fluxos
	_conta = conta if conta != null else ContaFragmentosNula.new()
	_bencaos = bencaos if bencaos != null else BencaosNula.new()
	_eventos = eventos if eventos != null else EventosDoPasso.new()
	_room_tuning = room_tuning


# --- Injeção de colaboradores (R11, R11-P, ADR-0015 §9) ----------------------

func configurar_run(run_ref: Object) -> void:
	_run = run_ref


func configurar_camaras(camaras_ref: Object) -> void:
	_camaras = camaras_ref


func configurar_vinculo(vinculo_ref: Object, encontro_aguardando_cb: Callable = Callable()) -> void:
	_vinculo = vinculo_ref
	_encontro_aguardando_cb = encontro_aguardando_cb


func configurar_orquestrador(orq: Object) -> void:
	_orquestrador = orq


func configurar_jogador(portador: Portador, vida_getter: Callable = Callable(), vida_setter: Callable = Callable()) -> void:
	_portador_jogador = portador
	_vida_getter = vida_getter
	_vida_setter = vida_setter


# --- Consultas ---------------------------------------------------------------

func estado() -> Estado:
	return _estado


func recompensa_pendente() -> StringName:
	return _recompensa_pendente


func definir_recompensa_pendente(tipo: StringName) -> void:
	_recompensa_pendente = tipo


func portas_atuais() -> Array[StringName]:
	return _portas_atuais.duplicate()


func vistas_de_porta() -> Array[VistaDePorta]:
	return _vistas_atuais.duplicate()


## Prepara o estado das Portas ao entrar numa nova câmara.
func iniciar_camara(recompensa: StringName = &"") -> void:
	if recompensa != &"":
		_recompensa_pendente = recompensa
	_estado = Estado.COMBATE
	_portas_atuais.clear()
	_vistas_atuais.clear()
	_tela_bencao_fechada = false
	_pacto_resolvido_lembrado = false


# --- R2 / R2-P: Fluxo de limpeza da câmara -----------------------------------

## Processa [code]camara_limpa(p, tipo)[/code] (R2-P):
## 0. Morte vence a limpeza: se a Run não está ativa ou [code]jogador_morreu[/code], não faz nada;
## 1. Se [param tipo_camara] == [code]santuario[/code]: nenhuma recompensa, vai direto ao passo 3 (abrir portas);
## 1b. Se a câmara é a última jogável ([code]proxima == fim_da_run[/code], ex.: chefe no índice 6):
##     nenhuma recompensa, nenhum [code]pedir_oferta[/code], nenhuma porta; vai a [code]FIM_DA_REGIAO[/code];
## 2. Concede a recompensa pendente da câmara (R3–R5); se bênção abrir oferta, entra em [code]AGUARDANDO_BENCAO[/code];
## 2b. Se [code]encontro_aguardando()[/code] for verdadeiro (e [code]pacto_resolvido[/code] ainda não chegou),
##     entra em [code]AGUARDANDO_PACTO[/code];
## 3. Pede às Câmaras que abram as portas para a próxima câmara.
func ao_camara_limpa(p: int, tipo_camara: StringName, indice_camara: int = -1,
		regiao_id: StringName = &"limiar", regiao_idx: int = 0) -> void:
	# Passo 0: morte vence a limpeza (AC-PR-23, ADR-0015 §3)
	if not _run_esta_ativa() or _jogador_morreu():
		return

	var idx: int = indice_camara if indice_camara >= 0 else _obter_indice_da_run()
	_ultimo_p_limpo = p
	_ultimo_indice_limpo = idx
	_regiao_id_atual = regiao_id if regiao_id != &"" else _obter_regiao_id_da_run()
	_regiao_idx_atual = regiao_idx

	# Passo 1: santuário (AC-PR-06)
	if tipo_camara == TIPO_SANTUARIO:
		_recompensa_pendente = &""
		_abrir_portas_do_indice(idx, _regiao_idx_atual)
		return

	# Passo 1b: última câmara jogável / chefe (AC-PR-24, AC-PR-30)
	var prox: StringName = _proxima_da_run(idx)
	if tipo_camara == TIPO_CHEFE or prox == FIM_DA_RUN:
		_transicionar(Estado.FIM_DA_REGIAO)
		_notificar_run_fim_se_necessario(p, tipo_camara, idx)
		return

	# Passo 2: conceder recompensa da câmara atual
	_transicionar(Estado.CONCEDENDO_RECOMPENSA)
	var abriu_bencao: bool = _conceder_recompensa_atual(p, idx, _regiao_id_atual)
	if abriu_bencao:
		_transicionar(Estado.AGUARDANDO_BENCAO)
		if _orquestrador != null and _orquestrador.has_method("pedir_estado"):
			_orquestrador.call("pedir_estado", EstadoDeJogo.Valor.BENCAO)
		return

	# Passo 2b -> Passo 3
	_avancar_para_passo_2b_ou_3()


## Concede uma recompensa diretamente (útil em testes unitários da Story 004).
## Devolve [code]true[/code] se uma oferta de bênção ficou aberta esperando escolha.
func conceder(tipo_recompensa: StringName, p: int, indice_camara: int = 0,
		regiao_id: StringName = &"limiar") -> bool:
	_recompensa_pendente = tipo_recompensa
	return _conceder_recompensa_atual(p, indice_camara, regiao_id)


## Notificação da Tela de bênção de que a tela fechou (R2 passo 2, AC-PR-25).
func ao_tela_bencao_fechada() -> void:
	if _estado != Estado.AGUARDANDO_BENCAO:
		return
	_tela_bencao_fechada = true


## Notificação de que a bênção foi escolhida (R2 passo 2, AC-PR-02, AC-PR-25).
## Só é aceita em [code]AGUARDANDO_BENCAO[/code] e depois de [method ao_tela_bencao_fechada].
func ao_bencao_escolhida(_bencao_id: StringName = &"") -> bool:
	if _estado != Estado.AGUARDANDO_BENCAO or not _tela_bencao_fechada:
		return false
	if not _run_esta_ativa() or _jogador_morreu():
		return false
	if _orquestrador != null and _orquestrador.has_method("pedir_estado"):
		_orquestrador.call("pedir_estado", EstadoDeJogo.Valor.JOGO)
	_avancar_para_passo_2b_ou_3()
	return true


## Notificação do Vínculo de que o encontro de pacto foi resolvido (R2-P passo 2b, AC-PR-26..29).
## Se chegar enquanto a Bênção ainda está aberta, fica lembrado e libera o passo 2b na hora.
func ao_pacto_resolvido() -> bool:
	if not _run_esta_ativa() or _jogador_morreu():
		return false
	if _estado == Estado.AGUARDANDO_BENCAO or _estado == Estado.CONCEDENDO_RECOMPENSA:
		_pacto_resolvido_lembrado = true
		return true
	if _estado != Estado.AGUARDANDO_PACTO:
		return false
	_abrir_portas_do_indice(_ultimo_indice_limpo, _regiao_idx_atual)
	return true


# --- R6 / R6-P / R7 / R8 / R9: Sorteio e escolha das portas ------------------

## Decide quais portas abrir após limpar a câmara de índice [param indice_camara] (R6-P, R7, AC-PR-32, AC-PR-33).
## - Se [param tipo_proxima] == [code]santuario[/code]: [code][&"santuario"][/code] (0 reais);
## - Se [param tipo_proxima] == [code]chefe[/code]: [code][&"chefe"][/code] (0 reais);
## - Se [param tipo_proxima] == [code]ultima[/code]: [code][&"ultima"][/code] (0 reais, só quando última jogável não é chefe);
## - Se [param tipo_proxima] == [code]fim_da_run[/code]: [code][][/code] (0 reais);
## - Se [param tipo_proxima] == [code]combate[/code]: sorteia 2 ou 3 portas distintas consumindo 4 reais
##   do fluxo [code](portas, regiao_idx, indice_camara)[/code].
func portas_para_indice(indice_camara: int, regiao_idx: int = 0, tipo_proxima_override: StringName = &"") -> Array[StringName]:
	var prox: StringName = tipo_proxima_override if tipo_proxima_override != &"" else _proxima_da_run(indice_camara)
	match prox:
		FIM_DA_RUN, &"":
			return []
		TIPO_SANTUARIO:
			return [TIPO_SANTUARIO]
		TIPO_CHEFE:
			return [TIPO_CHEFE]
		TIPO_ULTIMA:
			return [TIPO_ULTIMA]
		_:
			# Se a próxima câmara é a última jogável e NÃO é chefe (modo legado de 6 câmaras, AC-PR-08):
			if _proxima_eh_ultima_sem_recompensa(indice_camara + 1):
				return [TIPO_ULTIMA]
			var f_portas: FluxoRng = _fluxos.portas(regiao_idx, indice_camara) if _fluxos != null else null
			return SorteioDePortas.sortear(_tabela, f_portas)


## Processa a escolha da porta de índice [param k] (0..n-1, da esquerda para a direita) (R9, R9-P, AC-PR-16, AC-PR-36).
func ao_porta_escolhida(k: int) -> bool:
	if _estado != Estado.PORTAS_ABERTAS:
		return false
	if k < 0 or k >= _portas_atuais.size():
		return false
	var tipo_escolhido: StringName = _portas_atuais[k]
	var opcoes: Array[StringName] = _portas_atuais.duplicate()
	if PORTAS_SEM_RECOMPENSA.has(tipo_escolhido):
		_recompensa_pendente = &""
	else:
		_recompensa_pendente = tipo_escolhido
	_transicionar(Estado.PORTA_ESCOLHIDA)
	_eventos.emitir(EventosDePortas.EvPortaEscolhida.new(k, tipo_escolhido, opcoes))
	if _run != null:
		if _run.has_method("definir_recompensa_proxima"):
			_run.call("definir_recompensa_proxima", _recompensa_pendente)
		if _run.has_method("avancar"):
			_run.call("avancar")
	return true


# --- Interno -----------------------------------------------------------------

func _conceder_recompensa_atual(p: int, indice_camara: int, regiao_id: StringName) -> bool:
	var tipo_rec: StringName = _recompensa_pendente
	if tipo_rec == &"":
		tipo_rec = _tabela.primeira_recompensa if _tabela.primeira_recompensa != &"" else TIPO_BENCAO

	if tipo_rec == TIPO_BENCAO:
		# R3: se não restar nenhuma bênção no pool, vira Fragmentos (AC-PR-03)
		if _bencaos == null or _bencaos.restantes() <= 0:
			_conceder_fragmentos(p)
			return false
		_eventos.emitir(EventosDePortas.EvRecompensa.new(TIPO_BENCAO, 3))
		var resp: StringName = _bencaos.pedir_oferta(regiao_id, indice_camara)
		if resp == Bencaos.SEM_BENCAO:
			# Pool esgotou durante o pedido: converte em Fragmentos
			_conceder_fragmentos(p)
			return false
		_tela_bencao_fechada = false
		return resp == Bencaos.ABERTA or resp == Bencaos.OFERTA_JA_ABERTA

	if tipo_rec == TIPO_FRAGMENTOS:
		_conceder_fragmentos(p)
		return false

	if tipo_rec == TIPO_CURA:
		_conceder_cura()
		return false

	return false


func _conceder_fragmentos(p: int) -> void:
	var qtd: int = FormulasDePortas.fragmentos_por_porta(_tabela, p)
	if _conta != null:
		_conta.creditar(ContaFragmentos.PORTA, qtd)
	_eventos.emitir(EventosDePortas.EvRecompensa.new(TIPO_FRAGMENTOS, qtd))


func _conceder_cura() -> void:
	var vida_max: int = 100
	if _portador_jogador != null:
		vida_max = _portador_jogador.inteiro(Atributos.VIDA_MAX)
	var nominal: int = FormulasDePortas.cura_nominal_porta(_tabela, vida_max)
	if _vida_getter.is_valid() and _vida_setter.is_valid():
		var atual: int = int(_vida_getter.call())
		var nova: int = FormulasDePortas.aplicar_cura_porta(_tabela, atual, vida_max)
		_vida_setter.call(nova)
	_eventos.emitir(EventosDePortas.EvRecompensa.new(TIPO_CURA, nominal))


func _avancar_para_passo_2b_ou_3() -> void:
	if not _run_esta_ativa() or _jogador_morreu():
		return
	if _encontro_esta_aguardando() and not _pacto_resolvido_lembrado:
		_transicionar(Estado.AGUARDANDO_PACTO)
		return
	_pacto_resolvido_lembrado = false
	_abrir_portas_do_indice(_ultimo_indice_limpo, _regiao_idx_atual)


func _abrir_portas_do_indice(indice_camara: int, regiao_idx: int) -> void:
	if not _run_esta_ativa() or _jogador_morreu():
		return
	_portas_atuais = portas_para_indice(indice_camara, regiao_idx)
	if _portas_atuais.is_empty():
		_transicionar(Estado.FIM_DA_REGIAO)
		return
	var p_prox_combate: int = _profundidade_proxima_camara_combate(indice_camara)
	var quantidades: Array[int] = []
	_vistas_atuais.clear()
	var posicoes: Array[Vector2] = _calcular_posicoes_portas(_portas_atuais.size())
	for i: int in _portas_atuais.size():
		var t: StringName = _portas_atuais[i]
		var qtd: int = _quantidade_mostrada_na_porta(t, p_prox_combate)
		var rotulo: String = _rotulo_mostrado_na_porta(t, qtd)
		var carrega: bool = not PORTAS_SEM_RECOMPENSA.has(t)
		quantidades.append(qtd)
		_vistas_atuais.append(VistaDePorta.new(i, t, qtd, rotulo, posicoes[i], true, carrega))
	_transicionar(Estado.PORTAS_ABERTAS)
	if _camaras != null and _camaras.has_method("abrir_portas"):
		_camaras.call("abrir_portas", _portas_atuais, quantidades)
	_eventos.emitir(EventosDePortas.EvPortasAbertas.new(_portas_atuais, quantidades))


func _quantidade_mostrada_na_porta(tipo_porta: StringName, p_proxima_combate: int) -> int:
	match tipo_porta:
		TIPO_FRAGMENTOS:
			return FormulasDePortas.fragmentos_por_porta(_tabela, p_proxima_combate)
		TIPO_CURA:
			return Unidades.arredondar_meio_longe_do_zero(_tabela.cura_porta * 100.0)
		TIPO_BENCAO:
			return 3
		_:
			return 0


func _rotulo_mostrado_na_porta(tipo_porta: StringName, qtd: int) -> String:
	match tipo_porta:
		TIPO_FRAGMENTOS:
			return "+%d" % qtd
		TIPO_CURA:
			return "+%d%%" % qtd
		TIPO_BENCAO:
			return "3 ofertas"
		_:
			return ""


func _profundidade_proxima_camara_combate(indice_camara_atual: int) -> int:
	if _camaras != null and _camaras.has_method("profundidade_para_indice"):
		return int(_camaras.call("profundidade_para_indice", indice_camara_atual + 1))
	return _ultimo_p_limpo + 1


func _calcular_posicoes_portas(n: int) -> Array[Vector2]:
	var rt: RoomTuning = _room_tuning
	if rt == null:
		rt = RoomTuning.new()
		rt.camara_largura_px = 1920.0
		rt.portas_espaco_px = 450.0
		rt.portas_y_px = 177.0
	return PortasFisicas.calcular_posicoes(n, rt)


func _encontro_esta_aguardando() -> bool:
	if _encontro_aguardando_cb.is_valid():
		return bool(_encontro_aguardando_cb.call())
	if _vinculo != null and _vinculo.has_method("encontro_aguardando"):
		return bool(_vinculo.call("encontro_aguardando"))
	return false


func _run_esta_ativa() -> bool:
	if _run != null and _run.has_method("ativa"):
		return bool(_run.call("ativa"))
	return true


func _jogador_morreu() -> bool:
	if _eventos != null and _eventos.ha(&"jogador_morreu"):
		return true
	return false


func _proxima_da_run(indice_camara: int) -> StringName:
	if _run != null and _run.has_method("proxima"):
		return _run.call("proxima", indice_camara)
	# Padrão Limiar de 7 câmaras se Run não injetada
	const PADRAO_LIMIAR: Array[StringName] = [
		&"combate", &"combate", &"combate", &"santuario", &"combate", &"combate", &"chefe"
	]
	if indice_camara + 1 < PADRAO_LIMIAR.size():
		return PADRAO_LIMIAR[indice_camara + 1]
	return FIM_DA_RUN


func _proxima_eh_ultima_sem_recompensa(indice_proxima: int) -> bool:
	if _run != null and _run.has_method("eh_ultima_camara_sem_chefe"):
		return bool(_run.call("eh_ultima_camara_sem_chefe", indice_proxima))
	return false


func _obter_indice_da_run() -> int:
	if _run != null and _run.has_method("indice"):
		return int(_run.call("indice"))
	return 0


func _obter_regiao_id_da_run() -> StringName:
	if _run != null and _run.has_method("regiao"):
		return _run.call("regiao")
	return &"limiar"


func _notificar_run_fim_se_necessario(p: int, tipo_camara: StringName, indice_camara: int) -> void:
	if _run != null and _run.has_method("ao_camara_limpa"):
		_run.call("ao_camara_limpa", p, tipo_camara, indice_camara)


func _transicionar(novo: Estado) -> bool:
	var permitidos: Array = TRANSICOES.get(_estado, [])
	if _estado == novo or permitidos.has(novo):
		_estado = novo
		return true
	_estado = novo
	return false
