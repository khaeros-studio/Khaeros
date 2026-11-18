extends GdUnitTestSuite
## Story movimento-002, AC-40 [I]: OrquestradorDoPasso real + buffer real do Input; dublês de Combate e Selo
## registram a ordem e leem "em esquiva" e a posição depois do Movimento. Fora de JOGO só passo_congelado().


class FonteRoteiro extends FonteDeAmostra:
	var buffer: BufferDeComandos
	var n: int = 0
	var toques: Array[int] = []
	var mover_no: Dictionary[int, Vector2] = {}

	func _init(p_buffer: BufferDeComandos) -> void:
		buffer = p_buffer

	func amostrar() -> AmostraDeEntrada:
		var apertados: Array[StringName] = []
		if toques.has(n):
			apertados.append(Acoes.ESQUIVA)
		buffer.atualizar(apertados, n, 0, false)
		var a := AmostraDeEntrada.new([], apertados, buffer.visao())
		a.id_passo = n
		a.mover = mover_no.get(n, Vector2.ZERO)
		a.mirar = Vector2.RIGHT
		n += 1
		return a


class SemHitstop extends ControleDeHitstop:
	func hitstop_ativo() -> bool:
		return false

	func passo_congelado_do_combate() -> void:
		pass


class Leitor extends Passo:
	var nome: String
	var ordem: Array[String]
	var mov: MovimentoDoJogador
	var leituras: Array = []

	func _init(p_nome: String, p_ordem: Array[String], p_mov: MovimentoDoJogador) -> void:
		nome = p_nome
		ordem = p_ordem
		mov = p_mov

	func passo(_a: AmostraDeEntrada) -> void:
		ordem.append(nome)
		leituras.append([mov.em_esquiva(), mov.posicao().x])


class MovimentoRegistrado extends Passo:
	var mov: MovimentoDoJogador
	var ordem: Array[String]
	var congelados: int = 0

	func _init(p_mov: MovimentoDoJogador, p_ordem: Array[String]) -> void:
		mov = p_mov
		ordem = p_ordem

	func passo(a: AmostraDeEntrada) -> void:
		ordem.append("movimento")
		mov.passo(a)

	func passo_congelado() -> void:
		congelados += 1
		mov.passo_congelado()


class Nada extends Passo:
	func passo(_a: AmostraDeEntrada) -> void:
		pass


func _montar(ordem: Array[String]) -> Dictionary:
	var eventos := EventosDoPasso.new()
	var buffer := BufferDeComandos.new(ApoioMovimento.PRAZO_BUFFER)
	var fonte := FonteRoteiro.new(buffer)
	var mov := MovimentoDoJogador.new(0, ApoioMovimento.tuning_fp(), ApoioMovimento.AtributosDuble.new(),
			ApoioMovimento.CombateDuble.new(), ApoioMovimento.ComandosDuble.new(buffer),
			GeometriaDeMovimento.new(ApoioMovimento.ARENA_FP), eventos)
	mov.iniciar(ApoioMovimento.POS_FP)
	var reg := MovimentoRegistrado.new(mov, ordem)
	var combate := Leitor.new("combate", ordem, mov)
	var selo := Leitor.new("selo", ordem, mov)
	var modulos: Dictionary[StringName, Passo] = {}
	for chave: StringName in OrdemDoPasso.modulos():
		modulos[chave] = Nada.new()
	modulos[OrdemDoPasso.MOVIMENTO] = reg
	modulos[OrdemDoPasso.COMBATE_GOLPE] = combate
	modulos[OrdemDoPasso.SELO] = selo
	var orq := OrquestradorDoPasso.new(eventos)
	assert_array(Array(orq.configurar_passo(fonte, SemHitstop.new(), modulos))).is_empty()
	orq.pedir_estado(EstadoDeJogo.Valor.MENU)
	orq.pedir_estado(EstadoDeJogo.Valor.TRANSICAO)
	orq.pedir_estado(EstadoDeJogo.Valor.JOGO)
	return {"orq": orq, "fonte": fonte, "mov": mov, "reg": reg, "combate": combate, "selo": selo}


func test_ordem_movimento_combate_selo_em_300_passos_e_leituras_da_esquiva() -> void:
	var ordem: Array[String] = []
	var m := _montar(ordem)
	var fonte: FonteRoteiro = m.fonte
	fonte.toques = [0]
	fonte.mover_no[0] = Vector2.RIGHT
	var orq: OrquestradorDoPasso = m.orq
	for i in 300:
		orq.passo_fisico()
	assert_int(ordem.size()).is_equal(900)
	for i in 300:
		assert_array(ordem.slice(i * 3, i * 3 + 3)).is_equal(["movimento", "combate", "selo"])
	var combate: Leitor = m.combate
	var selo: Leitor = m.selo
	assert_float(combate.leituras[0][1]).is_equal_approx(982.5, 0.001)
	for k in 9:
		assert_bool(combate.leituras[k][0]).is_equal(k <= 7)
		assert_bool(selo.leituras[k][0]).is_equal(k <= 7)
	assert_float(combate.leituras[8][1]).is_equal_approx(1162.5, 0.001)


func test_fora_de_jogo_movimento_so_recebe_passo_congelado() -> void:
	var ordem: Array[String] = []
	var m := _montar(ordem)
	var orq: OrquestradorDoPasso = m.orq
	orq.pedir_estado(EstadoDeJogo.Valor.BENCAO)
	for i in 5:
		orq.passo_fisico()
	var reg: MovimentoRegistrado = m.reg
	assert_int(reg.congelados).is_equal(5)
	assert_array(ordem).is_empty()
	var mov: MovimentoDoJogador = m.mov
	assert_vector(mov.posicao()).is_equal(ApoioMovimento.POS_FP)
