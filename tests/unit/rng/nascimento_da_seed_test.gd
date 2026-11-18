## Story RNG-004, AC-39: momento do nascimento da seed (R2-P). O fluxo de telas
## real é do épico de Run; aqui um roteiro mínimo dirige a fonte e o criador.
extends GdUnitTestSuite

const SEED_FALSA: int = 0x3F9A07C2

var _relator: RelatorGravadorRng
var _entropia: EntropiaFalsaRng
var _fonte: FonteDeFluxos
var _criador: CriadorDeSeed


func before_test() -> void:
	_relator = RelatorGravadorRng.new()
	_entropia = EntropiaFalsaRng.new(SEED_FALSA)
	_fonte = FonteDeFluxos.new(_relator)
	_criador = CriadorDeSeed.new(_entropia, false, PackedStringArray(), _relator)


## Roteiro: confirmar a arma cria a run, salvo quando a seed nasce na dupla.
func _confirmar_arma(doutrina: StringName) -> void:
	if not CriadorDeSeed.seed_nasce_na_dupla(doutrina):
		_criar_run(false)


func _criar_run(pactos: bool) -> void:
	var resultado: CriadorDeSeed.ResultadoDaSeed = _criador.criar_seed()
	if resultado.criada:
		_fonte.iniciar_run(resultado.seed, pactos)


func test_besta_confirmada_tela_da_dupla_sem_seed_e_fluxo_e_erro() -> void:
	_confirmar_arma(&"pactos")
	assert_bool(_fonte.tem_seed()).is_false()
	assert_object(FluxosDeVinculo.new(_fonte).pactos(0)).is_null()
	assert_int(_relator.pedidos.size()).is_equal(1)
	assert_int(_entropia.chamadas).is_equal(0)


func test_dupla_confirmada_cria_seed_e_primeiro_fluxo_e_pactos() -> void:
	_confirmar_arma(&"pactos")
	_criar_run(true)
	assert_int(_fonte.seed()).is_equal(SEED_FALSA)
	var pactos: FluxoRng = FluxosDeVinculo.new(_fonte).pactos(0)
	assert_object(pactos).is_not_null()
	assert_int(pactos.estado()).is_equal(RngAritmetica.derivar(SEED_FALSA, FonteDeFluxos.PACTOS, 0, 0))
	assert_int(_fonte.fluxos_abertos()).is_equal(1)


func test_esc_na_tela_da_dupla_volta_sem_seed() -> void:
	_confirmar_arma(&"pactos")
	# Esc: o roteiro não chama nada na fonte nem no criador.
	assert_int(_fonte.estado()).is_equal(FonteDeFluxos.Estado.SEM_RUN)
	assert_int(_entropia.chamadas).is_equal(0)


func test_lamina_seed_nasce_ao_confirmar_a_arma() -> void:
	_confirmar_arma(&"lamina")
	assert_bool(_fonte.tem_seed()).is_true()
	assert_int(_entropia.chamadas).is_equal(1)
	assert_object(FluxosDeVinculo.new(_fonte).pactos(0)).is_null()


func test_seed_nasce_na_dupla_so_para_pactos() -> void:
	assert_bool(CriadorDeSeed.seed_nasce_na_dupla(&"pactos")).is_true()
	assert_bool(CriadorDeSeed.seed_nasce_na_dupla(&"lamina")).is_false()
	assert_bool(CriadorDeSeed.seed_nasce_na_dupla(&"ressonancia")).is_false()
