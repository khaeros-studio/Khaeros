class_name CatalogoMaldicoes
extends RefCounted
## Catálogo canônico das 4 espécies de Maldição do MVP e suas `TecnicaDef`
## (GDD maldicoes.md §Constantes e Catálogo das 4 Espécies, emenda Pactos 2026-11-15/16; ADR-0017 §5).


static func tuning_de_fabrica() -> MaldicoesTuning:
	return FabricasDeCatalogo.maldicoes_tuning()


static func especies_mvp() -> Dictionary[StringName, CurseDef]:
	return {
		&"vulto_mudo": vulto_mudo(),
		&"espreitador_da_fenda": espreitador_da_fenda(),
		&"baluarte_de_cinza": baluarte_de_cinza(),
		&"soberano_do_limiar": soberano_do_limiar(),
	}


static func vulto_mudo() -> CurseDef:
	var c := FabricasDeCatalogo.maldicao(&"vulto_mudo", &"comum")
	c.efeito_saida = &"paredes_de_sombra"
	c.efeito_entrada = &"passo_raso"
	return c


static func espreitador_da_fenda() -> CurseDef:
	var c := FabricasDeCatalogo.maldicao(&"espreitador_da_fenda", &"refinado")
	c.efeito_saida = &"rastro_cortante"
	c.efeito_entrada = &"salto_de_emboscada"
	return c


static func baluarte_de_cinza() -> CurseDef:
	var c := FabricasDeCatalogo.maldicao(&"baluarte_de_cinza", &"raro")
	c.efeito_saida = &"cratera_de_cinza"
	c.efeito_entrada = &"queda_de_pilar"
	return c


static func soberano_do_limiar() -> CurseDef:
	var c := FabricasDeCatalogo.maldicao(&"soberano_do_limiar", &"primordial")
	c.efeito_saida = &"fenda_retida"
	c.efeito_entrada = &"irrupcao_primordial"
	return c


## Devolve a TecnicaDef de Efeito de Saída da espécie (emenda Pactos: todas causam 5 de dano base).
static func tecnica_saida(especie_id: StringName) -> TecnicaDef:
	var t := TecnicaDef.new()
	match especie_id:
		&"vulto_mudo":
			t.id = &"paredes_de_sombra"
			t.forma = &"circulo"
			t.ancoragem = &"maldicao"
			t.raio_px = 150.0
			t.dano = 5.0
			t.controle = &"imobilizar"
			t.duracao_controle_s = 1.50
			t.marca_elites_chefes_na_saida = true
		&"espreitador_da_fenda":
			t.id = &"rastro_cortante"
			t.forma = &"circulo"
			t.ancoragem = &"maldicao"
			t.raio_px = 120.0
			t.dano = 5.0
			t.empurrao = 360.0
			t.status_id = &"abalo"
			t.duracao_status_s = 4.00
		&"baluarte_de_cinza":
			t.id = &"cratera_de_cinza"
			t.forma = &"circulo"
			t.ancoragem = &"maldicao"
			t.raio_px = 150.0
			t.dano = 5.0
			t.empurrao = 720.0
			t.status_id = &"abalo"
			t.duracao_status_s = 4.00
		&"soberano_do_limiar":
			t.id = &"fenda_retida"
			t.forma = &"circulo"
			t.ancoragem = &"maldicao"
			t.raio_px = 150.0
			t.dano = 5.0
			t.controle = &"imobilizar"
			t.duracao_controle_s = 1.50
			t.marca_elites_chefes_na_saida = true
	return t


## Devolve a TecnicaDef de Efeito de Entrada da espécie (emenda Pactos: 7 sem sinergia, 6 com sinergia +50% = 9).
static func tecnica_entrada(especie_id: StringName) -> TecnicaDef:
	var t := TecnicaDef.new()
	match especie_id:
		&"vulto_mudo":
			t.id = &"passo_raso"
			t.forma = &"circulo"
			t.ancoragem = &"jogador"
			t.raio_px = 120.0
			t.dano = 7.0
			t.empurrao = 450.0
			t.bonus_sinergia_pct = 0.0
		&"espreitador_da_fenda":
			t.id = &"salto_de_emboscada"
			t.forma = &"avanco"
			t.ancoragem = &"avanco_alvo"
			t.alcance_avanco_px = 240.0
			t.raio_px = 120.0
			t.dano = 6.0
			t.bonus_sinergia_pct = 0.50
		&"baluarte_de_cinza":
			t.id = &"queda_de_pilar"
			t.forma = &"circulo"
			t.ancoragem = &"jogador"
			t.raio_px = 135.0
			t.dano = 7.0
			t.empurrao = 630.0
			t.controle = &"atrair"
			t.duracao_controle_s = 1.50
			t.bonus_sinergia_pct = 0.0
		&"soberano_do_limiar":
			t.id = &"irrupcao_primordial"
			t.forma = &"avanco"
			t.ancoragem = &"avanco_alvo"
			t.alcance_avanco_px = 240.0
			t.raio_px = 120.0
			t.dano = 6.0
			t.bonus_sinergia_pct = 0.50
	return t


## Devolve a TecnicaDef de Efeito próprio no Chamado (Raro+: Baluarte e Soberano).
static func tecnica_chamado(especie_id: StringName, duracao_abalo_baluarte_s: float = 1.50) -> TecnicaDef:
	if especie_id == &"baluarte_de_cinza":
		var t := TecnicaDef.new()
		t.id = &"eco_de_muralha"
		t.forma = &"circulo"
		t.ancoragem = &"maldicao"
		t.raio_px = 135.0
		t.dano = 0.0
		t.status_id = &"abalo"
		t.duracao_status_s = duracao_abalo_baluarte_s
		return t
	if especie_id == &"soberano_do_limiar":
		var t := TecnicaDef.new()
		t.id = &"convergencia"
		t.forma = &"circulo"
		t.ancoragem = &"maldicao"
		t.raio_px = 210.0
		t.dano = 0.0
		t.controle = &"puxar"
		t.puxao_distancia_px = 60.0
		t.puxao_parar_a_px = 36.0
		return t
	return null


## Devolve a TecnicaDef de Habilidade Única Primordial (*Pulso de Soberania* do Soberano).
static func tecnica_habilidade_unica(especie_id: StringName) -> TecnicaDef:
	if especie_id != &"soberano_do_limiar":
		return null
	var t := TecnicaDef.new()
	t.id = &"pulso_de_soberania"
	t.forma = &"circulo"
	t.ancoragem = &"maldicao"
	t.raio_px = 135.0
	t.dano = 3.0
	t.empurrao = 900.0
	t.pesado = true
	t.controle = &"atrair"
	t.duracao_controle_s = 1.00
	t.a_cada_n_ataques = 3
	return t
