class_name FixtureChefes
extends RefCounted


class CombateChefesSpy extends ContratosDeChefes.CombateParaChefes:
	var pausas_registradas: Array[int] = []
	var descartes_projeteis: int = 0
	var resolucoes_subjugado: Array[Dictionary] = []
	var jogador_morreu: bool = false
	var log_ordem: Array[String] = []
	var curas_ao_abater_disparadas: int = 0

	func pausar_combate(passos: int) -> void:
		pausas_registradas.append(passos)
		log_ordem.append("pausar_combate:%d" % passos)

	func descartar_projeteis_inimigos() -> void:
		descartes_projeteis += 1
		log_ordem.append("descartar_projeteis")

	func resolver_subjugado(id_chefe: int, escolha: StringName) -> void:
		resolucoes_subjugado.append({"id": id_chefe, "escolha": escolha})
		log_ordem.append("resolver_subjugado:%s" % String(escolha))
		if escolha == &"exorcizar":
			curas_ao_abater_disparadas += 1

	func jogador_morreu_neste_passo() -> bool:
		return jogador_morreu


class CamarasChefesSpy extends ContratosDeChefes.CamarasParaChefes:
	var limpezas_camara: int = 0
	var pilares_configurados: Array[Vector2] = []
	var raio_pilar_configurado: float = 0.0
	var log_ordem: Array[String] = []

	func limpar_camara_chefe() -> void:
		limpezas_camara += 1
		log_ordem.append("limpar_camara_chefe")

	func configurar_pilares_arena(pilares: Array[Vector2], raio_px: float) -> void:
		pilares_configurados = pilares.duplicate()
		raio_pilar_configurado = raio_px


class VinculoChefesSpy extends ContratosDeChefes.VinculoParaChefes:
	var creditos: Array[Dictionary] = []
	var log_ordem: Array[String] = []

	func creditar(fonte: StringName, quantidade: int) -> void:
		creditos.append({"fonte": fonte, "quantidade": quantidade})
		log_ordem.append("creditar:%s:%d" % [String(fonte), quantidade])


class AmbienteChefe extends RefCounted:
	var ctx_ia: FixtureIA.ContextoTeste
	var ia: ModuloDeIA
	var telegrafos: Telegrafos
	var tuning_ch: ChefesTuning
	var combate_spy: CombateChefesSpy
	var camaras_spy: CamarasChefesSpy
	var vinculo_spy: VinculoChefesSpy
	var log_compartilhado: Array[String] = []
	var modulo: ModuloDeChefes
	var id_chefe: int = -1

	func avancar_passo() -> void:
		ia.executar_item_7()
		modulo.atualizar_passo(0)


static func criar_ambiente(
	doutrina: StringName = &"lamina",
	pos_jogador: Vector2 = Vector2(960.0, 450.0),
	iniciar_pronto: bool = true
) -> AmbienteChefe:
	var amb := AmbienteChefe.new()
	var rect_arena := Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0))
	amb.ctx_ia = FixtureIA.ContextoTeste.new(rect_arena)
	amb.ia = amb.ctx_ia.ia
	amb.telegrafos = amb.ctx_ia.telegrafos
	amb.tuning_ch = CatalogoChefes.criar_chefes_tuning_padrao()

	amb.combate_spy = CombateChefesSpy.new()
	amb.camaras_spy = CamarasChefesSpy.new()
	amb.vinculo_spy = VinculoChefesSpy.new()
	amb.combate_spy.log_ordem = amb.log_compartilhado
	amb.camaras_spy.log_ordem = amb.log_compartilhado
	amb.vinculo_spy.log_ordem = amb.log_compartilhado

	amb.ia.definir_jogador(0, pos_jogador, 27.0)
	amb.modulo = ModuloDeChefes.new(
		amb.tuning_ch,
		amb.ia,
		amb.telegrafos,
		amb.combate_spy,
		amb.camaras_spy,
		amb.vinculo_spy
	)
	amb.id_chefe = amb.modulo.iniciar_confronto(doutrina)
	if iniciar_pronto and amb.id_chefe >= 0:
		var est := amb.ia.estado_de(amb.id_chefe)
		est.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
		est.timer = 1
		est.sincronizar_ref()
	return amb
