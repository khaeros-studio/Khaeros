extends GdUnitTestSuite
## Story vinculo-e-pactos/002: PerfilVinculo e a seção `[vinculo]` (escrever/ler/campos_de_ids).
## Cobre AC-VP-02 (parte perfil), AC-VP-24 e AC-VP-25.


func test_ac_vp_25_campos_de_ids() -> void:
	var p := PerfilVinculo.new()
	assert_array(Array(p.campos_de_ids())).is_equal(["ultima_dupla", "encontro_pendente"])


func test_ac_vp_24_ler_recalcula_nivel_limpa_ultima_dupla_duplicada_e_emite_vp_s1() -> void:
	var avisos: Array[String] = []
	var p := PerfilVinculo.new([], FabricasDeCatalogo.vinculo_tuning(), func(cod: StringName, chave: String) -> void:
		if cod == PerfilVinculo.AVISO_VP_S1:
			avisos.append(chave)
	)
	var entrada: Dictionary = {
		"versao": 1,
		"primeiro_pacto_concedido": true,
		"ultima_dupla": ["vulto_mudo", "vulto_mudo"],
		"especies": {
			"vulto_mudo": {
				"pactuada": true,
				"vinculo_pontos": 55,
				"nivel": 7,
				"encontros_vistos": 2,
				"encontros_bem_sucedidos": 1,
			}
		}
	}
	p.ler(entrada)

	var est := p.estado_de(&"vulto_mudo")
	assert_int(est.vinculo_pontos).is_equal(55)
	assert_int(est.nivel).is_equal(3) # F3(55) com limiares [20, 50, 90, 140] -> 1 + 2 = 3
	assert_array(p.ultima_dupla).is_equal(["vulto_mudo"])
	assert_int(avisos.size()).is_equal(2)

	# escrever() só tem bool, int, String, Array e Dictionary, e é aceito pelo RepositorioDePerfil
	var a := ArmazemEmMemoria.new()
	var repo := RepositorioDePerfil.new(
		a, CaminhosDePersistencia.de(0), Callable(),
		PackedStringArray(["vulto_mudo", "espreitador_da_fenda", "baluarte_de_cinza", "soberano_do_limiar"]),
		p
	)
	repo.carregar()
	p.ler(entrada)
	assert_int(repo.salvar()).is_equal(OK)


func test_ac_vp_02_run_com_lamina_nao_altera_escrever() -> void:
	var p := PerfilVinculo.new()
	var v := Vinculo.new(p)
	var antes: Dictionary = p.escrever()

	v.pedir_dupla(&"lamina")
	v.planejar_encontro(&"lamina", null)
	v.ao_montar_camara(1, [])
	v.ao_camara_limpa(1, &"combate")
	v.consolidar_run(&"vitoria", true)

	assert_dict(p.escrever()).is_equal(antes)
