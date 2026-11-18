class_name Run
extends RefCounted
## Máquina de estados e orquestração da Run (GDD run-e-regioes.md R1–R11-P, F1–F3; ADR-0015 §3–§8).
##
## Estados (`Fase`):
## - [code]SEM_RUN -> ESCOLHA_DE_ARMA -> ESCOLHA_DA_DUPLA (só Pactos com >= 2 pactuadas) -> ATIVA -> ENCERRADA[/code].
## - Aliases compatíveis: [code]PREPARANDO[/code], [code]ESCOLHA_INICIAL[/code], [code]EM_CAMARA[/code],
##   [code]TRANSICAO[/code], [code]VITORIA[/code], [code]DERROTA[/code], [code]ABANDONADA[/code].
## - Coordena com o [OrquestradorDoPasso] apenas por [method OrquestradorDoPasso.pedir_estado].
## - Dono da sequência da região ([method proxima], [method avancar]), da condição de vitória no chefe
##   (+15 Fragmentos de vitória; total máximo no Limiar = 25 ao Pactuar ou 31 ao Exorcizar/Abater),
##   da morte (morte vence a limpeza), do abandono e do [ResumoDaRun] imutável.

enum Fase {
	SEM_RUN,
	ESCOLHA_DE_ARMA,
	ESCOLHA_DA_DUPLA,
	ATIVA,
	ENCERRADA,
}

## Aliases legíveis pedidos pelos contratos de estado da run:
const PREPARANDO: Fase = Fase.SEM_RUN
const ESCOLHA_INICIAL: Fase = Fase.ESCOLHA_DE_ARMA
const EM_CAMARA: Fase = Fase.ATIVA
const VITORIA: StringName = ResumoDaRun.MOTIVO_VITORIA
const DERROTA: StringName = ResumoDaRun.MOTIVO_MORTE
const ABANDONADA: StringName = ResumoDaRun.MOTIVO_ABANDONO

const FIM_DA_RUN: StringName = &"fim_da_run"
const DOUTRINA_LAMINA: StringName = &"lamina"
const DOUTRINA_RESSONANCIA: StringName = &"ressonancia"
const DOUTRINA_PACTOS: StringName = &"pactos"
const CARTAS_DE_ARMA: Array[StringName] = [DOUTRINA_LAMINA, DOUTRINA_RESSONANCIA, DOUTRINA_PACTOS]

## Tabela explícita de transições de `Fase` (AC-RN-01).
const TRANSICOES: Dictionary = {
	Fase.SEM_RUN: [Fase.ESCOLHA_DE_ARMA],
	Fase.ESCOLHA_DE_ARMA: [Fase.ESCOLHA_DA_DUPLA, Fase.ATIVA],
	Fase.ESCOLHA_DA_DUPLA: [Fase.ESCOLHA_DE_ARMA, Fase.ATIVA],
	Fase.ATIVA: [Fase.ENCERRADA],
	Fase.ENCERRADA: [Fase.ESCOLHA_DE_ARMA],
}

var _run_tuning: RunTuning
var _regioes: Array[RegionDef] = []
var _fonte_fluxos: FonteDeFluxos
var _criador_seed: CriadorDeSeed
var _conta: ContaFragmentos
var _eventos: EventosDoPasso
var _preferencias_arma: PreferenciasDeArma

# Colaboradores opcionais de sessão/run
var _orquestrador: Object = null
var _camaras: Object = null
var _portas: Object = null
var _vinculo: Object = null
var _bencaos: Object = null
var _maldicoes: Object = null
var _combate: Object = null
var _ao_montar_escopo_cb: Callable = Callable()
var _ao_abrir_tela_final_cb: Callable = Callable()

# Estado da run
var _fase: Fase = Fase.SEM_RUN
var _motivo_fim: StringName = &""
var _arma_escolhida: StringName = &""
var _doutrina_atual: StringName = &""
var _dupla_inicial: Array[StringName] = []
var _regiao_idx: int = 0
var _indice_camara: int = 0
var _camaras_limpas_contagem: int = 0
var _abates_contagem: int = 0
var _passos_inicio_run: int = 0
var _passos_acumulados_manual: int = 0
var _seed_atual: int = 0
var _seed_texto: String = TextoDaSeed.TEXTO_SEM_SEED
var _recompensa_primeira_camara: StringName = &"bencao"
var _recompensa_proxima_camara: StringName = &""
var _vida_inicial_jogador: int = 100
var _vida_atual_jogador: int = 100
var _chefe_subjugado_pendente: bool = false
var _desfecho_chefe_registrado: StringName = ResumoDaRun.DESFECHO_NENHUM
var _resumo: ResumoDaRun = null
var _tela_final_aberta_vezes: int = 0
var _erros: Array[StringName] = []


func _init(run_tuning: RunTuning = null, regiao_principal: RegionDef = null,
		fonte_fluxos: FonteDeFluxos = null, criador_seed: CriadorDeSeed = null,
		conta: ContaFragmentos = null, eventos: EventosDoPasso = null,
		preferencias_arma: PreferenciasDeArma = null) -> void:
	_run_tuning = run_tuning if run_tuning != null else _run_tuning_padrao()
	if regiao_principal != null:
		_regioes.append(regiao_principal)
	else:
		_regioes.append(_regiao_limiar_padrao())
	_fonte_fluxos = fonte_fluxos if fonte_fluxos != null else FonteDeFluxos.new(RelatorDeErrosRng.new())
	_criador_seed = criador_seed
	_conta = conta if conta != null else ContaFragmentosNula.new()
	_eventos = eventos if eventos != null else EventosDoPasso.new()
	_preferencias_arma = preferencias_arma if preferencias_arma != null else PreferenciasDeArmaEmMemoria.new()


static func _run_tuning_padrao() -> RunTuning:
	var rt := RunTuning.new()
	rt.id = &"run_tuning"
	rt.arma_padrao = DOUTRINA_LAMINA
	rt.fragmentos_vitoria = 15
	rt.camaras_jogaveis = {&"limiar": 7}
	return rt


static func _regiao_limiar_padrao() -> RegionDef:
	var r := RegionDef.new()
	r.id = &"limiar"
	r.chave_nome = &"REGION_LIMIAR_NAME"
	r.camaras = [&"combate", &"combate", &"combate", &"santuario", &"combate", &"combate", &"chefe"]
	r.pool_inimigos = [&"eco_perdido"]
	r.chefe = &"soberano_do_limiar"
	r.fragmentos_chefe = 6
	return r


# --- Configuração de colaboradores -------------------------------------------

func definir_regioes(lista: Array[RegionDef]) -> void:
	if not lista.is_empty():
		_regioes = lista.duplicate()


func configurar_orquestrador(orq: Object) -> void:
	_orquestrador = orq


func configurar_camaras(camaras_ref: Object) -> void:
	_camaras = camaras_ref


func configurar_portas(portas_ref: Object, primeira_recompensa: StringName = &"bencao") -> void:
	_portas = portas_ref
	if primeira_recompensa != &"":
		_recompensa_primeira_camara = primeira_recompensa


func configurar_vinculo(vinculo_ref: Object) -> void:
	_vinculo = vinculo_ref


func configurar_bencaos(bencaos_ref: Object) -> void:
	_bencaos = bencaos_ref


func configurar_maldicoes(maldicoes_ref: Object) -> void:
	_maldicoes = maldicoes_ref


func configurar_combate(combate_ref: Object) -> void:
	_combate = combate_ref


func configurar_callbacks(ao_montar_escopo: Callable = Callable(), ao_abrir_tela_final: Callable = Callable()) -> void:
	_ao_montar_escopo_cb = ao_montar_escopo
	_ao_abrir_tela_final_cb = ao_abrir_tela_final


# --- Consultas (ADR-0015 Key Interfaces) -------------------------------------

func fase() -> Fase:
	return _fase


func ativa() -> bool:
	return _fase == Fase.ATIVA


func doutrina() -> StringName:
	return _doutrina_atual


func arma() -> StringName:
	return _arma_escolhida


func cartas_disponiveis() -> Array[StringName]:
	return CARTAS_DE_ARMA.duplicate()


func arma_sugerida() -> StringName:
	var ult: StringName = _preferencias_arma.ultima_arma() if _preferencias_arma != null else &""
	if ult != &"" and CARTAS_DE_ARMA.has(ult):
		return ult
	if _run_tuning != null and CARTAS_DE_ARMA.has(_run_tuning.arma_padrao):
		return _run_tuning.arma_padrao
	return DOUTRINA_LAMINA


func regiao() -> StringName:
	var r: RegionDef = _regiao_atual_def()
	return r.id if r != null else &"limiar"


func regiao_indice() -> int:
	return _regiao_idx


func indice() -> int:
	return _indice_camara


func chave_estrutura() -> Vector2i:
	return Vector2i(_regiao_idx, _indice_camara)


func seed_valor() -> int:
	return _seed_atual


func seed_texto() -> String:
	return _seed_texto


func vida_inicial_jogador() -> int:
	return _vida_inicial_jogador


func vida_atual_jogador() -> int:
	return _vida_atual_jogador


func definir_vida_atual_jogador(v: int) -> void:
	_vida_atual_jogador = clampi(v, 0, _vida_inicial_jogador)


func dupla() -> Array[StringName]:
	return _dupla_inicial.duplicate()


func resumo() -> ResumoDaRun:
	return _resumo


func tela_final_aberta_vezes() -> int:
	return _tela_final_aberta_vezes


func chefe_subjugado_pendente() -> bool:
	return _chefe_subjugado_pendente


func erros() -> Array[StringName]:
	return _erros.duplicate()


## Lê [code]p_max[/code] das Câmaras (dono único: Câmaras R3; Run R9, AC-RN-21).
func p_max() -> int:
	var n_jog: int = camaras_jogaveis_da_regiao()
	if _camaras != null and _camaras.has_method("p_max"):
		return int(_camaras.call("p_max", n_jog))
	var r: RegionDef = _regiao_atual_def()
	if r == null:
		return 4
	return ProfundidadeCamara.calcular_p_max(r.camaras, n_jog)


## Quantidade de câmaras jogáveis na região atual (7 no Limiar com chefe; 6 no modo legado sem chefe).
func camaras_jogaveis_da_regiao(idx_reg: int = -1) -> int:
	var r: RegionDef = _regiao_def(idx_reg if idx_reg >= 0 else _regiao_idx)
	if r == null:
		return 7
	if _run_tuning != null and _run_tuning.camaras_jogaveis.has(r.id):
		return int(_run_tuning.camaras_jogaveis[r.id])
	return r.camaras.size()


## Tipo da câmara seguinte a [param i] na região atual, ou [code]&"fim_da_run"[/code] (R3, R3-P, AC-RN-06, AC-RN-30).
func proxima(i: int = -1) -> StringName:
	var idx: int = i if i >= 0 else _indice_camara
	var r: RegionDef = _regiao_atual_def()
	var n_jog: int = camaras_jogaveis_da_regiao()
	if r == null or idx + 1 >= n_jog or idx + 1 >= r.camaras.size():
		# R10: se houver outra região na lista depois desta, indica transição de região
		if _regiao_idx + 1 < _regioes.size():
			var prox_r: RegionDef = _regioes[_regiao_idx + 1]
			if not prox_r.camaras.is_empty():
				return prox_r.camaras[0]
		return FIM_DA_RUN
	return r.camaras[idx + 1]


## Verdadeiro se a câmara [param indice_camara] é a última jogável da região e NÃO é chefe (modo legado de 6 câmaras, AC-PR-08).
func eh_ultima_camara_sem_chefe(indice_camara: int) -> bool:
	var r: RegionDef = _regiao_atual_def()
	var n_jog: int = camaras_jogaveis_da_regiao()
	if r == null or indice_camara != n_jog - 1 or indice_camara >= r.camaras.size():
		return false
	return r.camaras[indice_camara] != &"chefe"


## Valida e pede a montagem do índice [param i] (R3, R3-P, AC-RN-07, AC-RN-30).
## Se [param i] < 0 ou >= [code]camaras_jogaveis[/code], registra e devolve o erro [code]&"RN3"[/code].
func validar_montagem_camara(i: int) -> StringName:
	var n_jog: int = camaras_jogaveis_da_regiao()
	var r: RegionDef = _regiao_atual_def()
	if r == null or i < 0 or i >= n_jog or i >= r.camaras.size():
		_erros.append(&"RN3")
		return &"RN3"
	return &""


# --- Fluxo de início da run (R1, R1-P, R2, R2-P; AC-RN-01..05, AC-RN-27..29) -

## Entra em [code]ESCOLHA_DE_ARMA[/code] (a partir de [code]SEM_RUN[/code], [code]ESCOLHA_DA_DUPLA[/code] ou via [method nova_run]).
func iniciar_escolha_de_arma() -> bool:
	if not _pode_transicionar(Fase.ESCOLHA_DE_ARMA):
		return false
	_fase = Fase.ESCOLHA_DE_ARMA
	_pedir_estado_orquestrador(EstadoDeJogo.Valor.MENU)
	return true


## Confirma a arma na tela de início (R2 passo 1, R2-P passo 1 e 1b).
## Se [param id_arma] for vazio, usa a última escolhida ou [code]arma_padrao[/code] (AC-RN-03).
func confirmar_arma(id_arma: StringName = &"", texto_seed_debug: String = "") -> bool:
	if _fase == Fase.SEM_RUN:
		iniciar_escolha_de_arma()
	if _fase != Fase.ESCOLHA_DE_ARMA:
		return false

	var escolhida: StringName = id_arma if id_arma != &"" else arma_sugerida()
	if not CARTAS_DE_ARMA.has(escolhida):
		_erros.append(&"RN1")
		return false

	_arma_escolhida = escolhida
	_doutrina_atual = escolhida
	if _preferencias_arma != null:
		_preferencias_arma.lembrar_arma(escolhida)

	# R2-P 1b: se Doutrina é `pactos`, pede a dupla ao Vínculo ANTES de criar a seed!
	if _doutrina_atual == DOUTRINA_PACTOS:
		if _vinculo != null and _vinculo.has_method("pedir_dupla"):
			var abriu_tela: bool = bool(_vinculo.call("pedir_dupla", DOUTRINA_PACTOS))
			if abriu_tela:
				_fase = Fase.ESCOLHA_DA_DUPLA
				return true
			# Se não abriu tela (0 ou 1 pactuada), o Vínculo já fixou a dupla (ex.: vulto_mudo)
			if _vinculo.has_method("dupla_da_run"):
				var d: Array[StringName] = _vinculo.call("dupla_da_run")
				var c_id: StringName = d[0] if d.size() > 0 else &""
				var r_id: StringName = d[1] if d.size() > 1 else &""
				return _concluir_inicio_da_run([c_id, r_id], texto_seed_debug)
		# Sem Vínculo real (dublê ausente): segue com dupla vazia
		return _concluir_inicio_da_run([], texto_seed_debug)

	# Lâmina ou Ressonância: vai direto a ATIVA sem pedir dupla (AC-RN-27)
	_dupla_inicial = []
	return _concluir_inicio_da_run([], texto_seed_debug)


## Recebe `dupla_confirmada(campo, reserva)` do Vínculo (R2-P 1b, AC-RN-27, AC-RN-29).
## Valida repetição, vazio-com-reserva e espécie não pactuada.
func confirmar_dupla(campo: StringName, reserva: StringName = &"", texto_seed_debug: String = "") -> bool:
	if _fase != Fase.ESCOLHA_DA_DUPLA and _fase != Fase.ESCOLHA_DE_ARMA:
		return false
	# Validação de borda da Run (Edge Case: "dupla_confirmada com espécie não pactuada ou repetida"):
	if campo == &"" and reserva != &"":
		_erros.append(&"DUPLA_INVALIDA")
		return false
	if campo != &"" and campo == reserva:
		_erros.append(&"DUPLA_REPETIDA")
		return false
	if _vinculo != null and _vinculo.has_method("perfil"):
		var perf: PerfilVinculo = _vinculo.call("perfil")
		if perf != null:
			var pactuadas: Array[StringName] = perf.especies_pactuadas_ativas()
			if (campo != &"" and not pactuadas.has(campo)) or (reserva != &"" and not pactuadas.has(reserva)):
				_erros.append(&"ESPECIE_NAO_PACTUADA")
				return false
	if _vinculo != null and _vinculo.has_method("confirmar_dupla") and _vinculo.call("tela_dupla_aberta"):
		if not bool(_vinculo.call("confirmar_dupla", campo, reserva)):
			_erros.append(&"DUPLA_RECUSADA")
			return false
	var d: Array[StringName] = []
	if campo != &"":
		d = [campo, reserva]
	return _concluir_inicio_da_run(d, texto_seed_debug)


## Esc na tela de Escolha da dupla: volta para [code]ESCOLHA_DE_ARMA[/code] sem criar seed (R2-P 1b, AC-RN-29).
func voltar_da_escolha_da_dupla() -> bool:
	if _fase != Fase.ESCOLHA_DA_DUPLA:
		return false
	if _vinculo != null and _vinculo.has_method("cancelar_escolha_dupla"):
		_vinculo.call("cancelar_escolha_dupla")
	_fase = Fase.ESCOLHA_DE_ARMA
	return true


func _concluir_inicio_da_run(dupla_escolhida: Array[StringName], texto_seed_debug: String = "") -> bool:
	# 2. Cria a seed (sorteada ou --seed= em debug; se --seed inválida no GDD Run Edge Cases, cai no provedor)
	_seed_atual = _gerar_seed(texto_seed_debug)
	_seed_texto = TextoDaSeed.formatar(_seed_atual)
	_fonte_fluxos.descartar_run()
	_fonte_fluxos.iniciar_run(_seed_atual, _doutrina_atual == DOUTRINA_PACTOS)

	# 3. Fixa o estado inicial (arma, Doutrina, Vida máxima: 100 Lâmina, 80 Ressonância, 90 Pactos — AC-RN-05, AC-RN-28)
	_dupla_inicial = dupla_escolhida.duplicate()
	_vida_inicial_jogador = _vida_base_por_arma(_arma_escolhida)
	_vida_atual_jogador = _vida_inicial_jogador
	_regiao_idx = 0
	_indice_camara = 0
	_camaras_limpas_contagem = 0
	_abates_contagem = 0
	_passos_acumulados_manual = 0
	_passos_inicio_run = _ler_passos_orquestrador()
	_chefe_subjugado_pendente = false
	_desfecho_chefe_registrado = ResumoDaRun.DESFECHO_NENHUM
	_resumo = null
	_tela_final_aberta_vezes = 0
	_recompensa_proxima_camara = _recompensa_primeira_camara

	_fase = Fase.ATIVA

	if _ao_montar_escopo_cb.is_valid():
		_ao_montar_escopo_cb.call(_arma_escolhida, _dupla_inicial, _seed_atual)

	if _maldicoes != null and _maldicoes.has_method("iniciar_dupla"):
		_maldicoes.call("iniciar_dupla", _dupla_inicial)

	# Planeja o encontro de pacto no fluxo `pactos` (só Pactos — ADR-0015 §3)
	if _vinculo != null and _vinculo.has_method("planejar_encontro"):
		var f_pactos: FluxoRng = null
		if _doutrina_atual == DOUTRINA_PACTOS:
			f_pactos = FluxosDeVinculo.new(_fonte_fluxos).pactos(_regiao_idx)
		_vinculo.call("planejar_encontro", _doutrina_atual, f_pactos)

	# 4. Pede às Câmaras a câmara de índice 0 com `primeira_recompensa` (bênção)
	if _portas != null and _portas.has_method("iniciar_camara"):
		_portas.call("iniciar_camara", _recompensa_primeira_camara)
	if _camaras != null and _camaras.has_method("trocar"):
		_camaras.call("trocar", 0, _recompensa_primeira_camara, _regiao_idx)

	_eventos.emitir(EventosDaRun.EvRunIniciada.new(_seed_atual, _seed_texto, _arma_escolhida, _doutrina_atual, _dupla_inicial))

	# 5. Pede a Transição de entrada ao orquestrador
	_pedir_estado_orquestrador(EstadoDeJogo.Valor.TRANSICAO)
	return true


# --- Avanço de câmara, vitória, morte, abandono e pausa (R3–R8) --------------

func definir_recompensa_proxima(tipo: StringName) -> void:
	_recompensa_proxima_camara = tipo


func recompensa_proxima() -> StringName:
	return _recompensa_proxima_camara


## Chamado pelas Portas após `porta_escolhida` (ADR-0015 §4 passo 4, R3, R10).
func avancar() -> bool:
	if _fase != Fase.ATIVA:
		return false
	var n_jog: int = camaras_jogaveis_da_regiao()
	if _indice_camara + 1 < n_jog:
		_indice_camara += 1
	elif _regiao_idx + 1 < _regioes.size():
		_regiao_idx += 1
		_indice_camara = 0
	else:
		return false

	if _portas != null and _portas.has_method("iniciar_camara"):
		_portas.call("iniciar_camara", _recompensa_proxima_camara)
	if _camaras != null and _camaras.has_method("trocar"):
		_camaras.call("trocar", _indice_camara, _recompensa_proxima_camara, _regiao_idx, false)
	return true


## Registra que o chefe entrou em `Subjugado` (R4-P, AC-RN-33, AC-RN-34).
## Só é aceito em runs da Doutrina `pactos` na última câmara jogável (chefe).
func ao_chefe_subjugado(chefe_id: StringName = &"soberano_do_limiar") -> bool:
	if _fase != Fase.ATIVA:
		return false
	if _doutrina_atual != DOUTRINA_PACTOS:
		_erros.append(&"CHEFE_SUBJUGADO_FORA_DE_PACTOS")
		return false
	_chefe_subjugado_pendente = true
	if _vinculo != null and _vinculo.has_method("ao_chefe_subjugado"):
		_vinculo.call("ao_chefe_subjugado", chefe_id)
	return true


## Recebe `chefe_escolhido(id, escolha)` de Vínculo e pactos (R4-P passo 3, AC-RN-33, AC-RN-37).
## Ignorado se a run não está na câmara do chefe ou se não houve `chefe_subjugado` antes.
func ao_chefe_escolhido(_chefe_id: StringName, escolha: StringName) -> bool:
	var n_jog: int = camaras_jogaveis_da_regiao()
	if _fase != Fase.ATIVA or _indice_camara != n_jog - 1 or not _chefe_subjugado_pendente:
		return false
	if escolha == &"pactuar":
		_desfecho_chefe_registrado = ResumoDaRun.DESFECHO_PACTUADO
	elif escolha == &"exorcizar":
		_desfecho_chefe_registrado = ResumoDaRun.DESFECHO_EXORCIZADO
	return true


## Recebe `camara_limpa(p, tipo)` das Câmaras (R4, R4-P, AC-RN-08..10, AC-RN-31..33).
func ao_camara_limpa(p: int, tipo_camara: StringName, indice_override: int = -1,
		morte_no_mesmo_passo: bool = false) -> void:
	if _fase != Fase.ATIVA:
		return
	# R5 / AC-RN-16 / AC-RN-35: se jogador_morreu no mesmo passo, morte vence!
	if morte_no_mesmo_passo or (_eventos != null and _eventos.ha(&"jogador_morreu")):
		ao_jogador_morreu()
		return

	var idx: int = indice_override if indice_override >= 0 else _indice_camara
	_indice_camara = idx
	_camaras_limpas_contagem += 1

	if _vinculo != null and _vinculo.has_method("ao_camara_limpa"):
		_vinculo.call("ao_camara_limpa", idx, tipo_camara)

	var n_jog: int = camaras_jogaveis_da_regiao()
	var eh_ultima_regiao: bool = (_regiao_idx == _regioes.size() - 1)
	var eh_ultima_camara: bool = (idx == n_jog - 1) and (tipo_camara != &"santuario")

	if eh_ultima_regiao and eh_ultima_camara:
		# Vitória (R4 / R4-P):
		if tipo_camara == &"chefe" and _desfecho_chefe_registrado == ResumoDaRun.DESFECHO_NENHUM:
			_desfecho_chefe_registrado = ResumoDaRun.DESFECHO_ABATIDO
		_chefe_subjugado_pendente = false
		_eventos.emitir(EventosDaRun.EvFimDaRun.new(regiao(), idx))
		var coletados_antes: int = _conta.coletados_run() if _conta != null else 0
		var qtd_vit: int = _run_tuning.fragmentos_vitoria if _run_tuning != null else 15
		var bonus_efetivo: int = _conta.creditar(ContaFragmentos.VITORIA, qtd_vit) if (_conta != null and qtd_vit > 0) else 0
		_encerrar(ResumoDaRun.MOTIVO_VITORIA, coletados_antes, bonus_efetivo)
		_pedir_estado_orquestrador(EstadoDeJogo.Valor.MENU)
		return

	# Câmara intermediária (0..5 no Limiar, incluindo Santuário no 3 e Combate no 5):
	if _portas != null and _portas.has_method("ao_camara_limpa"):
		_portas.call("ao_camara_limpa", p, tipo_camara, idx, regiao(), _regiao_idx)


## Processa `jogador_morreu` (R5, R5-P, AC-RN-12, AC-RN-13, AC-RN-16, AC-RN-35).
func ao_jogador_morreu(recusou_morte: bool = false) -> bool:
	if _fase != Fase.ATIVA:
		return false
	if recusou_morte:
		return false
	_chefe_subjugado_pendente = false
	_desfecho_chefe_registrado = ResumoDaRun.DESFECHO_NENHUM
	var coletados: int = _conta.coletados_run() if _conta != null else 0
	_encerrar(ResumoDaRun.MOTIVO_MORTE, coletados, 0)
	_pedir_estado_orquestrador(EstadoDeJogo.Valor.MORTE)
	return true


## Regra da pausa (R6, AC-RN-15): pausa abre em JOGO e em BENCAO; recusada em TRANSICAO, MORTE e ENCERRADA.
func pedir_pausa() -> bool:
	if _fase != Fase.ATIVA:
		return false
	if _orquestrador != null and _orquestrador.has_method("estado"):
		var est: int = int(_orquestrador.call("estado"))
		if est != EstadoDeJogo.Valor.JOGO and est != EstadoDeJogo.Valor.BENCAO:
			return false
		return bool(_orquestrador.call("pedir_estado", EstadoDeJogo.Valor.PAUSA))
	return true


## Verdadeiro se "Abandonar run" está habilitado (R6, R4-P passo 4, ADR-0015 §3, AC-RN-15, AC-RN-34):
## Exige `fase == ATIVA`, não estar com `chefe_subjugado` pendente, e estar em JOGO ou PAUSA vinda de JOGO
## (nunca em BENCAO ou PAUSA vinda de BENCAO).
func abandono_permitido(estado_atual_override: int = -1, veio_de_bencao: bool = false) -> bool:
	if _fase != Fase.ATIVA or _chefe_subjugado_pendente or veio_de_bencao:
		return false
	var est: int = estado_atual_override
	if est < 0 and _orquestrador != null and _orquestrador.has_method("estado"):
		est = int(_orquestrador.call("estado"))
	if est == EstadoDeJogo.Valor.BENCAO or est == EstadoDeJogo.Valor.TRANSICAO or est == EstadoDeJogo.Valor.MORTE:
		return false
	return true


## Confirma ou cancela o abandono pelo menu de pausa (R6, AC-RN-14, AC-RN-15, AC-RN-34).
func abandonar(confirmado: bool = true, veio_de_bencao: bool = false) -> bool:
	if not confirmado:
		return false
	if not abandono_permitido(-1, veio_de_bencao):
		return false
	var coletados: int = _conta.coletados_run() if _conta != null else 0
	_encerrar(ResumoDaRun.MOTIVO_ABANDONO, coletados, 0)
	_pedir_estado_orquestrador(EstadoDeJogo.Valor.MENU)
	return true


## Encerra a run ativa como abandono ao sair do jogo (menu Sair ou fechar janela — R10, V20b, ADR-0015 §7).
func encerrar_por_saida() -> bool:
	if _fase != Fase.ATIVA:
		return false
	_chefe_subjugado_pendente = false
	_desfecho_chefe_registrado = ResumoDaRun.DESFECHO_NENHUM
	var coletados: int = _conta.coletados_run() if _conta != null else 0
	_encerrar(ResumoDaRun.MOTIVO_ABANDONO, coletados, 0)
	return true


## Nova run (R1, R8, R8-P, AC-RN-01, AC-RN-19, AC-RN-20, AC-RN-36):
## Só vale a partir de `ENCERRADA`. Descarta a seed e os fluxos do RNG, zera `coletados_run` da conta
## (preservando o `saldo` e o `PerfilVinculo`) e volta a `ESCOLHA_DE_ARMA`.
func nova_run() -> bool:
	if _fase != Fase.ENCERRADA:
		return false
	_fonte_fluxos.descartar_run()
	if _conta != null:
		_conta.nova_run()
	_seed_atual = 0
	_seed_texto = TextoDaSeed.TEXTO_SEM_SEED
	_chefe_subjugado_pendente = false
	_desfecho_chefe_registrado = ResumoDaRun.DESFECHO_NENHUM
	_fase = Fase.ESCOLHA_DE_ARMA
	_pedir_estado_orquestrador(EstadoDeJogo.Valor.MENU)
	return true


## Registra abates e passos manuais (para testes sem orquestrador acoplado).
func registrar_abate(qtd: int = 1) -> void:
	if _fase == Fase.ATIVA and qtd > 0:
		_abates_contagem += qtd


func avancar_passos_em_jogo(passos: int) -> void:
	if _fase == Fase.ATIVA and passos > 0:
		_passos_acumulados_manual += passos


# --- Interno -----------------------------------------------------------------

func _encerrar(motivo: StringName, coletados: int, bonus_vit: int) -> void:
	if _fase == Fase.ENCERRADA:
		return
	_fase = Fase.ENCERRADA
	_motivo_fim = motivo
	_fonte_fluxos.encerrar_run()

	var duracao_passos: int = _calcular_duracao_passos()
	var ids_bencaos: Array[StringName] = _obter_ids_bencaos_tomadas()
	var desfecho: StringName = _desfecho_chefe_registrado if motivo == ResumoDaRun.MOTIVO_VITORIA else ResumoDaRun.DESFECHO_NENHUM
	var dupla_resumo: Array[StringName] = _dupla_inicial if _doutrina_atual == DOUTRINA_PACTOS else ([] as Array[StringName])

	_resumo = ResumoDaRun.new(
		motivo, _seed_texto, _arma_escolhida, _camaras_limpas_contagem,
		ids_bencaos, coletados, bonus_vit, _abates_contagem,
		duracao_passos, desfecho, dupla_resumo
	)

	# ADR-0015 §7: consolida o Vínculo DIRETO antes de emitir EvRunEncerrada
	if _vinculo != null and _vinculo.has_method("consolidar_run"):
		_vinculo.call("consolidar_run", motivo, motivo == ResumoDaRun.MOTIVO_VITORIA)

	_eventos.emitir(EventosDaRun.EvRunEncerrada.new(motivo, _resumo))
	_tela_final_aberta_vezes += 1
	if _ao_abrir_tela_final_cb.is_valid():
		_ao_abrir_tela_final_cb.call(_resumo)


func _calcular_duracao_passos() -> int:
	var do_orq: int = _ler_passos_orquestrador() - _passos_inicio_run
	return maxi(0, do_orq + _passos_acumulados_manual)


func _ler_passos_orquestrador() -> int:
	if _orquestrador != null and _orquestrador.has_method("passos_em_jogo"):
		return int(_orquestrador.call("passos_em_jogo"))
	return 0


func _obter_ids_bencaos_tomadas() -> Array[StringName]:
	var r: Array[StringName] = []
	if _bencaos != null and _bencaos.has_method("tomadas"):
		var lista: Variant = _bencaos.call("tomadas")
		if lista is Array:
			for item in lista:
				if item is StringName:
					r.append(item)
				elif item is Dictionary and (item as Dictionary).has("id"):
					r.append(StringName(item["id"]))
	return r


func _gerar_seed(texto_debug: String = "") -> int:
	if _criador_seed != null:
		var res: CriadorDeSeed.ResultadoDaSeed = _criador_seed.criar_seed(texto_debug)
		if res.criada:
			return res.seed
		# AC-RN-04: no GDD de Run e regiões, `--seed=XYZ` inválida cai na seed do provedor de entropia!
		if _criador_seed._entropia != null:
			return RngAritmetica.mascarar_u32(_criador_seed._entropia.sortear_u32())
	return 0x3F9A07C2


func _vida_base_por_arma(id_arma: StringName) -> int:
	match id_arma:
		DOUTRINA_RESSONANCIA:
			return 80
		DOUTRINA_PACTOS:
			return 90
		_:
			return 100


func _regiao_atual_def() -> RegionDef:
	return _regiao_def(_regiao_idx)


func _regiao_def(idx: int) -> RegionDef:
	if idx >= 0 and idx < _regioes.size():
		return _regioes[idx]
	return null


func _pode_transicionar(destino: Fase) -> bool:
	var lista: Array = TRANSICOES.get(_fase, [])
	return lista.has(destino)


func _pedir_estado_orquestrador(alvo: EstadoDeJogo.Valor) -> void:
	if _orquestrador != null and _orquestrador.has_method("pedir_estado"):
		_orquestrador.call("pedir_estado", alvo)
