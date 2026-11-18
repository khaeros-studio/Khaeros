class_name ApoioMovimento
extends RefCounted
## Fixtures e dublês dos testes do Movimento (GDD movimento-e-esquiva, Acceptance Criteria: FP).
## Não é suíte. Números aqui são os da fixture padrão do GDD (o valor exato é o ponto do teste).

const PRAZO_BUFFER: int = 10
const VELOCIDADE_FP: float = 387.0
const POS_FP := Vector2(960.0, 540.0)
const ARENA_FP := Rect2(0.0, 0.0, 1920.0, 1080.0)


## MovementTuning padrão (R11).
static func tuning_fp() -> MovementTuning:
	var t := MovementTuning.new()
	t.cargas_base = 1
	t.duracao_esquiva_s = 0.15
	t.velocidade_esquiva_pxs = 1350.0
	t.invuln_extra_s = 0.05
	t.recarga_s = 0.7
	t.fator_recuperacao = 0.45
	t.raio_jogador_px = 27.0
	return t


## Dublê do portador (ConsultaDeAtributos): velocidade e cargas_esquiva mutáveis.
class AtributosDuble extends ConsultaDeAtributos:
	var velocidade: float = VELOCIDADE_FP
	var cargas_max: int = 1
	## Resumo do gatilho do Corte (null = sem gatilho).
	var resumo_corte: ResumoDeGatilho = null

	func valor(atributo: StringName) -> float:
		if atributo == Atributos.VELOCIDADE:
			return velocidade
		if atributo == Atributos.CARGAS_ESQUIVA:
			return float(cargas_max)
		return 0.0

	func inteiro(atributo: StringName) -> int:
		if atributo == Atributos.CARGAS_ESQUIVA:
			return cargas_max
		return 0

	func congelar_dano(_slot: Modificador.Slot, _ctx: ContextoDeDano) -> DanoCongelado:
		return null

	func multiplicador_de_dano(_slot: Modificador.Slot, _ctx: ContextoDeDano) -> float:
		return 1.0

	func gatilhos(tipo: StringName) -> ResumoDeGatilho:
		if tipo == MovimentoDoJogador.GATILHO_CORTE and resumo_corte != null:
			return resumo_corte
		return ResumoDeGatilho.new(tipo)


## Resumo do gatilho da FP-Corte (total 10; alcance 9, empurrão 360, Sangramento 1).
static func resumo_fp_corte(total: float = 10.0) -> ResumoDeGatilho:
	var r := ResumoDeGatilho.new(MovimentoDoJogador.GATILHO_CORTE)
	r.total = total
	r.params = params_fp_corte()
	return r


static func params_fp_corte() -> Dictionary[StringName, float]:
	return {&"alcance_extra_px": 9.0, &"empurrao": 360.0, &"sangramento": 1.0}


## Lista de atingíveis mutável (a IA filtra; o teste troca a lista por passo).
class AlvosDuble extends AlvosDoCorte:
	var lista: Array[AlvoDoCorte] = []

	func alvos_atingiveis() -> Array[AlvoDoCorte]:
		return lista


## Dublê do Combate: registra pedidos em ordem; honra cancelar no mesmo passo.
class CombateDuble extends CombateParaMovimento:
	var pedidos: Array[String] = []
	var recuperacao: bool = false
	var investida: bool = false
	var d_investida: Vector2 = Vector2.ZERO
	var vida: float = 100.0
	## Janela apos_esquiva aberta pelo esquiva_iniciada (como o Combate real faz, Modificadores R4).
	var janela_apos_esquiva: bool = false
	## [alvo_id, dano, dir, empurrao, sangramento] de cada aplicar_corte.
	var cortes: Array = []
	## Chamado dentro de aplicar_corte (reentrada); recebe alvo_id.
	var ao_cortar: Callable = Callable()

	func em_recuperacao(_pid: int) -> bool:
		return recuperacao

	func investida_ativa(_pid: int) -> bool:
		return investida

	func deslocamento_investida(_pid: int) -> Vector2:
		return d_investida

	func cancelar(_pid: int) -> void:
		investida = false
		recuperacao = false
		pedidos.append("cancelar")

	func garantir_invulneravel(_pid: int, passos: int) -> void:
		pedidos.append("inv:%d" % passos)

	func esquiva_iniciada(_pid: int) -> void:
		janela_apos_esquiva = true
		pedidos.append("iniciada")

	func vida_atual(_pid: int) -> float:
		return vida

	func aplicar_corte(_pid: int, alvo_id: int, dano: float, dir: Vector2, empurrao: float,
			sangramento: float) -> void:
		pedidos.append("corte:%d" % alvo_id)
		cortes.append([alvo_id, dano, dir, empurrao, sangramento])
		if ao_cortar.is_valid():
			ao_cortar.call(alvo_id)


## Fonte de comandos sobre um BufferDeComandos real (Input F3).
class ComandosDuble extends FonteDeComandos:
	var buffer: BufferDeComandos
	var segurados: Array[StringName] = []

	func _init(p_buffer: BufferDeComandos) -> void:
		buffer = p_buffer

	func comandos_do_passo(id_passo: int) -> ComandosDoPasso:
		return ComandosDoPasso.new(buffer, segurados, id_passo, 0)

	func drenar_esquivas_congeladas() -> int:
		return buffer.drenar_esquivas_congeladas()


## Simulador por passos: monta o Movimento da FP e roda vivo/congelado com o buffer real.
class Sim extends RefCounted:
	var tuning: MovementTuning
	var atributos := AtributosDuble.new()
	var combate := CombateDuble.new()
	var buffer := BufferDeComandos.new(PRAZO_BUFFER)
	var comandos := ComandosDuble.new(buffer)
	var eventos := EventosDoPasso.new()
	var alvos := AlvosDuble.new()
	var mov: MovimentoDoJogador
	var n: int = 0
	## [passo, tipo] de cada evento emitido.
	var log_eventos: Array = []
	## Passos em que os pedidos do Combate começaram (índice em combate.pedidos).
	var inicios: Array[int] = []

	func _init(p_tuning: MovementTuning, cargas_max: int = 1, obstaculos: Array[ObstaculoCircular] = [],
			arena: Rect2 = ARENA_FP, portador: ConsultaDeAtributos = null) -> void:
		tuning = p_tuning
		atributos.cargas_max = cargas_max
		var consulta: ConsultaDeAtributos = portador if portador != null else atributos
		mov = MovimentoDoJogador.new(0, tuning, consulta, combate, comandos,
				GeometriaDeMovimento.new(arena, obstaculos), eventos, alvos)
		mov.iniciar(POS_FP)

	## Um passo vivo.
	func vivo(mover: Vector2 = Vector2.ZERO, toque: bool = false, mirar: Vector2 = Vector2.RIGHT,
			segurado: bool = false) -> void:
		var apertados: Array[StringName] = []
		if toque:
			apertados.append(Acoes.ESQUIVA)
		var seg: Array[StringName] = []
		if segurado:
			seg.append(Acoes.ESQUIVA)
		comandos.segurados = seg
		buffer.atualizar(apertados, n, 0, false)
		var a := AmostraDeEntrada.new(seg, apertados, buffer.visao())
		a.id_passo = n
		a.mover = mover
		a.mirar = mirar
		var antes := combate.pedidos.size()
		mov.passo(a)
		if combate.pedidos.size() > antes and combate.pedidos[antes] == "cancelar":
			inicios.append(n)
		_coletar()

	## Um passo de hitstop (buffer com prazo parado, toque conta como congelado).
	func congelado(toque: bool = false) -> void:
		var apertados: Array[StringName] = []
		if toque:
			apertados.append(Acoes.ESQUIVA)
		buffer.atualizar(apertados, n, 0, true)
		mov.passo_congelado()
		_coletar()

	## Um passo fora de JOGO (Bênção/pausa): buffer esvaziado, só passo_congelado.
	func fora_de_jogo() -> void:
		buffer.esvaziar()
		mov.passo_congelado()
		_coletar()

	## Eventos de [param tipo] no passo [param p].
	func eventos_em(tipo: StringName, p: int) -> int:
		var c := 0
		for par: Array in log_eventos:
			if par[0] == p and par[1] == tipo:
				c += 1
		return c

	## Total de eventos de [param tipo].
	func total(tipo: StringName) -> int:
		var c := 0
		for par: Array in log_eventos:
			if par[1] == tipo:
				c += 1
		return c

	func _coletar() -> void:
		for ev: EventoDoPasso in eventos.esvaziar():
			log_eventos.append([n, ev.tipo(), ev])
		n += 1
