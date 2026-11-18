## Story input-004: buffer com contador único, ComandosDoPasso e troca (R6, R7, F3; AC-15–AC-19, AC-42–AC-44,
## capacidade retida). Tempo em passos; sem engine.
extends GdUnitTestSuite

const BUFFER := 10
const ZM := 0.2
const ZE := 0.05
const LIMIAR_MOUSE := 4.0
const RAIO := 1350.0
const EPOCA := 1


## Roda `passos` passos aplicando F3 e devolve, por passo, se `acao` está no buffer depois da atualização.
## `toques`: passo -> Array[StringName]; hitstop nos passos de `hitstop_ate` (inclusive) para baixo.
func _simular(toques: Dictionary, hitstop_ate: int, passos: int, acao: StringName) -> Array[bool]:
	var buffer := BufferDeComandos.new(BUFFER)
	var saida: Array[bool] = []
	for passo: int in passos:
		var apertados: Array[StringName] = []
		apertados.assign(toques.get(passo, []))
		buffer.atualizar(apertados, passo, EPOCA, passo <= hitstop_ate)
		saida.append(buffer.contem(acao, EPOCA))
	return saida


func _faixa(saida: Array[bool], de: int, ate: int) -> bool:
	for passo: int in range(de, ate + 1):
		if not saida[passo]:
			return false
	return true


func test_toque_no_passo_0_vale_ate_9_e_some_no_10() -> void:
	var saida := _simular({0: [Acoes.ATAQUE]}, -1, 12, Acoes.ATAQUE)
	assert_bool(_faixa(saida, 0, 9)).is_true()
	assert_bool(saida[10]).is_false()


func test_hitstop_0_a_35_toque_no_0_ou_20_vale_de_36_a_44() -> void:
	for passo_toque: int in [0, 20]:
		var buffer := BufferDeComandos.new(BUFFER)
		var disponivel: Array[bool] = []
		for passo: int in 46:
			var apertados: Array[StringName] = []
			if passo == passo_toque:
				apertados.append(Acoes.ATAQUE)
			buffer.atualizar(apertados, passo, EPOCA, passo <= 35)
			if passo == 35:
				assert_int(buffer.prazo()).is_equal(BUFFER)
			disponivel.append(buffer.contem(Acoes.ATAQUE, EPOCA))
		assert_bool(_faixa(disponivel, 36, 44)).is_true()
		assert_bool(disponivel[45]).is_false()


func test_ataque_0_e_especial_8_prazo_compartilhado_ate_17() -> void:
	var toques := {0: [Acoes.ATAQUE], 8: [Acoes.ESPECIAL]}
	var ataque := _simular(toques, -1, 19, Acoes.ATAQUE)
	var especial := _simular(toques, -1, 19, Acoes.ESPECIAL)
	assert_bool(_faixa(ataque, 0, 17) and _faixa(especial, 8, 17)).is_true()
	assert_bool(ataque[18] or especial[18]).is_false()


func test_consumidores_em_ordem_cada_um_consome_o_seu_sem_apagar_outros() -> void:
	var buffer := BufferDeComandos.new(BUFFER)
	var apertados: Array[StringName] = [Acoes.SELO, Acoes.ATAQUE, Acoes.ESPECIAL, Acoes.ESQUIVA]
	buffer.atualizar(apertados, 0, EPOCA, false)
	var comandos := ComandosDoPasso.new(buffer, [] as Array[StringName], 0, EPOCA)
	# Movimento
	assert_bool(comandos.quer(Acoes.ESQUIVA) and comandos.consumir(Acoes.ESQUIVA)).is_true()
	# Combate: Especial antes de Ataque; executa o Especial e deixa o Ataque.
	assert_bool(comandos.quer(Acoes.ESPECIAL) and comandos.consumir(Acoes.ESPECIAL)).is_true()
	assert_bool(comandos.quer(Acoes.ATAQUE)).is_true()
	# Selo por último
	assert_bool(comandos.quer(Acoes.SELO) and comandos.consumir(Acoes.SELO)).is_true()
	assert_array(buffer.visao()).is_equal([Acoes.ATAQUE])
	assert_int(buffer.prazo()).is_equal(BUFFER)
	# Passo seguinte: o Ataque continua disponível.
	buffer.atualizar([] as Array[StringName], 1, EPOCA, false)
	assert_bool(ComandosDoPasso.new(buffer, [] as Array[StringName], 1, EPOCA).quer(Acoes.ATAQUE)).is_true()


func test_ataque_segurado_com_buffer_vazio_quer_sem_mudar_buffer() -> void:
	var buffer := BufferDeComandos.new(BUFFER)
	var comandos := ComandosDoPasso.new(buffer, [Acoes.ATAQUE] as Array[StringName], 0, EPOCA)
	assert_bool(comandos.quer(Acoes.ATAQUE)).is_true()
	assert_bool(comandos.consumir(Acoes.ATAQUE)).is_false()
	assert_array(buffer.visao()).is_empty()


func _provedor() -> Array:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var provedor := ProvedorDeEntrada.new(adaptador.drenar)
	provedor.configurar_ajustes(ZM, ZE, LIMIAR_MOUSE, BUFFER, RAIO)
	return [adaptador, provedor]


func _segurar_30_passos(codigo: int, acao: StringName) -> Array[bool]:
	var partes := _provedor()
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	var provedor: ProvedorDeEntrada = partes[1]
	adaptador.registrar_botao(DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, codigo), true)
	var saida: Array[bool] = []
	for passo: int in 30:
		provedor.amostrar(passo, Acoes.CONTEXTO_JOGO, false)
		saida.append(provedor.comandos_do_passo(passo).quer(acao))
		provedor.encerrar_passo(passo)
	return saida


func test_esquiva_ou_selo_segurados_30_passos_quer_falso_a_partir_do_10() -> void:
	for par: Array in [[KEY_SPACE, Acoes.ESQUIVA], [KEY_Q, Acoes.SELO]]:
		var saida := _segurar_30_passos(par[0], par[1])
		assert_bool(_faixa(saida, 0, 9)).is_true()
		assert_bool(saida.slice(10).has(true)).is_false()


func test_troca_segurada_30_passos_quer_falso_a_partir_do_10() -> void:
	var saida := _segurar_30_passos(KEY_R, Acoes.TROCA)
	assert_bool(_faixa(saida, 0, 9)).is_true()
	assert_bool(saida.slice(10).has(true)).is_false()


func test_interagir_e_pausar_nunca_entram_no_buffer() -> void:
	var buffer := BufferDeComandos.new(BUFFER)
	buffer.atualizar([Acoes.INTERAGIR, Acoes.PAUSAR] as Array[StringName], 0, EPOCA, false)
	assert_array(buffer.visao()).is_empty()
	assert_int(buffer.prazo()).is_equal(0)


func test_esquiva_nao_consumida_fica_ate_o_prazo_acabar() -> void:
	var saida := _simular({0: [Acoes.ESQUIVA]}, -1, 11, Acoes.ESQUIVA)
	assert_bool(_faixa(saida, 0, 9)).is_true()
	assert_bool(saida[10]).is_false()


func test_troca_tocada_no_0_vale_ate_9_e_some_no_10() -> void:
	var saida := _simular({0: [Acoes.TROCA]}, -1, 11, Acoes.TROCA)
	assert_bool(_faixa(saida, 0, 9)).is_true()
	assert_bool(saida[10]).is_false()


func test_troca_com_hitstop_0_a_5_vale_de_6_a_14_e_some_no_15() -> void:
	var buffer := BufferDeComandos.new(BUFFER)
	var saida: Array[bool] = []
	for passo: int in 16:
		var apertados: Array[StringName] = []
		if passo == 0:
			apertados.append(Acoes.TROCA)
		buffer.atualizar(apertados, passo, EPOCA, passo <= 5)
		if passo <= 5:
			assert_int(buffer.prazo()).is_equal(BUFFER)
		saida.append(buffer.contem(Acoes.TROCA, EPOCA))
	assert_bool(_faixa(saida, 6, 14)).is_true()
	assert_bool(saida[15]).is_false()


func test_esquiva_ataque_troca_cada_dono_consome_sem_mudar_prazo() -> void:
	var buffer := BufferDeComandos.new(BUFFER)
	buffer.atualizar([Acoes.ESQUIVA, Acoes.ATAQUE, Acoes.TROCA] as Array[StringName], 0, EPOCA, false)
	buffer.atualizar([] as Array[StringName], 1, EPOCA, false)
	var prazo := buffer.prazo()
	var comandos := ComandosDoPasso.new(buffer, [] as Array[StringName], 1, EPOCA)
	assert_bool(comandos.consumir(Acoes.ESQUIVA)).is_true()   # Movimento
	assert_bool(comandos.quer(Acoes.ATAQUE) and comandos.quer(Acoes.TROCA)).is_true()
	assert_bool(comandos.consumir(Acoes.ATAQUE)).is_true()    # Combate
	assert_bool(comandos.quer(Acoes.TROCA)).is_true()
	assert_bool(comandos.quer(Acoes.SELO)).is_false()         # Selo: nada
	assert_bool(comandos.consumir(Acoes.TROCA)).is_true()     # Maldições
	assert_int(buffer.prazo()).is_equal(prazo)


func test_capacidade_retida_apos_fim_do_passo_fica_invalida_sem_alterar_buffer() -> void:
	var partes := _provedor()
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	var provedor: ProvedorDeEntrada = partes[1]
	var j := DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, KEY_J)
	adaptador.registrar_botao(j, true)
	adaptador.registrar_botao(j, false)
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	var retida := provedor.comandos_do_passo(0)
	provedor.encerrar_passo(0)
	assert_bool(retida.quer(Acoes.ATAQUE)).is_false()
	assert_bool(retida.consumir(Acoes.ATAQUE)).is_false()
	provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	assert_bool(provedor.comandos_do_passo(1).quer(Acoes.ATAQUE)).is_true()
	assert_bool(provedor.comandos_do_passo(0).quer(Acoes.ATAQUE)).is_false()


func test_capacidade_retida_apos_troca_de_contexto_fica_invalida() -> void:
	var partes := _provedor()
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	var provedor: ProvedorDeEntrada = partes[1]
	var j := DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, KEY_J)
	adaptador.registrar_botao(j, true)
	adaptador.registrar_botao(j, false)
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	var retida := provedor.comandos_do_passo(0)
	provedor.trocar_contexto(Acoes.CONTEXTO_PAUSA)
	assert_bool(retida.quer(Acoes.ATAQUE)).is_false()
	assert_bool(retida.consumir(Acoes.ATAQUE)).is_false()


func test_metadados_de_epoca_e_congelamento_na_entrada() -> void:
	var buffer := BufferDeComandos.new(BUFFER)
	buffer.atualizar([Acoes.ESQUIVA] as Array[StringName], 7, EPOCA, true)
	assert_dict(buffer.metadados(Acoes.ESQUIVA)).is_equal({"acao": Acoes.ESQUIVA, "passo_do_toque": 7,
			"epoca": EPOCA, "durante_congelamento": true})
	assert_bool(buffer.contem(Acoes.ESQUIVA, EPOCA + 1)).is_false()
	assert_int(buffer.drenar_esquivas_congeladas()).is_equal(1)
	assert_int(buffer.drenar_esquivas_congeladas()).is_equal(0)
