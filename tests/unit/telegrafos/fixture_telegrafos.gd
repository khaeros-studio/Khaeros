class_name FixtureTelegrafos
extends RefCounted
## Fábricas e dublês em memória para as suítes unitárias de Telégrafos (ADR-0014).


class ConsultaDublê extends ConsultaDeAlvoMaldicao:
	var donos_pos: Dictionary[int, Vector2] = {}
	var donos_vivos: Dictionary[int, bool] = {}
	var jogadores_pos: Dictionary[int, Vector2] = {0: Vector2.ZERO}
	var jogadores_raios: Dictionary[int, float] = {0: 27.0}
	var maldicoes_pos: Dictionary[int, Vector2] = {}
	var maldicoes_raios: Dictionary[int, float] = {}
	var maldicoes_em_campo: Dictionary[int, bool] = {}
	var acuada_pos: Vector2 = Vector2.ZERO
	var acuada_raio: float = 22.5
	var acuada_ativa: bool = false

	func definir_dono(id: int, pos: Vector2, vivo: bool = true) -> void:
		donos_pos[id] = pos
		donos_vivos[id] = vivo

	func definir_jogador(id: int, pos: Vector2, raio: float = 27.0) -> void:
		jogadores_pos[id] = pos
		jogadores_raios[id] = raio

	func definir_maldicao(id: int, pos: Vector2, raio: float, em_campo: bool = true) -> void:
		maldicoes_pos[id] = pos
		maldicoes_raios[id] = raio
		maldicoes_em_campo[id] = em_campo

	func dono_vivo(inimigo_id: int) -> bool:
		return donos_vivos.get(inimigo_id, true)

	func posicao_dono(inimigo_id: int) -> Vector2:
		return donos_pos.get(inimigo_id, Vector2.ZERO)

	func posicao_alvo(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> Vector2:
		match faccao:
			TelegrafoTipos.FaccaoAlvo.ALIADO:
				return maldicoes_pos.get(alvo_id, Vector2.ZERO)
			TelegrafoTipos.FaccaoAlvo.ACUADA:
				return acuada_pos
			_:
				return jogadores_pos.get(alvo_id, Vector2.ZERO)

	func raio_alvo(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> float:
		match faccao:
			TelegrafoTipos.FaccaoAlvo.ALIADO:
				return maldicoes_raios.get(alvo_id, 24.0)
			TelegrafoTipos.FaccaoAlvo.ACUADA:
				return acuada_raio
			_:
				return jogadores_raios.get(alvo_id, 27.0)

	func alvo_atingivel(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> bool:
		match faccao:
			TelegrafoTipos.FaccaoAlvo.ALIADO:
				return maldicoes_em_campo.get(alvo_id, false)
			TelegrafoTipos.FaccaoAlvo.ACUADA:
				return acuada_ativa
			_:
				return true


static func eco_perdido() -> EnemyDef:
	var e := EnemyDef.new()
	e.id = &"eco_perdido"
	e.chave_nome = &"ENEMY_ECO_NAME"
	e.comportamento = &"corpo_a_corpo"
	e.vida = 30.0
	e.velocidade = 153.0
	e.raio_px = 24.0
	e.dano = 9.0
	e.alcance_px = 51.0
	e.preparo_s = 26.0 / 60.0
	e.recarga_s = 50.0 / 60.0
	e.custo_onda = 1
	return e


static func eco_do_veio() -> EnemyDef:
	var e := eco_perdido()
	e.id = &"eco_do_veio"
	e.alcance_px = 57.0
	e.raio_px = 25.5
	e.preparo_s = 24.0 / 60.0
	return e


static func anomalia_menor() -> EnemyDef:
	var e := EnemyDef.new()
	e.id = &"anomalia_menor"
	e.chave_nome = &"ENEMY_ANOMALIA_NAME"
	e.comportamento = &"distancia"
	e.vida = 24.0
	e.velocidade = 117.0
	e.raio_px = 22.5
	e.dano = 8.0
	e.alcance_px = 975.0
	e.preparo_s = 36.0 / 60.0
	e.recarga_s = 90.0 / 60.0
	e.velocidade_projetil = 414.0
	e.custo_onda = 1
	return e


static func anomalia_do_veio() -> EnemyDef:
	var e := anomalia_menor()
	e.id = &"anomalia_do_veio"
	e.raio_px = 24.0
	e.velocidade_projetil = 468.0
	return e


static func fenda_errante() -> EnemyDef:
	var e := EnemyDef.new()
	e.id = &"fenda_errante"
	e.chave_nome = &"ENEMY_FENDA_NAME"
	e.comportamento = &"arremetida"
	e.vida = 46.0
	e.velocidade = 126.0
	e.raio_px = 30.0
	e.dano = 13.0
	e.alcance_px = 570.0
	e.preparo_s = 42.0 / 60.0
	e.recarga_s = 80.0 / 60.0
	e.custo_onda = 2
	return e


static func estilhaco_vivo() -> EnemyDef:
	var e := fenda_errante()
	e.id = &"estilhaco_vivo"
	e.velocidade = 144.0
	e.raio_px = 31.5
	return e


static func soberano_do_limiar() -> EnemyDef:
	return FabricasDeCatalogo.chefe_soberano()


static func camara_livre() -> GeometriaDeMovimento:
	return GeometriaDeMovimento.new(Rect2(Vector2(-10000.0, -10000.0), Vector2(20000.0, 20000.0)))


static func vistas_pre_alocadas(n: int = 24) -> Array[VistaDeTelegrafo]:
	var v: Array[VistaDeTelegrafo] = []
	for i in n:
		v.append(VistaDeTelegrafo.new())
	return v
