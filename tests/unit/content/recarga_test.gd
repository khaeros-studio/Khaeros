extends GdUnitTestSuite
## Story conteudo-009 [L]: recarga em debug, revogação de ajustes e Tela de Erros do Catálogo
## (AC-05, AC-06, AC-07, AC-51).


class ConsumidorFalso:
	extends ConsumidorDeAjustes
	var catalogo_atual: Catalogo = null
	var input_tuning: InputTuning = null
	var chamadas_receber: int = 0
	var chamadas_revogar: int = 0
	var ordem_eventos: Array[String] = []

	func receber_ajustes(catalogo: Catalogo) -> void:
		chamadas_receber += 1
		catalogo_atual = catalogo
		input_tuning = catalogo.obter(&"tuning", &"input_tuning", "teste") as InputTuning if catalogo != null else null
		ordem_eventos.append("receber")

	func revogar_ajustes() -> void:
		chamadas_revogar += 1
		catalogo_atual = null
		input_tuning = null
		ordem_eventos.append("revogar")


class LeitorRastreavel:
	extends CarregadorDeCatalogo.Leitor
	var recursos: Dictionary[String, Resource] = {}
	var consumidor_observado: ConsumidorFalso = null
	var tuning_estava_revogado_na_primeira_leitura: bool = false
	var leituras: int = 0

	func existe(caminho: String) -> bool:
		return recursos.has(caminho)

	func carregar(caminho: String) -> Resource:
		_registrar_leitura()
		return recursos.get(caminho, null)

	func carregar_sem_cache(caminho: String) -> Resource:
		leituras_sem_cache += 1
		ultimo_modo_cache = ResourceLoader.CACHE_MODE_IGNORE_DEEP
		_registrar_leitura()
		return recursos.get(caminho, null)

	func _registrar_leitura() -> void:
		if leituras == 0 and consumidor_observado != null:
			tuning_estava_revogado_na_primeira_leitura = (consumidor_observado.input_tuning == null)
		leituras += 1


class ArteSempre:
	extends VerificadorDeArte
	func existe(_c: String) -> bool:
		return true


func _montar_carregador(itens: Array[ItemDoCatalogo], leitor: LeitorRastreavel) -> CarregadorDeCatalogo:
	var m := ManifestoDoCatalogo.new()
	for item in itens:
		m.acrescentar(item.tipo, item.arquivo)
		leitor.recursos[item.arquivo] = item.definicao
	leitor.recursos["res://t/manifesto.tres"] = m
	var v := ValidadorDeCatalogo.new(
		FabricasDeCatalogo.registros(),
		FabricasDeCatalogo.textos_para(itens),
		ArteSempre.new()
	)
	return CarregadorDeCatalogo.new(v, RelatorAcumulador.new(), leitor, 60)


func _itens_com_input_tuning() -> Array[ItemDoCatalogo]:
	var itens := FabricasDeCatalogo.itens_mvp()
	var it := InputTuning.new()
	it.id = &"input_tuning"
	it.buffer_passos = 10
	it.zona_morta_interna = 0.20
	it.zona_morta_externa = 0.05
	it.raio_mira_px = 540.0
	it.limiar_mouse_px = 4.0
	it.gatilho_aperta = 0.50
	it.gatilho_solta = 0.40
	itens.append(ItemDoCatalogo.new(&"tuning", "res://teste/tuning/input_tuning.tres", itens.size(), it))
	return itens


func test_ac05_recarga_em_run_ou_em_release_e_recusada_com_aviso_e_preserva_catalogo() -> void:
	var leitor := LeitorRastreavel.new()
	var itens := _itens_com_input_tuning()
	var c := _montar_carregador(itens, leitor)
	var consumidor := ConsumidorFalso.new()
	c.registrar_consumidor(consumidor)
	c.definir_debug_build(true)
	var em_run: Array[bool] = [true]
	c.definir_consulta_em_run(func() -> bool: return em_run[0])

	assert_bool(c.carregar("res://t/manifesto.tres")).is_true()
	var cat_original := c.catalogo()
	assert_object(cat_original).is_not_null()
	assert_object(consumidor.input_tuning).is_not_null()

	# Em run: recusa com aviso, preserva catálogo Pronto e não revoga ajustes
	var recarregou_em_run := c.recarregar("res://t/manifesto.tres")
	assert_bool(recarregou_em_run).is_false()
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.PRONTO)
	assert_object(c.catalogo()).is_same(cat_original)
	assert_int(consumidor.chamadas_revogar).is_equal(0)
	assert_bool(c.diagnosticos().any(func(d: Diagnostico) -> bool: return d.regra == &"RECARGA" and d.e_aviso())).is_true()

	# Em release (fora de run): também recusa com aviso
	em_run[0] = false
	c.definir_debug_build(false)
	var recarregou_release := c.recarregar("res://t/manifesto.tres")
	assert_bool(recarregou_release).is_false()
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.PRONTO)
	assert_object(c.catalogo()).is_same(cat_original)

	# Fora de run em debug: aceita recarga, usa CACHE_MODE_IGNORE_DEEP e revoga antes da 1ª leitura
	c.definir_debug_build(true)
	leitor.leituras = 0
	leitor.consumidor_observado = consumidor
	var recarregou_ok := c.recarregar("res://t/manifesto.tres")
	assert_bool(recarregou_ok).is_true()
	assert_bool(leitor.tuning_estava_revogado_na_primeira_leitura).is_true()
	assert_int(leitor.ultimo_modo_cache).is_equal(ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.PRONTO)
	assert_object(consumidor.input_tuning).is_not_null()


func test_ac06_e_ac51_recarga_invalida_descarta_catalogo_anterior_e_deixa_consumidor_sem_tuning() -> void:
	var leitor := LeitorRastreavel.new()
	var itens := _itens_com_input_tuning()
	var c := _montar_carregador(itens, leitor)
	var consumidor := ConsumidorFalso.new()
	c.registrar_consumidor(consumidor)
	c.definir_debug_build(true)
	c.definir_consulta_em_run(func() -> bool: return false)

	assert_bool(c.carregar("res://t/manifesto.tres")).is_true()
	assert_object(consumidor.input_tuning).is_not_null()

	# Corrompe InputTuning com zm + ze >= 1.0 (AC-51)
	var it := leitor.recursos["res://teste/tuning/input_tuning.tres"] as InputTuning
	it.zona_morta_interna = 0.85
	it.zona_morta_externa = 0.20

	var ok := c.recarregar("res://t/manifesto.tres")
	assert_bool(ok).is_false()
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.FALHOU)
	assert_object(c.catalogo()).is_null()
	assert_object(consumidor.input_tuning).is_null()
	assert_object(consumidor.catalogo_atual).is_null()
	assert_bool(c.diagnosticos().any(func(d: Diagnostico) -> bool: return d.regra == &"V2" and d.e_erro())).is_true()


func test_ac07_e_ac51_tela_de_erros_ordena_erros_primeiro_opera_so_digital_e_ignora_analogico() -> void:
	var porta := TelaDeErrosDoCatalogo.PortaDaAreaDeTransferencia.new()
	var tela: TelaDeErrosDoCatalogo = auto_free(TelaDeErrosDoCatalogo.new(porta, true))
	var d_aviso := Diagnostico.novo(&"V2", "preparo_s", 0.005, "EnemyDef (eco_perdido): preparo_s abaixo de meio passo", Diagnostico.Nivel.AVISO)
	d_aviso.arquivo = "res://assets/data/inimigos/eco_perdido.tres"
	d_aviso.tipo = &"enemy"
	d_aviso.id = &"eco_perdido"

	var d_erro1 := Diagnostico.novo(&"V1", "dano", null, "EnemyDef (eco_perdido): dano ausente")
	d_erro1.arquivo = "res://assets/data/inimigos/eco_perdido.tres"
	d_erro1.tipo = &"enemy"
	d_erro1.id = &"eco_perdido"

	var d_erro2 := Diagnostico.novo(&"V2", "zona_morta_interna", [0.85, 0.20], "InputTuning (input_tuning): zm + ze >= 1")
	d_erro2.arquivo = "res://assets/data/tuning/input_tuning.tres"
	d_erro2.tipo = &"tuning"
	d_erro2.id = &"input_tuning"

	# Passa aviso antes dos erros para testar que a tela ordena erros primeiro
	tela.configurar([d_aviso, d_erro1, d_erro2] as Array[Diagnostico], true)
	var exibidos := tela.diagnosticos_exibidos()
	assert_int(exibidos.size()).is_equal(3)
	assert_bool(exibidos[0].e_erro()).is_true()
	assert_bool(exibidos[1].e_erro()).is_true()
	assert_bool(exibidos[2].e_aviso()).is_true()
	assert_int(tela.botoes_visiveis().size()).is_equal(3)

	# Analógico (InputEventJoypadMotion) é totalmente ignorado (AC-51)
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 1.0
	assert_bool(tela.processar_evento_entrada(motion)).is_false()
	assert_int(tela.indice_foco()).is_equal(0)
	assert_int(tela.rolagem_vertical()).is_equal(0)

	# D-pad baixo rola a lista
	var dpad_down := InputEventJoypadButton.new()
	dpad_down.button_index = JOY_BUTTON_DPAD_DOWN
	dpad_down.pressed = true
	assert_bool(tela.processar_evento_entrada(dpad_down)).is_true()
	assert_int(tela.rolagem_vertical()).is_greater(0)

	# JOY_BUTTON_A no foco 0 ("Copiar relatório") copia o relatório
	var btn_a := InputEventJoypadButton.new()
	btn_a.button_index = JOY_BUTTON_A
	btn_a.pressed = true
	assert_bool(tela.processar_evento_entrada(btn_a)).is_true()
	assert_int(porta.chamadas).is_equal(1)
	assert_str(porta.ultimo_texto).contains("[V1]").contains("[V2]")

	# Em release (debug_build = false), botão Recarregar fica oculto (2 botões: Copiar e Sair)
	tela.configurar([d_erro1, d_erro2, d_aviso] as Array[Diagnostico], false)
	assert_int(tela.botoes_visiveis().size()).is_equal(2)

	# D-pad direita move foco para "Sair" e JOY_BUTTON_A aciona saída
	var saiu := [false]
	tela.definir_callbacks(Callable(), func() -> void: saiu[0] = true)
	var dpad_right := InputEventJoypadButton.new()
	dpad_right.button_index = JOY_BUTTON_DPAD_RIGHT
	dpad_right.pressed = true
	assert_bool(tela.processar_evento_entrada(dpad_right)).is_true()
	assert_int(tela.indice_foco()).is_equal(1)
	assert_bool(tela.processar_evento_entrada(btn_a)).is_true()
	assert_bool(saiu[0]).is_true()
