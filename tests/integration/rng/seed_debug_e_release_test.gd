## Story RNG-004, AC-20 e AC-21: `--seed` em build debug e release (injetados).
## O smoke manual no build exportado fica registrado como pendência na story.
extends GdUnitTestSuite

const SEED_ENTROPIA: int = 0x0BADF00D

var _relator: RelatorGravadorRng
var _entropia: EntropiaFalsaRng


func before_test() -> void:
	_relator = RelatorGravadorRng.new()
	_entropia = EntropiaFalsaRng.new(SEED_ENTROPIA)


func _criador(eh_debug: bool, argumentos: Array[String]) -> CriadorDeSeed:
	return CriadorDeSeed.new(_entropia, eh_debug, PackedStringArray(argumentos), _relator)


func test_debug_seed_valida_vira_seed_da_run_e_fica_fixa() -> void:
	var resultado: CriadorDeSeed.ResultadoDaSeed = _criador(true, ["--seed=3F9A07C2"]).criar_seed()
	assert_bool(resultado.criada).is_true()
	assert_int(resultado.seed).is_equal(1067059138)
	assert_int(_entropia.chamadas).is_equal(0)
	var fonte := FonteDeFluxos.new(_relator)
	fonte.iniciar_run(resultado.seed, false)
	var ondas: FluxoRng = FluxosDeCamaras.new(fonte).ondas(0, 0)
	for i: int in 50:
		ondas.inteiro(10)
	assert_int(fonte.seed()).is_equal(1067059138)


func test_debug_seed_invalida_nao_cria_run_e_nao_sorteia() -> void:
	var resultado: CriadorDeSeed.ResultadoDaSeed = _criador(true, ["--seed=xyz"]).criar_seed()
	assert_bool(resultado.criada).is_false()
	assert_str(resultado.mensagem).contains("\"xyz\"")
	assert_int(_entropia.chamadas).is_equal(0)


func test_debug_campo_do_menu_tem_precedencia_e_recusa_invalido() -> void:
	var criador := _criador(true, ["--seed=3F9A07C2"])
	assert_int(criador.criar_seed("7C2").seed).is_equal(1986)
	assert_bool(criador.criar_seed("0x7C2").criada).is_false()


func test_release_ignora_seed_usa_entropia_e_registra() -> void:
	var resultado: CriadorDeSeed.ResultadoDaSeed = _criador(false, ["--seed=3F9A07C2"]).criar_seed()
	assert_bool(resultado.criada).is_true()
	assert_int(resultado.seed).is_equal(SEED_ENTROPIA)
	assert_int(_entropia.chamadas).is_equal(1)
	assert_int(_relator.avisos.size()).is_equal(1)
	assert_str(_relator.avisos[0]).contains(CriadorDeSeed.AVISO_RELEASE)


func test_sem_argumento_entropia_mascarada_em_u32() -> void:
	_entropia.valor = -1
	var resultado: CriadorDeSeed.ResultadoDaSeed = _criador(true, []).criar_seed()
	assert_int(resultado.seed).is_equal(0xFFFFFFFF)
	assert_int(_relator.total()).is_equal(0)
