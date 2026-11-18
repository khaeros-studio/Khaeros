class_name FixtureIA
extends RefCounted
## Fábricas e dublês em memória para as suítes unitárias do épico `ia-de-inimigos-e-elites`.


class FluxoRoteirizado extends FluxoRng:
	var inteiros_fila: Array[int] = []
	var reais_fila: Array[float] = []
	var chamadas_inteiro: int = 0
	var chamadas_real: int = 0

	func _init() -> void:
		super(12345, null, null)

	func inteiro(n: int) -> int:
		chamadas_inteiro += 1
		if not inteiros_fila.is_empty():
			return clampi(inteiros_fila.pop_front(), 0, maxi(0, n - 1))
		return super(n)

	func real_unitario() -> float:
		chamadas_real += 1
		if not reais_fila.is_empty():
			return reais_fila.pop_front()
		return super()


class CombateDublê extends CombateParaIA:
	var danos_jogador: Array[Dictionary] = []
	var danos_maldicao: Array[Dictionary] = []
	var danos_acuada: Array[Dictionary] = []
	var projeteis_disparados: Array[Dictionary] = []
	var empurroes_alvo: Array[Dictionary] = []
	var hitstops_pedidos: Array[int] = []

	func ferir_jogador(player_id: int, dano_base: float, m_atacante: float,
			atacante_id: int, ataque_id: StringName) -> void:
		danos_jogador.append({
			"player_id": player_id, "dano": dano_base, "m": m_atacante,
			"atacante_id": atacante_id, "ataque_id": ataque_id,
		})

	func ferir_maldicao(maldicao_id: int, dano_base: float, m_atacante: float,
			atacante_id: int, ataque_id: StringName) -> void:
		danos_maldicao.append({
			"maldicao_id": maldicao_id, "dano": dano_base, "m": m_atacante,
			"atacante_id": atacante_id, "ataque_id": ataque_id,
		})

	func ferir_acuada(dano_base: float, m_atacante: float,
			atacante_id: int, ataque_id: StringName) -> void:
		danos_acuada.append({
			"dano": dano_base, "m": m_atacante,
			"atacante_id": atacante_id, "ataque_id": ataque_id,
		})

	func disparar_projetil(dono_inimigo_id: int, pos: Vector2, dir: Vector2, vel_pxs: float,
			raio: float, vida_s: float, dano_base: float, m_disparo: float, atravessa: bool,
			alvo_faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> void:
		projeteis_disparados.append({
			"dono_id": dono_inimigo_id, "pos": pos, "dir": dir, "vel_pxs": vel_pxs,
			"raio": raio, "vida_s": vida_s, "dano": dano_base, "m": m_disparo,
			"atravessa": atravessa, "alvo_faccao": alvo_faccao, "alvo_id": alvo_id,
		})

	func aplicar_empurrao_no_alvo(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int,
			dir: Vector2, velocidade_pxs: float) -> void:
		empurroes_alvo.append({
			"faccao": faccao, "alvo_id": alvo_id, "dir": dir, "velocidade_pxs": velocidade_pxs,
		})

	func pedir_hitstop(passos: int) -> void:
		hitstops_pedidos.append(passos)


class MaldicaoDublê extends ConsultaDaMaldicao:
	var id_campo: int = -1
	var pos: Vector2 = Vector2(600.0, 0.0)
	var raio: float = 24.0
	var atingivel: bool = true
	var fator_andar: float = 1.0

	func maldicao_em_campo(_player_id: int) -> int:
		return id_campo

	func posicao_e_raio(_maldicao_id: int) -> Vector3:
		return Vector3(pos.x, pos.y, raio)

	func maldicao_atingivel(maldicao_id: int) -> bool:
		return atingivel and maldicao_id == id_campo

	func fator_andar_atraido(_player_id: int) -> float:
		return fator_andar


class AcuadaDublê extends ConsultaDaAcuada:
	var ativa: bool = false
	var pos: Vector2 = Vector2(960.0, 540.0)
	var raio: float = 22.5

	func acuada_atingivel() -> bool:
		return ativa

	func posicao_e_raio_acuada() -> Vector3:
		return Vector3(pos.x, pos.y, raio)


class DeslocamentosDublê extends DeslocamentosDoChefe:
	var jogador_imune: bool = false
	var maldicao_imune: bool = false
	var deslocamentos_jogador: Array[Vector2] = []
	var deslocamentos_maldicao: Array[Vector2] = []
	var maldicao_duble: MaldicaoDublê = null

	func imune(faccao: TelegrafoTipos.FaccaoAlvo, _id: int) -> bool:
		return maldicao_imune if faccao == TelegrafoTipos.FaccaoAlvo.ALIADO else jogador_imune

	func deslocar(faccao: TelegrafoTipos.FaccaoAlvo, _id: int, delta: Vector2) -> void:
		if faccao == TelegrafoTipos.FaccaoAlvo.ALIADO:
			deslocamentos_maldicao.append(delta)
			if maldicao_duble != null:
				maldicao_duble.pos += delta
		else:
			deslocamentos_jogador.append(delta)


class ContextoTeste extends RefCounted:
	var ia: ModuloDeIA
	var telegrafos: Telegrafos
	var combate: CombateDublê
	var maldicao: MaldicaoDublê
	var acuada: AcuadaDublê
	var deslocamentos: DeslocamentosDublê
	var fluxo_ia: FluxoRoteirizado
	var eventos: EventosDoPasso
	var geometria: GeometriaDeMovimento
	var vista: ConsultaDeVista.Fixa

	func _init(rect_camara: Rect2 = Rect2(Vector2(-2000.0, -2000.0), Vector2(6000.0, 6000.0))) -> void:
		eventos = EventosDoPasso.new()
		geometria = GeometriaDeMovimento.new(rect_camara)
		vista = ConsultaDeVista.Fixa.new(rect_camara)
		combate = CombateDublê.new()
		maldicao = MaldicaoDublê.new()
		acuada = AcuadaDublê.new()
		deslocamentos = DeslocamentosDublê.new()
		deslocamentos.maldicao_duble = maldicao
		fluxo_ia = FluxoRoteirizado.new()
		ia = ModuloDeIA.new()
		telegrafos = Telegrafos.new()
		ia.configurar(IATuning.de_fabrica(), RegrasDeElite.de_fabrica(), FabricasDeCatalogo.chefes_tuning(),
			combate, telegrafos, geometria, maldicao, acuada, vista, deslocamentos, fluxo_ia, null, eventos)
		telegrafos.configurar(TelegraphTuning.de_fabrica(), ia, geometria, eventos)
