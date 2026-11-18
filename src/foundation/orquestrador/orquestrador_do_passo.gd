## Orquestrador do passo e dos estados de jogo (ADR-0001, ADR-0002). Lógica pura:
## [RefCounted], sem [code]SceneTree[/code], sem [code]Autoload[/code], sem ler [code]Time[/code]/[code]OS[/code].
## O tempo entra como contagem de passos ([method passo_fisico]) e como [code]delta_real[/code]
## ([method quadro]). Tudo é injetado pelo [code]Main[/code].
##
## Responsabilidades:
## [br]- estado de jogo próprio ([EstadoDeJogo]) e pedidos de estado ([method pedir_estado],
## [method retomar]); dentro do passo o pedido fica pendente e vale no final comum; [code]MORTE[/code] vence;
## [br]- ordem fixa do passo vivo ([OrdemDoPasso]); hitstop consultado no Combate ([ControleDeHitstop]);
## fora de [code]JOGO[/code] só [code]passo_congelado()[/code] do Movimento;
## [br]- final comum de todo passo ([code]_finalizar_passo[/code]): contadores, uma entrega de eventos, pedido;
## [br]- relógios [method t_vivo] e [method t_apres], entregues ao Pipeline todo quadro, e as seis
## ações da troca de câmara na metade do wipe.
##
## Exemplo (composição no [code]Main[/code], depois [code]_physics_process[/code] → [method passo_fisico] e
## [code]_process(delta)[/code] → [method quadro]):
## [codeblock]
## var eventos := EventosDoPasso.new()
## var orq := OrquestradorDoPasso.new(eventos, [telemetria, hud, feedback, telas, audio])
## orq.configurar_passo(fonte_de_amostra, hitstop_do_combate, modulos_por_chave)
## orq.configurar_quadro(pipeline, acoes_da_troca, visual_tuning.dt_max_apres)
## orq.pedir_estado(EstadoDeJogo.Valor.MENU)
## [/codeblock]
## Não é seguro entre threads: só a thread principal o usa.
class_name OrquestradorDoPasso
extends RefCounted

## Passos de simulação por segundo: **constante única** do passo de 1/60 s. O [code]Main[/code]
## a valida contra [code]Engine.physics_ticks_per_second[/code] em [code]_ready()[/code].
const PASSOS_POR_SEGUNDO: int = 60

## Quantidade de ações da troca de câmara (Combate R1, Transição).
const QTD_ACOES_DA_TROCA: int = 6

## Progresso do wipe a partir do qual a troca de câmara acontece (metade, tela coberta).
const PROGRESSO_DA_TROCA: float = 0.5

## Progresso do wipe que encerra a Transição (descobriu a tela).
const PROGRESSO_FIM_DO_WIPE: float = 1.0

## Erro de composição: módulo do passo ausente (formato: chave).
const ERRO_MODULO_AUSENTE: String = "OrquestradorDoPasso: módulo do passo ausente: %s"
## Erro de composição: passo físico antes de [method configurar_passo].
const ERRO_SEM_PASSO: String = "OrquestradorDoPasso: passo_fisico() sem configurar_passo()"
## Erro de composição: quantidade de ações da troca (formato: recebidas, esperadas).
const ERRO_ACOES: String = "OrquestradorDoPasso: %d ações da troca (esperadas %d)"
## Erro de composição: dt_max_apres inválido (formato: valor).
const ERRO_DT_MAX: String = "OrquestradorDoPasso: dt_max_apres inválido: %f"

## Sem pedido pendente.
const _SEM_PEDIDO: int = -1

var _eventos: EventosDoPasso
var _consumidores: Array[ConsumidorDeEventos] = []

var _fonte: FonteDeAmostra = null
var _hitstop: ControleDeHitstop = null
var _movimento: Passo = null
var _modulos_vivos: Array[Passo] = []
var _passo_configurado: bool = false

var _pipeline: PipelineDeRelogios = null
var _acoes_da_troca: Array[AcaoDeTroca] = []
var _dt_max_apres: float = 0.0
var _quadro_configurado: bool = false

var _estado: EstadoDeJogo.Valor = EstadoDeJogo.Valor.INICIANDO
var _estado_antes_da_pausa: EstadoDeJogo.Valor = EstadoDeJogo.Valor.JOGO
var _estado_no_inicio: EstadoDeJogo.Valor = EstadoDeJogo.Valor.INICIANDO
var _no_passo: bool = false
var _pendente: int = _SEM_PEDIDO
var _pendente_e_retomada: bool = false

var _n_vivos: int = 0
var _n_passos_em_jogo: int = 0
var _t_apres: float = 0.0
var _troca_feita: bool = false


## [param eventos]: canal do passo (ADR-0002), compartilhado com os módulos.
## [param consumidores]: Apresentação na ordem fixa (Telemetria, HUD, Feedback, Telas, Áudio).
func _init(eventos: EventosDoPasso, consumidores: Array[ConsumidorDeEventos] = []) -> void:
	_eventos = eventos
	_consumidores.append_array(consumidores)


# --- Composição ----------------------------------------------------------------

## Injeta o item 1, o hitstop do Combate e os módulos [Passo] por chave de [method OrdemDoPasso.modulos].
## Todo módulo é obrigatório (um módulo sem conteúdo é um [Passo] que não faz nada, nunca
## [code]null[/code]). Devolve as chaves ausentes; vazio = configurado. Com ausências,
## sai um [code]push_error[/code] por chave e o orquestrador continua sem passo configurado.
func configurar_passo(fonte: FonteDeAmostra, hitstop: ControleDeHitstop,
		modulos: Dictionary[StringName, Passo]) -> PackedStringArray:
	var ausentes := PackedStringArray()
	if fonte == null:
		ausentes.append(OrdemDoPasso.INPUT)
	if hitstop == null:
		ausentes.append("hitstop")
	var lista: Array[Passo] = []
	for chave: StringName in OrdemDoPasso.modulos():
		var m: Passo = modulos.get(chave, null)
		if m == null:
			ausentes.append(chave)
		else:
			lista.append(m)
	if not ausentes.is_empty():
		for chave: String in ausentes:
			push_error(ERRO_MODULO_AUSENTE % chave)
		return ausentes
	_fonte = fonte
	_hitstop = hitstop
	_movimento = modulos[OrdemDoPasso.MOVIMENTO]
	_modulos_vivos = lista
	_passo_configurado = true
	return ausentes


## Injeta o Pipeline (relógios e progresso do wipe), as seis ações da troca em ordem e
## [param dt_max_apres] (dado: [code]VisualTuning[/code], Pipeline F8; 0,1 s no MVP).
## Devolve [code]false[/code] (e não configura) se faltar algo ou o valor for inválido.
func configurar_quadro(pipeline: PipelineDeRelogios, acoes: Array[AcaoDeTroca],
		dt_max_apres: float) -> bool:
	if pipeline == null or acoes.size() != QTD_ACOES_DA_TROCA or acoes.has(null):
		push_error(ERRO_ACOES % [acoes.size(), QTD_ACOES_DA_TROCA])
		return false
	if dt_max_apres <= 0.0:
		push_error(ERRO_DT_MAX % dt_max_apres)
		return false
	_pipeline = pipeline
	_acoes_da_troca.clear()
	_acoes_da_troca.append_array(acoes)
	_dt_max_apres = dt_max_apres
	_quadro_configurado = true
	return true


# --- Ganchos da engine (repassados pelo Main) -------------------------------------

## Um passo de simulação (1 vez por [code]_physics_process[/code]). Em [code]JOGO[/code]: item 1,
## item 2 (hitstop?) e, se vivo, itens 3–10 na ordem de [OrdemDoPasso]; congelado: Combate
## desconta 1 e Movimento [code]passo_congelado()[/code]. Fora de [code]JOGO[/code]: item 1 e
## Movimento [code]passo_congelado()[/code]. Sempre termina no final comum.
func passo_fisico() -> void:
	if not _passo_configurado:
		push_error(ERRO_SEM_PASSO)
		return
	_no_passo = true
	_estado_no_inicio = _estado
	var vivo: bool = false
	var amostra: AmostraDeEntrada = _fonte.amostrar()
	if _estado_no_inicio == EstadoDeJogo.Valor.JOGO:
		# Item 1: passo_vivo conta passos em JOGO, inclusive hitstop (TR-telemetria-003).
		_eventos.emitir(EvPassoVivo.new(_n_passos_em_jogo))
		if _hitstop.hitstop_ativo():
			_hitstop.passo_congelado_do_combate()
			_movimento.passo_congelado()
		else:
			for m: Passo in _modulos_vivos:
				m.passo(amostra)
			vivo = true
	else:
		_movimento.passo_congelado()
	_finalizar_passo(vivo)
	_no_passo = false


## Um quadro de render (1 vez por [code]_process[/code]); não executa passos nem supõe
## "um passo por quadro". Avança [method t_apres] em [code]JOGO[/code]/[code]TRANSICAO[/code]/[code]MORTE[/code]
## por [code]min(delta_real, dt_max_apres)[/code]; na Transição executa a troca de câmara uma vez na
## metade do wipe e pede [code]JOGO[/code] no fim; entrega os relógios ao Pipeline.
func quadro(delta_real: float) -> void:
	if not _quadro_configurado:
		return
	if _relogio_de_apresentacao_corre(_estado):
		_t_apres += minf(maxf(delta_real, 0.0), _dt_max_apres)
	if _estado == EstadoDeJogo.Valor.TRANSICAO:
		var progresso: float = _pipeline.progresso_wipe()
		if not _troca_feita and progresso >= PROGRESSO_DA_TROCA:
			_trocar_camara()
		if _troca_feita and progresso >= PROGRESSO_FIM_DO_WIPE:
			pedir_estado(EstadoDeJogo.Valor.JOGO)
	_pipeline.receber_relogios(t_vivo(), _t_apres)


# --- Consultas -------------------------------------------------------------------

## Estado de jogo corrente (um pedido pendente ainda não conta).
func estado() -> EstadoDeJogo.Valor:
	return _estado


## Tempo vivo em segundos: [code]n_vivos / 60.0[/code] (contador inteiro); parado no hitstop
## e fora de [code]JOGO[/code]; zera na troca de câmara.
func t_vivo() -> float:
	return _n_vivos / float(PASSOS_POR_SEGUNDO)


## Passos vivos desde a última troca de câmara.
func n_vivos() -> int:
	return _n_vivos


## Tempo de apresentação em segundos (tempo real com teto por quadro); zera na troca de câmara.
func t_apres() -> float:
	return _t_apres


## Passos iniciados em [code]JOGO[/code], inclusive hitstop; monotônico na run (Run F3, Telemetria F1).
## Consumidores guardam o valor no início do que medem e usam a diferença.
func passos_em_jogo() -> int:
	return _n_passos_em_jogo


## Hitstop ativo, consulta delegada ao Combate ([code]false[/code] sem composição).
func hitstop_ativo() -> bool:
	return _hitstop != null and _hitstop.hitstop_ativo()


## [code]true[/code] entre o início de [method passo_fisico] e o fim do final comum.
func dentro_do_passo() -> bool:
	return _no_passo


## Duração em segundos de [param passos] passos (ex.: diferença de [method passos_em_jogo]).
## AC-TL-06: [code]duracao_s(1044) == 17.4[/code].
static func duracao_s(passos: int) -> float:
	return passos / float(PASSOS_POR_SEGUNDO)


## [code]true[/code] se a tabela de pedidos do ADR-0001 permite ir de [param de] para [param para]
## por [method pedir_estado]. A volta da pausa é só por [method retomar].
static func transicao_permitida(de: EstadoDeJogo.Valor, para: EstadoDeJogo.Valor) -> bool:
	match para:
		EstadoDeJogo.Valor.MORTE, EstadoDeJogo.Valor.BENCAO:
			return de == EstadoDeJogo.Valor.JOGO
		EstadoDeJogo.Valor.TRANSICAO:
			return de == EstadoDeJogo.Valor.JOGO or de == EstadoDeJogo.Valor.MENU
		EstadoDeJogo.Valor.MENU:
			return de in [EstadoDeJogo.Valor.INICIANDO, EstadoDeJogo.Valor.JOGO,
					EstadoDeJogo.Valor.PAUSA, EstadoDeJogo.Valor.MORTE]
		EstadoDeJogo.Valor.JOGO:
			return de == EstadoDeJogo.Valor.BENCAO or de == EstadoDeJogo.Valor.TRANSICAO
		EstadoDeJogo.Valor.PAUSA:
			return de == EstadoDeJogo.Valor.JOGO or de == EstadoDeJogo.Valor.BENCAO
	return false


# --- Pedidos de estado -------------------------------------------------------------

## Pede a troca para [param novo]. Devolve [code]false[/code] se a transição não é permitida a
## partir do estado corrente ou se perde para um pedido pendente. Fora do passo (UI, foco)
## vale na hora; dentro do passo fica pendente até o final comum. Com dois pedidos no mesmo
## passo, [code]MORTE[/code] vence qualquer outro; entre dois que não são [code]MORTE[/code], o
## primeiro fica (o item anterior decide) e o segundo devolve [code]false[/code].
func pedir_estado(novo: EstadoDeJogo.Valor) -> bool:
	if not transicao_permitida(_estado, novo):
		return false
	if not _no_passo:
		_aplicar(novo)
		return true
	return _registrar_pendente(novo, false)


## Sai de [code]PAUSA[/code] para o estado de antes ([code]JOGO[/code] ou [code]BENCAO[/code]).
## [code]false[/code] fora de [code]PAUSA[/code]. Dentro do passo, fica pendente como um pedido.
func retomar() -> bool:
	if _estado != EstadoDeJogo.Valor.PAUSA:
		return false
	if not _no_passo:
		_aplicar(_estado_antes_da_pausa)
		return true
	return _registrar_pendente(_estado_antes_da_pausa, true)


## [code]true[/code] se há pedido de estado pendente no passo corrente.
func ha_pedido_pendente() -> bool:
	return _pendente != _SEM_PEDIDO


# --- Interno ---------------------------------------------------------------------

func _registrar_pendente(novo: EstadoDeJogo.Valor, retomada: bool) -> bool:
	if _pendente == _SEM_PEDIDO or (novo == EstadoDeJogo.Valor.MORTE and _pendente != EstadoDeJogo.Valor.MORTE):
		_pendente = novo
		_pendente_e_retomada = retomada
		return true
	return false


## Final comum de todo passo físico (ADR-0001, decisão 5), nesta ordem.
func _finalizar_passo(vivo: bool) -> void:
	# 1. passos vivos (t_vivo deriva do contador inteiro)
	if vivo:
		_n_vivos += 1
	# 2. passos iniciados em JOGO, inclusive hitstop
	if _estado_no_inicio == EstadoDeJogo.Valor.JOGO:
		_n_passos_em_jogo += 1
	# 3. uma entrega por passo, mesmo vazia
	_eventos.entregar(_eventos.esvaziar(), _consumidores)
	# 4. pedido pendente (MORTE já venceu no registro)
	if _pendente != _SEM_PEDIDO:
		var alvo: EstadoDeJogo.Valor = _pendente as EstadoDeJogo.Valor
		var retomada: bool = _pendente_e_retomada
		_pendente = _SEM_PEDIDO
		_pendente_e_retomada = false
		if retomada or transicao_permitida(_estado, alvo):
			_aplicar(alvo)


func _aplicar(novo: EstadoDeJogo.Valor) -> void:
	if novo == EstadoDeJogo.Valor.PAUSA:
		_estado_antes_da_pausa = _estado
	if novo == EstadoDeJogo.Valor.TRANSICAO:
		_troca_feita = false
	_estado = novo


func _relogio_de_apresentacao_corre(e: EstadoDeJogo.Valor) -> bool:
	return e == EstadoDeJogo.Valor.JOGO or e == EstadoDeJogo.Valor.TRANSICAO \
			or e == EstadoDeJogo.Valor.MORTE


## Troca de câmara na metade do wipe: relógios a zero (Pipeline R8; não no pedido de
## TRANSICAO) e as seis ações em ordem, uma única vez. passos_em_jogo() não zera.
func _trocar_camara() -> void:
	_troca_feita = true
	_n_vivos = 0
	_t_apres = 0.0
	for acao: AcaoDeTroca in _acoes_da_troca:
		acao.executar()
