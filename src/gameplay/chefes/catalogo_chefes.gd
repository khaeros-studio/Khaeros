class_name CatalogoChefes
extends RefCounted

const ID_SOBERANO := &"soberano_do_limiar"
const ID_ECO_PERDIDO := &"eco_perdido"

const POS_SURGIMENTO_SOBERANO := Vector2(960.0, 285.0)
const RAIO_PILAR_PX: float = 51.0
const PILARES_SOBERANO: Array[Vector2] = [
	Vector2(390.0, 300.0),
	Vector2(1530.0, 300.0),
	Vector2(390.0, 750.0),
	Vector2(1530.0, 750.0),
]


static func criar_chefes_tuning_padrao() -> ChefesTuning:
	return FabricasDeCatalogo.chefes_tuning()


static func criar_soberano_do_limiar() -> EnemyDef:
	return FabricasDeCatalogo.chefe_soberano()


static func criar_eco_perdido_padrao() -> EnemyDef:
	var e := EnemyDef.new()
	e.id = ID_ECO_PERDIDO
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
