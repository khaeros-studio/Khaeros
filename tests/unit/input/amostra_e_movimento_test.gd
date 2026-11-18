## Story input-002: amostra por passo, F1/F2 e combinação teclado/analógico (AC-02, AC-03, AC-06, AC-07,
## AC-08, AC-20 e passos sem eventos). Entradas roteirizadas pelo adaptador fora da árvore (sem dispositivo).
extends GdUnitTestSuite

# Fixture de ajustes (valores de fábrica do GDD; aqui são dados de teste, não tuning do jogo).
const ZM := 0.2
const ZE := 0.05
const LIMIAR_MOUSE := 4.0
const BUFFER := 10
const RAIO := 1350.0
const GATILHO_APERTA := 0.5
const GATILHO_SOLTA := 0.4
const TOL := 1e-6
## Arquivo legado da fatia, ainda usado por src/app/main.gd; sai quando a integração do orquestrador o trocar.
const LEGADO_PERMITIDO := "res://src/foundation/game_input.gd"
## Exceção do modo "Sem catálogo" (ADR-0006, story conteudo-009): opera apenas com eventos digitais quando o catálogo falha.
const TELA_SEM_CATALOGO := "res://src/presentation/tela_de_erros_do_catalogo.gd"


class FonteRoteirizada:
	var lotes: Array = []

	func proximo() -> AdaptadorDeEntradaGodot.Lote:
		if lotes.is_empty():
			return AdaptadorDeEntradaGodot.Lote.new()
		return lotes.pop_front()


func _adaptador() -> AdaptadorDeEntradaGodot:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	adaptador.configurar_limiares(ZM, GATILHO_APERTA, GATILHO_SOLTA)
	return adaptador


func _provedor(adaptador: AdaptadorDeEntradaGodot) -> ProvedorDeEntrada:
	var provedor := ProvedorDeEntrada.new(adaptador.drenar)
	provedor.configurar_ajustes(ZM, ZE, LIMIAR_MOUSE, BUFFER, RAIO)
	return provedor


func _tecla(codigo: int) -> DescritorDeEntrada:
	return DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, codigo)


func _vetor_proximo(atual: Vector2, esperado: Vector2, tolerancia: float) -> void:
	assert_float(atual.x).is_equal_approx(esperado.x, tolerancia)
	assert_float(atual.y).is_equal_approx(esperado.y, tolerancia)


func test_amostra_tem_nove_campos_e_faixas_validas() -> void:
	var adaptador := _adaptador()
	var provedor := _provedor(adaptador)
	adaptador.registrar_eixo(0, JOY_AXIS_LEFT_X, 1.0)
	adaptador.registrar_eixo(0, JOY_AXIS_LEFT_Y, 1.0)
	adaptador.registrar_eixo(0, JOY_AXIS_RIGHT_X, 0.3)
	adaptador.registrar_eixo(0, JOY_AXIS_RIGHT_Y, 0.4)
	var amostra := provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	for campo: String in ["mover", "mirar", "fonte_mira", "intensidade_mira", "ponto_mira", "escolha_tela",
			"id_passo", "epoca_contexto"]:
		assert_bool(campo in amostra).override_failure_message(campo).is_true()
	assert_bool(amostra.has_method("segurados") and amostra.has_method("apertados")
			and amostra.has_method("buffer")).is_true()
	assert_float(amostra.mover.length()).is_less_equal(1.0 + TOL)
	assert_float(amostra.mirar.length()).is_equal_approx(1.0, TOL)
	assert_float(amostra.intensidade_mira).is_between(0.0, 1.0)


func test_amostra_listas_devolvidas_sao_copias() -> void:
	var adaptador := _adaptador()
	var provedor := _provedor(adaptador)
	adaptador.registrar_botao(_tecla(KEY_J), true)
	var amostra := provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	amostra.segurados().clear()
	amostra.apertados().clear()
	assert_bool(amostra.esta_segurado(Acoes.ATAQUE)).is_true()
	assert_bool(amostra.foi_apertado(Acoes.ATAQUE)).is_true()


func test_varredura_input_so_na_pasta_de_input() -> void:
	var achados: Array[String] = []
	_varrer("res://src", achados)
	assert_array(achados).override_failure_message("leitura de Input fora da camada: %s" % [achados]).is_empty()


func _varrer(pasta: String, achados: Array[String]) -> void:
	var regex := RegEx.create_from_string("\\bInput\\.|\\bInputEvent")
	for sub: String in DirAccess.get_directories_at(pasta):
		if pasta.path_join(sub) != "res://src/foundation/input":
			_varrer(pasta.path_join(sub), achados)
	for nome: String in DirAccess.get_files_at(pasta):
		var caminho := pasta.path_join(nome)
		if not nome.ends_with(".gd") or caminho == LEGADO_PERMITIDO or caminho == TELA_SEM_CATALOGO:
			continue
		for linha: String in FileAccess.get_file_as_string(caminho).split("\n"):
			var codigo := linha.strip_edges()
			if codigo.begins_with("#"):
				continue
			if regex.search(codigo) != null:
				achados.append("%s: %s" % [caminho, codigo])


func test_tres_lotes_roteirizados_chegam_na_ordem() -> void:
	var fonte := FonteRoteirizada.new()
	for codigo: int in [KEY_J, KEY_K, KEY_Q]:
		var lote := AdaptadorDeEntradaGodot.Lote.new()
		lote.bordas.append(AdaptadorDeEntradaGodot.Borda.new(_tecla(codigo), 1))
		fonte.lotes.append(lote)
	var provedor := ProvedorDeEntrada.new(fonte.proximo)
	var recebidas: Array[AmostraDeEntrada] = []
	for passo: int in 3:
		recebidas.append(provedor.amostrar(passo, Acoes.CONTEXTO_JOGO, false))
	assert_array(recebidas[0].apertados()).is_equal([Acoes.ATAQUE])
	assert_array(recebidas[1].apertados()).is_equal([Acoes.ESPECIAL])
	assert_array(recebidas[2].apertados()).is_equal([Acoes.SELO])
	assert_int(recebidas[2].id_passo).is_equal(2)


func test_f1_d_mais_w_diagonal_normalizada() -> void:
	var adaptador := _adaptador()
	var provedor := _provedor(adaptador)
	adaptador.registrar_botao(_tecla(KEY_D), true)
	adaptador.registrar_botao(_tecla(KEY_W), true)
	_vetor_proximo(provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false).mover, Vector2(0.7071068, -0.7071068), TOL)


func test_f1_a_mais_d_anulam() -> void:
	var adaptador := _adaptador()
	var provedor := _provedor(adaptador)
	adaptador.registrar_botao(_tecla(KEY_A), true)
	adaptador.registrar_botao(_tecla(KEY_D), true)
	assert_vector(provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false).mover).is_equal(Vector2.ZERO)


func test_f1_w_mais_seta_cima_modulo_um() -> void:
	var adaptador := _adaptador()
	var provedor := _provedor(adaptador)
	adaptador.registrar_botao(_tecla(KEY_W), true)
	adaptador.registrar_botao(_tecla(KEY_UP), true)
	assert_vector(provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false).mover).is_equal(Vector2(0, -1))


func test_f2_vetores_do_gdd() -> void:
	_vetor_proximo(MovimentoF1F2.zona_morta_radial(Vector2(0.3, 0.4), ZM, ZE), Vector2(0.24, 0.32), TOL)
	assert_float(MovimentoF1F2.zona_morta_radial(Vector2(0.25, 0), ZM, ZE).length()).is_equal_approx(0.0667, 1e-4)
	# Vector2 é float32: |(0,2; 0)| fica ~3e-9 acima de 0,2 (double); tolerância 1e-6 como nos outros vetores.
	assert_float(MovimentoF1F2.zona_morta_radial(Vector2(0.2, 0), ZM, ZE).length()).is_equal_approx(0.0, TOL)
	assert_float(MovimentoF1F2.zona_morta_radial(Vector2(0.95, 0), ZM, ZE).length()).is_equal_approx(1.0, TOL)
	assert_float(MovimentoF1F2.zona_morta_radial(Vector2(1.0, 0), ZM, ZE).length()).is_equal_approx(1.0, TOL)
	assert_vector(MovimentoF1F2.zona_morta_radial(Vector2.ZERO, ZM, ZE)).is_equal(Vector2.ZERO)


func test_teclado_nao_zero_vence_analogico() -> void:
	var adaptador := _adaptador()
	var provedor := _provedor(adaptador)
	adaptador.registrar_eixo(0, JOY_AXIS_LEFT_X, 0.5)
	adaptador.registrar_botao(_tecla(KEY_W), true)
	assert_vector(provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false).mover).is_equal(Vector2(0, -1))


func test_teclado_zero_usa_analogico() -> void:
	var adaptador := _adaptador()
	var provedor := _provedor(adaptador)
	adaptador.registrar_eixo(0, JOY_AXIS_LEFT_X, 0.5)
	_vetor_proximo(provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false).mover, Vector2(0.4, 0), TOL)


func test_ataque_segurado_30_passos_apertado_so_no_primeiro() -> void:
	var adaptador := _adaptador()
	var provedor := _provedor(adaptador)
	adaptador.registrar_botao(_tecla(KEY_J), true)
	for passo: int in 30:
		var amostra := provedor.amostrar(passo, Acoes.CONTEXTO_JOGO, false)
		assert_bool(amostra.esta_segurado(Acoes.ATAQUE)).is_true()
		assert_bool(amostra.foi_apertado(Acoes.ATAQUE)).is_equal(passo == 0)
		provedor.encerrar_passo(passo)


func test_passos_extras_sem_eventos_conservam_segurado_sem_aperto() -> void:
	var adaptador := _adaptador()
	var provedor := _provedor(adaptador)
	adaptador.registrar_botao(_tecla(KEY_SPACE), true)
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	var segunda := provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	var terceira := provedor.amostrar(2, Acoes.CONTEXTO_JOGO, false)
	assert_bool(segunda.esta_segurado(Acoes.ESQUIVA) and terceira.esta_segurado(Acoes.ESQUIVA)).is_true()
	assert_bool(segunda.foi_apertado(Acoes.ESQUIVA) or terceira.foi_apertado(Acoes.ESQUIVA)).is_false()
