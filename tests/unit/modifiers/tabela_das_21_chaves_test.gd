extends GdUnitTestSuite
## Story modificadores-006: tabela das 21 chaves, validação e ordem (AC-27, AC-28, AC-06, AC-19).

const F := preload("res://tests/unit/modifiers/fabrica_de_portadores.gd")
const CANON := "res://tests/fixtures/modifiers/player_mods_canon.txt"


func _ef(tipo: StringName, v: float, escala: bool = true, params: Dictionary[StringName, float] = {}) -> EffectDef:
	var e := EffectDef.new()
	e.tipo = tipo
	e.valor = v
	e.escala_com_raridade = escala
	e.params = params
	return e


func test_tabela_tem_21_tipos_em_bijecao_com_o_canon() -> void:
	var linhas := FileAccess.get_file_as_string(CANON).strip_edges().split("\n")
	var canon: Array[String] = []
	for l: String in linhas:
		canon.append(l.strip_edges())
	var da_tabela: Array[String] = []
	for t: StringName in TabelaDeEfeitos.tipos():
		da_tabela.append(String(TabelaDeEfeitos.linha(t).chave_canon))
	assert_int(TabelaDeEfeitos.tipos().size()).is_equal(21)
	canon.sort()
	da_tabela.sort()
	assert_array(da_tabela).is_equal(canon)


func test_registro_entregue_ao_validador_rejeita_tipo_desconhecido() -> void:
	var reg := RegistrosDeChaves.new()
	TabelaDeEfeitos.registrar_em(reg)
	for t: StringName in TabelaDeEfeitos.tipos():
		assert_bool(reg.resolve(TabelaDeEfeitos.REGISTRO_TIPOS, t)).is_true()
	var boon := BoonDef.new()
	var efs: Array[EffectDef] = [_ef(&"dano_inventado", 1.0)]
	boon.efeitos = efs
	var itens: Array[ItemDoCatalogo] = [ItemDoCatalogo.new(&"boon", "res://x.tres", 0, boon)]
	var diags := V4Referencias.new(reg).validar(itens)
	var achou := false
	for d: Diagnostico in diags:
		if d.valor == &"dano_inventado":
			achou = true
	assert_bool(achou).is_true()


func test_vinculo_com_cargas_esquiva_recusado_pela_validacao() -> void:
	var reg := RegistrosDeChaves.new()
	TabelaDeEfeitos.registrar_em(reg)
	var ok: Array[StringName] = [Atributos.VIDA_MAX]
	var ruim: Array[StringName] = [Atributos.CARGAS_ESQUIVA]
	assert_int(V4Referencias.validar_fonte_vinculo(&"vinculo:vulto_mudo", ok, reg).size()).is_equal(0)
	assert_int(V4Referencias.validar_fonte_vinculo(&"vinculo:vulto_mudo", ruim, reg).size()).is_equal(1)


func test_tipo_desconhecido_em_execucao_vai_ao_relator_e_e_ignorado() -> void:
	var relator := RelatorAcumulador.new()
	var efs: Array[EffectDef] = [_ef(&"dano_inventado", 1.0), _ef(&"vida_max_plano", 10.0)]
	var f := AplicadorDeEfeitos.fonte_de(&"bencao:x", efs, 1.0, FonteDeModificador.PERMANENTE, relator)
	assert_int(relator.entradas.size()).is_equal(1)
	assert_int(f.modificadores.size()).is_equal(1)


func test_condicional_sem_param_vai_ao_relator() -> void:
	var relator := RelatorAcumulador.new()
	var efs: Array[EffectDef] = [_ef(&"dano_vida_baixa_pct", 0.4)]
	var f := AplicadorDeEfeitos.fonte_de(&"bencao:fp", efs, 1.0, FonteDeModificador.PERMANENTE, relator)
	assert_int(relator.entradas.size()).is_equal(1)
	assert_int(f.modificadores.size()).is_equal(0)


func test_condicional_multiplicador_entra_como_um_mais_valor_com_slots() -> void:
	var efs: Array[EffectDef] = [_ef(&"dano_apos_esquiva", 0.5, true, {&"janela_s": 1.5})]
	var m := AplicadorDeEfeitos.fonte_de(&"bencao:penumbra", efs, 1.0).modificadores[0]
	assert_float(m.valor).is_equal_approx(1.5, F.TOL)
	assert_int(m.condicao).is_equal(Modificador.Condicao.APOS_ESQUIVA)
	assert_int(m.slots).is_equal(Modificador.MASCARA_ATAQUE | Modificador.MASCARA_ESPECIAL)


func test_muro_preco_vigor_impeto_nas_24_ordens_vida_165_e_mesmo_m() -> void:
	var fontes: Array[FonteDeModificador] = [
		AplicadorDeEfeitos.fonte_de(&"bencao:muro_de_pedras", [_ef(&"vida_max_plano", 25.0)], 1.0),
		AplicadorDeEfeitos.fonte_de(&"bencao:preco_com_nome", [_ef(&"dano_todo_pct", 0.2), _ef(&"vida_max_plano", -10.0, false)], 1.0),
		AplicadorDeEfeitos.fonte_de(&"oficina:vigor", [_ef(&"vida_max_plano", 20.0, false)], 1.0),
		AplicadorDeEfeitos.fonte_de(&"oficina:impeto", [_ef(&"dano_todo_pct", 0.15, false)], 1.0),
	]
	var ordens := 0
	for a: int in 4:
		for b: int in 4:
			for c: int in 4:
				for d: int in 4:
					if [a, b, c, d].duplicate().size() != 4 or _repetido([a, b, c, d]):
						continue
					var p := F.jogador(130.0)
					for i: int in [a, b, c, d]:
						p.aplicar_fonte(fontes[i])
					assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(165)
					assert_float(p.multiplicador_de_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(165.0))).is_equal_approx(1.35, F.TOL)
					ordens += 1
	assert_int(ordens).is_equal(24)


func test_f5_preco_rara_muro_epico_fio_invisivel_epico() -> void:
	var p := F.jogador(130.0, {Atributos.VELOCIDADE: 100.0, Atributos.CARGAS_ESQUIVA: 1.0})
	p.aplicar_fonte(AplicadorDeEfeitos.fonte_de(&"bencao:preco_com_nome", [_ef(&"dano_todo_pct", 0.2), _ef(&"vida_max_plano", -10.0, false)], 1.5))
	p.aplicar_fonte(AplicadorDeEfeitos.fonte_de(&"bencao:muro_de_pedras", [_ef(&"vida_max_plano", 25.0)], 2.0))
	p.aplicar_fonte(AplicadorDeEfeitos.fonte_de(&"bencao:fio_invisivel", [_ef(&"velocidade_pct", 0.12), _ef(&"cargas_esquiva", 1.0, false)], 2.0))
	assert_float(p.multiplicador_de_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(170.0))).is_equal_approx(1.3, F.TOL)
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(170)
	assert_float(p.valor(Atributos.VELOCIDADE)).is_equal_approx(124.0, F.TOL)
	assert_int(p.inteiro(Atributos.CARGAS_ESQUIVA)).is_equal(2)


func _repetido(xs: Array) -> bool:
	for i: int in xs.size():
		for j: int in range(i + 1, xs.size()):
			if xs[i] == xs[j]:
				return true
	return false
