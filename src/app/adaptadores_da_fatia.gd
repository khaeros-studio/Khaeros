## Adaptadores que ligam a fatia jogável de 2026-11-14 ao [OrquestradorDoPasso]
## (story orquestrador-007; ADR-0001 §Migration Plan, ADR-0002 §Migration Plan, ADR-0003).
## Só composição: nenhuma regra nova mora aqui. [code]GameSession.step()[/code] continua sendo a
## regra da fatia e passa a ser chamado **pelo orquestrador** em exatamente um ponto por passo:
## [br]- passo vivo: módulo [code]combate_inicio[/code] ([PassoDaFatia]);
## [br]- passo congelado por hitstop: [method HitstopDaFatia.passo_congelado_do_combate] (o
## [code]step()[/code] desconta o hitstop, ADR-0001 decisão 4);
## [br]- fora de [code]JOGO[/code]: [method MovimentoDaFatia.passo_congelado].
## Os demais módulos de [OrdemDoPasso] são [PassoVazio] até os épicos donos extraírem cada item.
##
## Exemplo (no [code]Main[/code]):
## [codeblock]
## var ctx := AdaptadoresDaFatia.Contexto.new(session, eventos, _amostrar, controls.consume)
## orq.configurar_passo(AdaptadoresDaFatia.Fonte.new(ctx), AdaptadoresDaFatia.HitstopDaFatia.new(ctx),
##         AdaptadoresDaFatia.modulos(ctx))
## [/codeblock]
## Não é seguro entre threads.
class_name AdaptadoresDaFatia
extends RefCounted


## Estado compartilhado pelos adaptadores num passo: a sessão, o canal e a amostra do item 1.
class Contexto extends RefCounted:
	## Regra da fatia ([code]src/gameplay/game_session.gd[/code]).
	var session: RefCounted
	## Canal do passo (ADR-0002).
	var eventos: EventosDoPasso
	## Amostra da fatia (dicionário do [code]game_input.gd[/code]) colhida no item 1 deste passo.
	var amostra: Dictionary = {}
	## [code]func() -> Dictionary[/code]: amostra o Input legado (chamado uma vez por passo).
	var amostrar: Callable
	## [code]func(acao: String) -> void[/code]: consome um comando do buffer do Input.
	var consumir: Callable

	func _init(p_session: RefCounted, p_eventos: EventosDoPasso, p_amostrar: Callable,
			p_consumir: Callable) -> void:
		session = p_session
		eventos = p_eventos
		amostrar = p_amostrar
		consumir = p_consumir


## Item 1: amostra o Input legado e devolve a [AmostraDeEntrada] tipada equivalente.
class Fonte extends FonteDeAmostra:
	var _ctx: Contexto

	func _init(ctx: Contexto) -> void:
		_ctx = ctx

	## Amostra uma vez por passo, em todo estado (ADR-0001 item 1).
	func amostrar() -> AmostraDeEntrada:
		_ctx.amostra = _ctx.amostrar.call()
		var segurados: Array[StringName] = []
		var apertados: Array[StringName] = []
		for chave: Variant in _ctx.amostra.get("held", {}).keys():
			if _ctx.amostra.held[chave]:
				segurados.append(StringName(str(chave)))
		for chave: Variant in _ctx.amostra.get("pressed", {}).keys():
			if _ctx.amostra.pressed[chave]:
				apertados.append(StringName(str(chave)))
		return AmostraDeEntrada.new(segurados, apertados)


## Hitstop local da fatia ([code]hitstop[/code]/[code]_pending_hitstop[/code] de [code]GameSession[/code])
## exposto pelo contrato do Combate (ADR-0001 decisão 4, ADR-0010).
class HitstopDaFatia extends ControleDeHitstop:
	var _ctx: Contexto

	func _init(ctx: Contexto) -> void:
		_ctx = ctx

	## [code]true[/code] com contador de hitstop positivo e sessão em jogo.
	func hitstop_ativo() -> bool:
		return _ctx.session.state == "jogo" and int(_ctx.session.hitstop) > 0

	## O [code]step()[/code] da fatia desconta 1 e congela as posições.
	func passo_congelado_do_combate() -> void:
		_ctx.session.step(_ctx.amostra)


## Módulo [code]combate_inicio[/code]: roda o [code]step()[/code] inteiro da fatia num passo vivo e
## emite os eventos tipados ([EventosDaFatia]).
class PassoDaFatia extends Passo:
	var _ctx: Contexto

	func _init(ctx: Contexto) -> void:
		_ctx = ctx

	## Passo vivo. Se o item 1 pausou a sessão neste passo, o [code]step()[/code] só congela.
	func passo(_amostra: AmostraDeEntrada) -> void:
		var s: RefCounted = _ctx.session
		if s.state != "jogo" or s.player.is_empty():
			s.step(_ctx.amostra)
			return
		var hp_antes: float = s.player.hp
		var inimigos_antes: float = AdaptadoresDaFatia.vida_dos_inimigos(s.enemies)
		var executados: Array[String] = s.step(_ctx.amostra)
		for acao: String in executados:
			_ctx.eventos.emitir(EventosDaFatia.EvComandoExecutado.new(StringName(acao)))
			_ctx.consumir.call(acao)
		var mira: Vector2 = _ctx.amostra.get("aim", Vector2.ZERO)
		if s.player.hp < hp_antes:
			_ctx.eventos.emitir(EventosDaFatia.EvGolpeSentido.new(true, mira))
		elif AdaptadoresDaFatia.vida_dos_inimigos(s.enemies) < inimigos_antes:
			_ctx.eventos.emitir(EventosDaFatia.EvGolpeSentido.new(false, mira))


## Módulo [code]movimento[/code]: o movimento ainda está dentro de [PassoDaFatia]; aqui só o
## [code]passo_congelado()[/code] fora de [code]JOGO[/code] (Movimento R2). No hitstop o congelamento
## já foi feito por [HitstopDaFatia], então não repete.
class MovimentoDaFatia extends Passo:
	var _ctx: Contexto

	func _init(ctx: Contexto) -> void:
		_ctx = ctx

	## Sem efeito: o movimento vivo ainda roda dentro do [code]step()[/code] da fatia.
	func passo(_amostra: AmostraDeEntrada) -> void:
		pass

	## Congela posições fora de [code]JOGO[/code] (prev = pos).
	func passo_congelado() -> void:
		if _ctx.session.state != "jogo":
			_ctx.session.step(_ctx.amostra)


## Módulo sem conteúdo (item ainda não extraído do [code]step()[/code] da fatia).
class PassoVazio extends Passo:
	## Sem efeito.
	func passo(_amostra: AmostraDeEntrada) -> void:
		pass


## Consumidor sem efeito, com nome para a ordem fixa (Telemetria, HUD, Feedback, Telas, Áudio).
class ConsumidorNulo extends ConsumidorDeEventos:
	## Nome do consumidor na ordem do ADR-0002/0016.
	var nome: StringName

	func _init(p_nome: StringName) -> void:
		nome = p_nome

	## Sem efeito.
	func consumir(_eventos: Array[EventoDoPasso]) -> void:
		pass


## Feedback da fatia: traduz [EventosDaFatia.EvGolpeSentido] em impulso na câmera da fatia.
class FeedbackDaFatia extends ConsumidorNulo:
	## Força do impulso quando o jogador é ferido / quando fere (valores herdados da fatia;
	## migram para o FeedbackTuning no épico feedback-de-combate).
	const FORCA_FERIDO: float = 1.0
	const FORCA_ACERTO: float = 0.5
	var _camera: Object

	func _init(camera: Object) -> void:
		super(&"feedback")
		_camera = camera

	## Lê só os eventos de golpe; a câmera da fatia aplica o impulso.
	func consumir(eventos: Array[EventoDoPasso]) -> void:
		for ev: EventoDoPasso in eventos:
			if ev is EventosDaFatia.EvGolpeSentido:
				var g := ev as EventosDaFatia.EvGolpeSentido
				if g.jogador_ferido:
					_camera.impulse(-g.direcao, FORCA_FERIDO)
				else:
					_camera.impulse(g.direcao, FORCA_ACERTO)


## Pipeline da fatia: recebe os relógios e expõe o progresso do wipe da sessão.
class PipelineDaFatia extends PipelineDeRelogios:
	## Últimos relógios recebidos.
	var t_vivo: float = 0.0
	var t_apres: float = 0.0
	var _ctx: Contexto

	func _init(ctx: Contexto) -> void:
		_ctx = ctx

	## Guarda os relógios do quadro.
	func receber_relogios(p_t_vivo: float, p_t_apres: float) -> void:
		t_vivo = p_t_vivo
		t_apres = p_t_apres

	## Progresso do wipe da fatia ([code]transition_progress[/code]).
	func progresso_wipe() -> float:
		return float(_ctx.session.transition_progress)


## Ação da troca sem efeito: na fatia a troca de câmara ainda é feita por
## [code]GameSession.advance_presentation()[/code].
class AcaoNula extends AcaoDeTroca:
	## Sem efeito.
	func executar() -> void:
		pass


## Relator de erros do RNG do ponto de composição: avisa no log e conta os registros
## (RNG story 006). A gravação em telemetria/relatório é do épico telemetria-local.
class RelatorRngPorAviso extends RelatorDeErrosRng:
	## Quantidade de registros recebidos na sessão.
	var registros: int = 0

	## Operação inválida (não consome o fluxo).
	func registrar_operacao_invalida(operacao: StringName, motivo: String) -> void:
		registros += 1
		push_warning("RNG: operação %s recusada: %s" % [operacao, motivo])

	## Pedido de fluxo recusado.
	func registrar_pedido_recusado(finalidade: int, regiao: int, profundidade: int,
			solicitante: StringName, motivo: String) -> void:
		registros += 1
		push_warning("RNG: fluxo (%d, %d, %d) recusado para %s: %s" % [finalidade, regiao,
				profundidade, solicitante, motivo])

	## Aviso genérico.
	func registrar_aviso(mensagem: String) -> void:
		registros += 1
		push_warning("RNG: %s" % mensagem)


## Mapa chave de [OrdemDoPasso] → módulo da fatia.
static func modulos(ctx: Contexto) -> Dictionary[StringName, Passo]:
	var r: Dictionary[StringName, Passo] = {}
	for chave: StringName in OrdemDoPasso.modulos():
		r[chave] = PassoVazio.new()
	r[OrdemDoPasso.COMBATE_INICIO] = PassoDaFatia.new(ctx)
	r[OrdemDoPasso.MOVIMENTO] = MovimentoDaFatia.new(ctx)
	return r


## Seis ações nulas da troca.
static func acoes_da_troca() -> Array[AcaoDeTroca]:
	var r: Array[AcaoDeTroca] = []
	for i: int in OrquestradorDoPasso.QTD_ACOES_DA_TROCA:
		r.append(AcaoNula.new())
	return r


## Soma da vida positiva dos inimigos da fatia.
static func vida_dos_inimigos(inimigos: Array) -> float:
	var total := 0.0
	for e: Dictionary in inimigos:
		total += maxf(0.0, e.hp)
	return total


## Estado do orquestrador que espelha o texto de estado da fatia ([code]vitoria[/code] → MENU,
## ADR-0001 §6: "MENU←JOGO (vitória)").
static func estado_de(texto: String) -> EstadoDeJogo.Valor:
	match texto:
		"menu", "vitoria", "oficina": return EstadoDeJogo.Valor.MENU
		"jogo": return EstadoDeJogo.Valor.JOGO
		"pausa": return EstadoDeJogo.Valor.PAUSA
		"bencao": return EstadoDeJogo.Valor.BENCAO
		"transicao": return EstadoDeJogo.Valor.TRANSICAO
		"morte": return EstadoDeJogo.Valor.MORTE
	return EstadoDeJogo.Valor.INICIANDO


## Leva [param orq] até [param alvo] só por pedidos permitidos pela tabela do ADR-0001
## (busca em largura sobre [method OrquestradorDoPasso.transicao_permitida]; saída de PAUSA por
## [method OrquestradorDoPasso.retomar]). Chamado fora do passo, então cada pedido vale na hora.
## Devolve [code]true[/code] se chegou. Fachada transitória: enquanto a fatia for dona do estado,
## o orquestrador o espelha (story 007).
static func espelhar(orq: OrquestradorDoPasso, alvo: EstadoDeJogo.Valor) -> bool:
	for _i: int in EstadoDeJogo.Valor.size():
		var atual: EstadoDeJogo.Valor = orq.estado()
		if atual == alvo:
			return true
		if atual == EstadoDeJogo.Valor.PAUSA and alvo != EstadoDeJogo.Valor.MENU:
			orq.retomar()
			continue
		var proximo: int = _primeiro_passo(atual, alvo)
		if proximo < 0 or not orq.pedir_estado(proximo as EstadoDeJogo.Valor):
			return false
	return orq.estado() == alvo


static func _primeiro_passo(de: EstadoDeJogo.Valor, para: EstadoDeJogo.Valor) -> int:
	var origem: Dictionary = {de: -1}
	var fila: Array[int] = [de]
	while not fila.is_empty():
		var v: int = fila.pop_front()
		if v == para:
			var passo: int = v
			while origem[passo] != de and origem[passo] != -1:
				passo = origem[passo]
			return passo
		for w: int in EstadoDeJogo.Valor.values():
			if not origem.has(w) and OrquestradorDoPasso.transicao_permitida(v as EstadoDeJogo.Valor,
					w as EstadoDeJogo.Valor):
				origem[w] = v
				fila.append(w)
	return -1
