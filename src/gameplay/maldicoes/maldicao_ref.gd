class_name MaldicaoRef
extends RefCounted
## Entidade aliada da dupla de Pactos (GDD maldicoes.md R1–R24; ADR-0017 §2, ADR-0003).

enum Estado {
	SEGUINDO,
	PERSEGUINDO,
	PREPARO,
	EXECUCAO,
	RECUPERACAO,
	SALTANDO,
	PRONTA,
	EXAUSTA,
}

var id: int = -1
var player_id: int = 0
var especie_id: StringName = &""
var def: CurseDef = null
var portador: Portador = null

var vida: int = 110
var estado: Estado = Estado.SEGUINDO
var pos: Vector2 = Vector2.ZERO
var dir: Vector2 = Vector2.RIGHT
var alvo_id: int = -1
var timer_fase: int = 0
var ataques_concluidos: int = 0

## Exaustão e regeneração na reserva (F2, R9, R10, R19, R24).
var restante_exausta: int = 0
var total_exausta: int = 0
var ordem_exaustao: int = 0
var acum_regen: float = 0.0

## Fio de vínculo (F1, R5).
var estourou_fio: bool = false

## Salto do Chamado do Pacto (F4, R13).
var salto_origem: Vector2 = Vector2.ZERO
var salto_destino: Vector2 = Vector2.ZERO
var salto_passo_px: Vector2 = Vector2.ZERO
var salto_restante: int = 0
var salto_total: int = 12
var salto_dano_golpe: float = 17.0
var salto_m_chamado: float = 1.0

## Bônus de vínculo fixados no começo da run (R24, ADR-0017 §12).
var nivel_vinculo: int = 1
var mult_recuperacao_vinculo: float = 1.0
var bonus_dano_basico_vinculo: float = 0.0


func vida_max() -> int:
	if portador != null:
		return portador.inteiro(Atributos.VIDA_MAX)
	return int(def.vida_max) if def != null else 110


func velocidade_pxs() -> float:
	if portador != null:
		return portador.valor(Atributos.VELOCIDADE)
	return def.velocidade if def != null else 405.0


func raio_px() -> float:
	if portador != null:
		return portador.valor(Atributos.RAIO)
	return def.raio_px if def != null else 24.0


func reducao_dano() -> float:
	if portador != null:
		return portador.valor(Atributos.REDUCAO_DANO)
	if def != null and def.passivas.has(&"carapaca_ancorada"):
		return 0.15
	return 0.0


func multiplicador_dano() -> float:
	if portador != null:
		return portador.multiplicador_de_dano(Modificador.Slot.NENHUM, ContextoDeDano.new(float(vida), false))
	return 1.0


func em_campo() -> bool:
	return estado != Estado.PRONTA and estado != Estado.EXAUSTA


func estado_hud() -> StringName:
	match estado:
		Estado.SALTANDO:
			return &"Saltando"
		Estado.PRONTA:
			return &"Pronta"
		Estado.EXAUSTA:
			return &"Exausta"
		_:
			return &"Ativa"
