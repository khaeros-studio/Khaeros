class_name EventosDoCombate
extends RefCounted
## Eventos emitidos pelo [Combate] na lista [EventosDoPasso] do passo (GDD combate-nucleo R17,
## R3.1, R20–R25, V1–V15; ADR-0002, ADR-0010 §10, §11). Subclasses imutáveis de [EventoDoPasso]
## contendo apenas valores escalares e ids inteiros (ADR-0003).


class EvGolpe extends EventoDoPasso:
	const TIPO: StringName = &"golpe"
	var player_id: int
	var posicao: Vector2
	var mira: Vector2
	var slot: StringName
	var alcance_px: float
	var meio_angulo_graus: float
	var pesado: bool
	var n_alvos: int

	func _init(p_player_id: int, p_pos: Vector2, p_mira: Vector2, p_slot: StringName,
			p_alcance: float, p_meio_ang: float, p_pesado: bool, p_n_alvos: int) -> void:
		player_id = p_player_id
		posicao = p_pos
		mira = p_mira
		slot = p_slot
		alcance_px = p_alcance
		meio_angulo_graus = p_meio_ang
		pesado = p_pesado
		n_alvos = p_n_alvos

	func tipo() -> StringName:
		return TIPO


class EvArea extends EventoDoPasso:
	const TIPO: StringName = &"area"
	var player_id: int
	var centro: Vector2
	var raio_px: float
	var slot: StringName
	var pesado: bool
	var n_alvos: int

	func _init(p_player_id: int, p_centro: Vector2, p_raio: float, p_slot: StringName,
			p_pesado: bool, p_n_alvos: int) -> void:
		player_id = p_player_id
		centro = p_centro
		raio_px = p_raio
		slot = p_slot
		pesado = p_pesado
		n_alvos = p_n_alvos

	func tipo() -> StringName:
		return TIPO


class EvDisparo extends EventoDoPasso:
	const TIPO: StringName = &"disparo"
	var player_id: int
	var posicao: Vector2
	var direcao: Vector2
	## &"jogador" ou &"inimigo".
	var dono: StringName

	func _init(p_player_id: int, p_pos: Vector2, p_dir: Vector2, p_dono: StringName) -> void:
		player_id = p_player_id
		posicao = p_pos
		direcao = p_dir
		dono = p_dono

	func tipo() -> StringName:
		return TIPO


class EvInvestida extends EventoDoPasso:
	const TIPO: StringName = &"investida"
	var player_id: int
	var posicao: Vector2
	var direcao: Vector2
	var n_passos: int

	func _init(p_player_id: int, p_pos: Vector2, p_dir: Vector2, p_n_passos: int) -> void:
		player_id = p_player_id
		posicao = p_pos
		direcao = p_dir
		n_passos = p_n_passos

	func tipo() -> StringName:
		return TIPO


class EvAcerto extends EventoDoPasso:
	const TIPO: StringName = &"acerto"
	var alvo_id: int
	var posicao: Vector2
	var direcao: Vector2
	var dano: float
	var pesado: bool
	var enesimo_acerto: bool
	var de_arma: bool
	## &"ataque", &"especial" ou &"nenhum".
	var slot: StringName
	## &"arco", &"circulo", &"avanco", &"projetil" ou a origem (&"corte", &"parede", &"reflexo", &"explosao", &"maldicao").
	var forma: StringName
	## &"leve" ou &"pesado".
	var peso_visual: StringName
	var flash_passos: int

	func _init(p_alvo_id: int, p_pos: Vector2, p_dir: Vector2, p_dano: float,
			p_pesado: bool, p_enesimo: bool, p_de_arma: bool, p_slot: StringName,
			p_forma: StringName, p_peso_visual: StringName, p_flash_passos: int) -> void:
		alvo_id = p_alvo_id
		posicao = p_pos
		direcao = p_dir
		dano = p_dano
		pesado = p_pesado
		enesimo_acerto = p_enesimo
		de_arma = p_de_arma
		slot = p_slot
		forma = p_forma
		peso_visual = p_peso_visual
		flash_passos = p_flash_passos

	func tipo() -> StringName:
		return TIPO


class EvAcertoDeArma extends EventoDoPasso:
	const TIPO: StringName = &"acerto_de_arma"
	var player_id: int
	var alvo_id: int
	var slot: StringName
	var enesimo_acerto: bool
	var pesado: bool

	func _init(p_player_id: int, p_alvo_id: int, p_slot: StringName, p_enesimo: bool,
			p_pesado: bool) -> void:
		player_id = p_player_id
		alvo_id = p_alvo_id
		slot = p_slot
		enesimo_acerto = p_enesimo
		pesado = p_pesado

	func tipo() -> StringName:
		return TIPO


class EvParede extends EventoDoPasso:
	const TIPO: StringName = &"parede"
	var alvo_id: int
	var posicao: Vector2
	var normal: Vector2

	func _init(p_alvo_id: int, p_pos: Vector2, p_normal: Vector2) -> void:
		alvo_id = p_alvo_id
		posicao = p_pos
		normal = p_normal

	func tipo() -> StringName:
		return TIPO


class EvQuebrou extends EventoDoPasso:
	const TIPO: StringName = &"quebrou"
	var alvo_id: int
	var posicao: Vector2

	func _init(p_alvo_id: int, p_pos: Vector2) -> void:
		alvo_id = p_alvo_id
		posicao = p_pos

	func tipo() -> StringName:
		return TIPO


class EvJogadorAtingido extends EventoDoPasso:
	const TIPO: StringName = &"jogador_atingido"
	var player_id: int
	var vida_perdida: int
	var direcao: Vector2
	var inversao_passos: int
	var invuln_passos: int
	var atacante_id: int
	var ataque_id: StringName

	func _init(p_player_id: int, p_vida_perdida: int, p_dir: Vector2, p_inversao: int,
			p_invuln: int, p_atacante_id: int = -1, p_ataque_id: StringName = &"") -> void:
		player_id = p_player_id
		vida_perdida = p_vida_perdida
		direcao = p_dir
		inversao_passos = p_inversao
		invuln_passos = p_invuln
		atacante_id = p_atacante_id
		ataque_id = p_ataque_id

	func tipo() -> StringName:
		return TIPO


class EvRecusouMorte extends EventoDoPasso:
	const TIPO: StringName = &"recusou_morte"
	var player_id: int
	var vida_nova: int
	var impact_passos: int
	var invuln_passos: int

	func _init(p_player_id: int, p_vida_nova: int, p_impact: int, p_invuln: int) -> void:
		player_id = p_player_id
		vida_nova = p_vida_nova
		impact_passos = p_impact
		invuln_passos = p_invuln

	func tipo() -> StringName:
		return TIPO


class EvJogadorMorreu extends EventoDoPasso:
	const TIPO: StringName = &"jogador_morreu"
	var player_id: int
	## Dicionário opcional com "atacante_tipo" e "ataque_id" do último jogador_atingido, ou null.
	var causa: Variant

	func _init(p_player_id: int, p_causa: Variant = null) -> void:
		player_id = p_player_id
		causa = p_causa

	func tipo() -> StringName:
		return TIPO


class EvInimigoMorreu extends EventoDoPasso:
	const TIPO: StringName = &"inimigo_morreu"
	var alvo_id: int
	var posicao: Vector2
	var elite: bool
	var chefe: bool
	var vel_empurrao: Vector2
	var impact_passos: int
	var autor_player_id: int
	var limpo_pelo_chefe: bool

	func _init(p_alvo_id: int, p_pos: Vector2, p_elite: bool, p_chefe: bool,
			p_vel_empurrao: Vector2, p_impact: int, p_autor: int = 0,
			p_limpo_pelo_chefe: bool = false) -> void:
		alvo_id = p_alvo_id
		posicao = p_pos
		elite = p_elite
		chefe = p_chefe
		vel_empurrao = p_vel_empurrao
		impact_passos = p_impact
		autor_player_id = p_autor
		limpo_pelo_chefe = p_limpo_pelo_chefe

	func tipo() -> StringName:
		return TIPO


class EvExplosao extends EventoDoPasso:
	const TIPO: StringName = &"explosao"
	var posicao: Vector2
	var raio_px: float

	func _init(p_pos: Vector2, p_raio: float) -> void:
		posicao = p_pos
		raio_px = p_raio

	func tipo() -> StringName:
		return TIPO


class EvMaldicaoAtingida extends EventoDoPasso:
	const TIPO: StringName = &"maldicao_atingida"
	var player_id: int
	var curse_id: StringName
	var dano: int
	var vida_nova: int
	var direcao: Vector2
	var atacante_id: int
	var ataque_id: StringName

	func _init(p_player_id: int, p_curse_id: StringName, p_dano: int, p_vida_nova: int,
			p_dir: Vector2, p_atacante_id: int, p_ataque_id: StringName) -> void:
		player_id = p_player_id
		curse_id = p_curse_id
		dano = p_dano
		vida_nova = p_vida_nova
		direcao = p_dir
		atacante_id = p_atacante_id
		ataque_id = p_ataque_id

	func tipo() -> StringName:
		return TIPO


class EvMaldicaoExausta extends EventoDoPasso:
	const TIPO: StringName = &"maldicao_exausta"
	var player_id: int
	var curse_id: StringName
	var posicao: Vector2
	var atacante_id: int
	var ataque_id: StringName

	func _init(p_player_id: int, p_curse_id: StringName, p_pos: Vector2,
			p_atacante_id: int, p_ataque_id: StringName) -> void:
		player_id = p_player_id
		curse_id = p_curse_id
		posicao = p_pos
		atacante_id = p_atacante_id
		ataque_id = p_ataque_id

	func tipo() -> StringName:
		return TIPO


class EvChamado extends EventoDoPasso:
	const TIPO: StringName = &"chamado"
	var player_id: int
	var posicao_jogador: Vector2
	var ponto_mirado: Vector2

	func _init(p_player_id: int, p_pos: Vector2, p_ponto: Vector2) -> void:
		player_id = p_player_id
		posicao_jogador = p_pos
		ponto_mirado = p_ponto

	func tipo() -> StringName:
		return TIPO


const EvChamadoIndisponivel := preload("res://src/gameplay/armas/ev_chamado_indisponivel.gd")


class EvChefeVencido extends EventoDoPasso:
	const TIPO: StringName = &"chefe_vencido"
	var alvo_id: int
	var posicao: Vector2
	var subjugado: bool
	var autor_player_id: int
	var impact_passos: int

	func _init(p_alvo_id: int, p_pos: Vector2, p_subjugado: bool, p_autor: int,
			p_impact: int) -> void:
		alvo_id = p_alvo_id
		posicao = p_pos
		subjugado = p_subjugado
		autor_player_id = p_autor
		impact_passos = p_impact

	func tipo() -> StringName:
		return TIPO


class EvAcuadaAtingida extends EventoDoPasso:
	const TIPO: StringName = &"acuada_atingida"
	var dano: int
	var vida_nova: int
	var atacante_id: int
	var ataque_id: StringName

	func _init(p_dano: int, p_vida_nova: int, p_atacante_id: int, p_ataque_id: StringName) -> void:
		dano = p_dano
		vida_nova = p_vida_nova
		atacante_id = p_atacante_id
		ataque_id = p_ataque_id

	func tipo() -> StringName:
		return TIPO


class EvEncontroFalhou extends EventoDoPasso:
	const TIPO: StringName = &"encontro_falhou"
	var atacante_id: int
	var ataque_id: StringName

	func _init(p_atacante_id: int = -1, p_ataque_id: StringName = &"") -> void:
		atacante_id = p_atacante_id
		ataque_id = p_ataque_id

	func tipo() -> StringName:
		return TIPO
