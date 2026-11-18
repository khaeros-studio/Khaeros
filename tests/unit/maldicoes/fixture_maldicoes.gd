class_name FixtureMaldicoes
extends RefCounted

const POS_JOGADOR_PADRAO := Vector2(400.0, 400.0)
const POS_INIMIGO_PADRAO := Vector2(435.0, 400.0)


class CombateAliadoSpy extends ContextoDaTecnica.CombateAliado:
	var ia: ModuloDeIA = null
	var golpes_registrados: Array[Dictionary] = []
	var abates_creditados: int = 0
	var cura_ao_abater_configurada: int = 0
	var vida_jogador: int = 100
	var vida_max_jogador: int = 100

	func _init(p_ia: ModuloDeIA = null) -> void:
		ia = p_ia

	func aplicar_golpe_maldicao(
		player_id: int,
		maldicao_id: int,
		alvos: Array[int],
		dano_golpe: float,
		m_maldicao: float,
		dir: Vector2,
		empurrao: float,
		status: Array,
		pesado: bool,
		ataque_id: StringName
	) -> void:
		var dano_int := maxi(1, FormulasDeModificadores.arredondar_meio_longe_do_zero(dano_golpe * m_maldicao))
		golpes_registrados.append({
			"player_id": player_id,
			"maldicao_id": maldicao_id,
			"alvos": alvos.duplicate(),
			"dano_golpe": dano_golpe,
			"m_maldicao": m_maldicao,
			"dano_int": dano_int,
			"dir": dir,
			"empurrao": empurrao,
			"status": status.duplicate(),
			"pesado": pesado,
			"ataque_id": ataque_id,
		})
		if ia == null:
			return
		for id_alvo: int in alvos:
			var est: EstadoDeInimigoIA = ia.estado_de(id_alvo)
			if est == null or not ia.atingivel(id_alvo) or ia.invulneravel_por_fase(id_alvo):
				continue
			est.vida = maxf(0.0, est.vida - float(dano_int))
			est.sincronizar_ref()
			if empurrao > 0.0:
				var dir_n := dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT
				var desl := dir_n * (empurrao / float(Unidades.TICK_RATE))
				ia.aplicar_impacto_combate(id_alvo, desl, 6 if pesado else 0)
			if pesado and est.vida > 0.0:
				ia.pedir_recuperacao(id_alvo)
			if est.chefe:
				ia.notificar_dano_no_chefe(id_alvo)
			if est.vida <= 0.0:
				if est.chefe and est.estado_chefe != null and est.estado_chefe.subjugavel:
					ia.subjugar(id_alvo)
				else:
					var era_lacaio := est.invocado_pelo_chefe
					ia.remover_morto(id_alvo)
					if not era_lacaio:
						abates_creditados += 1
						if cura_ao_abater_configurada > 0:
							vida_jogador = mini(vida_max_jogador, vida_jogador + cura_ao_abater_configurada)


class AmbienteCompleto extends RefCounted:
	var tuning_ml: MaldicoesTuning
	var tuning_ia: IATuning
	var tuning_tl: TelegraphTuning
	var telegrafos: Telegrafos
	var ia: ModuloDeIA
	var combate_ia: FixtureIA.CombateDublê
	var combate_aliado: CombateAliadoSpy
	var status_aliado: ContextoDaTecnica.StatusNulo
	var espelho_dupla: EspelhoDaDupla
	var portador_jogador: Portador
	var eventos: EventosDoPasso
	var geometria: GeometriaDeMovimento
	var vista: ConsultaDeVista.Fixa
	var modulo: ModuloDeMaldicoes

	var pos_jogador: Vector2 = POS_JOGADOR_PADRAO
	var dir_mira: Vector2 = Vector2.RIGHT
	var r_troca: bool = false

	func avancar_passo(avancar_ia: bool = false) -> void:
		ia.definir_jogador(0, pos_jogador, 27.0)
		modulo.definir_posicao_jogador(0, pos_jogador, dir_mira)
		status_aliado.avancar_um_passo()
		modulo.passo_jogador(0, r_troca)
		r_troca = false
		if avancar_ia:
			ia.executar_item_7()


static func criar_ambiente(
	especie_ativa: StringName = &"vulto_mudo",
	especie_reserva: StringName = &"espreitador_da_fenda",
	tuning_ml_custom: MaldicoesTuning = null,
	niveis_vinculo: Dictionary[StringName, int] = {}
) -> AmbienteCompleto:
	var amb := AmbienteCompleto.new()
	amb.tuning_ml = tuning_ml_custom if tuning_ml_custom != null else CatalogoMaldicoes.tuning_de_fabrica()
	amb.tuning_ia = IATuning.de_fabrica()
	amb.tuning_tl = TelegraphTuning.de_fabrica()
	amb.eventos = EventosDoPasso.new()
	var rect_camara := Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0))
	amb.geometria = GeometriaDeMovimento.new(rect_camara)
	amb.vista = ConsultaDeVista.Fixa.new(rect_camara)
	amb.combate_ia = FixtureIA.CombateDublê.new()
	amb.ia = ModuloDeIA.new()
	amb.telegrafos = Telegrafos.new()
	amb.combate_aliado = CombateAliadoSpy.new(amb.ia)
	amb.status_aliado = ContextoDaTecnica.StatusNulo.new()
	var mod_tuning := ModuloDeMaldicoes._normalizar_mod_tuning(ModifiersTuning.new())
	amb.espelho_dupla = EspelhoDaDupla.new()
	amb.portador_jogador = Portador.new(1, 0, Atributos.Especie.JOGADOR, {Atributos.VIDA_MAX: 100.0}, mod_tuning)
	amb.espelho_dupla.configurar_jogador(0, amb.portador_jogador, mod_tuning)

	amb.modulo = ModuloDeMaldicoes.criar(
		amb.tuning_ml,
		CatalogoMaldicoes.especies_mvp(),
		amb.ia,
		amb.combate_aliado,
		amb.status_aliado,
		amb.eventos,
		GeradorDeIds.new(),
		mod_tuning,
		amb.espelho_dupla,
		amb.geometria
	)
	amb.ia.configurar(
		amb.tuning_ia,
		RegrasDeElite.de_fabrica(),
		FabricasDeCatalogo.chefes_tuning(),
		amb.combate_ia,
		amb.telegrafos,
		amb.geometria,
		amb.modulo,
		ConsultaDaAcuada.Nula.new(),
		amb.vista,
		DeslocamentosDoChefe.Nulo.new(),
		FixtureIA.FluxoIaRoteirizado.new(),
		null,
		amb.eventos
	)
	amb.telegrafos.configurar(amb.tuning_tl, amb.ia, amb.geometria, amb.eventos)
	amb.ia.definir_jogador(0, amb.pos_jogador, 27.0)
	amb.modulo.definir_posicao_jogador(0, amb.pos_jogador, amb.dir_mira)

	var especies: Array[StringName] = []
	if especie_ativa != &"":
		especies.append(especie_ativa)
	if especie_reserva != &"":
		especies.append(especie_reserva)
	amb.modulo.iniciar_dupla(0, especies, niveis_vinculo)
	return amb


static func nascer_inimigo_padrao(
	amb: AmbienteCompleto,
	pos: Vector2 = POS_INIMIGO_PADRAO,
	vida: float = 200.0,
	pronto: bool = true,
	elite: bool = false
) -> int:
	var def := FixtureTelegrafos.eco_perdido()
	def.vida = vida
	var op := OpcoesDeNascimento.de_elite() if elite else OpcoesDeNascimento.comum()
	var id_in: int = amb.ia.criar_inimigo(def, pos, op)
	if pronto:
		var est: EstadoDeInimigoIA = amb.ia.estado_de(id_in)
		est.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
		est.timer = 100
		est.sincronizar_ref()
	return id_in
