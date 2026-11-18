## Dublês dos testes do orquestrador (stories orquestrador-do-passo/003–005).
## Não é suíte: as suítes fazem [code]preload[/code] deste arquivo. Lógica pura, sem I/O.
extends RefCounted


## Item 1 falso: registra "input" no diário e devolve uma amostra nova.
class FonteFalsa extends FonteDeAmostra:
	var diario: Array[StringName]
	var chamadas: int = 0

	func _init(p_diario: Array[StringName]) -> void:
		diario = p_diario

	func amostrar() -> AmostraDeEntrada:
		chamadas += 1
		diario.append(OrdemDoPasso.INPUT)
		return AmostraDeEntrada.new()


## Combate falso no item 2: um pedido de hitstop vira ativo só na consulta do passo seguinte.
class HitstopFalso extends ControleDeHitstop:
	const DESCONTO: StringName = &"combate_desconta"
	var diario: Array[StringName]
	var restante: int = 0
	var pedido: int = 0
	var consultas: int = 0

	func _init(p_diario: Array[StringName]) -> void:
		diario = p_diario

	## Pedido feito durante o passo (como a forma do golpe faria).
	func pedir(passos: int) -> void:
		pedido = maxi(pedido, passos)

	func hitstop_ativo() -> bool:
		consultas += 1
		if pedido > 0:
			restante = maxi(restante, pedido)
			pedido = 0
		return restante > 0

	func passo_congelado_do_combate() -> void:
		diario.append(DESCONTO)
		restante -= 1


## Módulo do passo falso: registra a própria chave (ou chave:congelado) e roda uma ação opcional.
class PassoFalso extends Passo:
	const SUFIXO_CONGELADO: String = ":congelado"
	var nome: StringName
	var diario: Array[StringName]
	var acao: Callable = Callable()
	var amostras: Array[AmostraDeEntrada] = []

	func _init(p_nome: StringName, p_diario: Array[StringName]) -> void:
		nome = p_nome
		diario = p_diario

	func passo(amostra: AmostraDeEntrada) -> void:
		diario.append(nome)
		amostras.append(amostra)
		if acao.is_valid():
			acao.call()

	func passo_congelado() -> void:
		diario.append(StringName(String(nome) + SUFIXO_CONGELADO))


## Consumidor da Apresentação falso: guarda, por entrega, os tipos recebidos (cópia).
class ConsumidorFalso extends ConsumidorDeEventos:
	var entregas: Array[Array] = []

	func consumir(eventos: Array[EventoDoPasso]) -> void:
		var tipos: Array[StringName] = []
		for e: EventoDoPasso in eventos:
			tipos.append(e.tipo())
		entregas.append(tipos)


## Evento de UI de teste (ex.: clique na Tela de bênção).
class EvUiTeste extends EventoDoPasso:
	const TIPO: StringName = &"ui_teste"

	func tipo() -> StringName:
		return TIPO


## Evento de combate de teste emitido dentro de um item.
class EvGolpeTeste extends EventoDoPasso:
	const TIPO: StringName = &"golpe_teste"

	func tipo() -> StringName:
		return TIPO


## Pipeline falso: progresso do wipe ajustável; registra os relógios recebidos.
class PipelineFalso extends PipelineDeRelogios:
	var progresso: float = 0.0
	var recebidos: Array[Vector2] = []

	func receber_relogios(t_vivo: float, t_apres: float) -> void:
		recebidos.append(Vector2(t_vivo, t_apres))

	func progresso_wipe() -> float:
		return progresso


## Ação da troca falsa: registra o nome no diário.
class AcaoFalsa extends AcaoDeTroca:
	var nome: StringName
	var diario: Array[StringName]

	func _init(p_nome: StringName, p_diario: Array[StringName]) -> void:
		nome = p_nome
		diario = p_diario

	func executar() -> void:
		diario.append(nome)


## Orquestrador montado com todos os dublês.
class Montagem extends RefCounted:
	var nomes_acoes: Array[StringName] = [
		&"combate_camara_nova", &"teleporte", &"montar_camara", &"vfx_relogios", &"corte_camera", &"pipeline_lut",
	]
	var diario: Array[StringName] = []
	var diario_acoes: Array[StringName] = []
	var eventos := EventosDoPasso.new()
	var consumidor := ConsumidorFalso.new()
	var fonte: FonteFalsa
	var hitstop: HitstopFalso
	var modulos: Dictionary[StringName, Passo] = {}
	var pipeline := PipelineFalso.new()
	var acoes: Array[AcaoDeTroca] = []
	var orq: OrquestradorDoPasso

	func _init(dt_max_apres: float) -> void:
		fonte = FonteFalsa.new(diario)
		hitstop = HitstopFalso.new(diario)
		for chave: StringName in OrdemDoPasso.modulos():
			modulos[chave] = PassoFalso.new(chave, diario)
		for nome: StringName in nomes_acoes:
			acoes.append(AcaoFalsa.new(nome, diario_acoes))
		var consumidores: Array[ConsumidorDeEventos] = [consumidor]
		orq = OrquestradorDoPasso.new(eventos, consumidores)
		orq.configurar_passo(fonte, hitstop, modulos)
		orq.configurar_quadro(pipeline, acoes, dt_max_apres)

	## Módulo falso da [param chave].
	func modulo(chave: StringName) -> PassoFalso:
		return modulos[chave] as PassoFalso

	## Leva o orquestrador a [param alvo] por pedidos permitidos, fora do passo.
	func levar_a(alvo: EstadoDeJogo.Valor) -> void:
		orq.pedir_estado(EstadoDeJogo.Valor.MENU)
		if alvo == EstadoDeJogo.Valor.MENU:
			return
		orq.pedir_estado(EstadoDeJogo.Valor.TRANSICAO)
		if alvo == EstadoDeJogo.Valor.TRANSICAO:
			return
		orq.pedir_estado(EstadoDeJogo.Valor.JOGO)
		if alvo == EstadoDeJogo.Valor.JOGO:
			return
		if alvo == EstadoDeJogo.Valor.BENCAO or alvo == EstadoDeJogo.Valor.MORTE or alvo == EstadoDeJogo.Valor.PAUSA:
			orq.pedir_estado(alvo)

	## Roda [param n] passos físicos.
	func passos(n: int) -> void:
		for i: int in n:
			orq.passo_fisico()
