class_name TracoEVfxMaldicoes
extends RefCounted
## Lógica e nós de apresentação do corpo do jogador (R6: tempos de inversão, contorno tracejado
## de invulnerabilidade, flash de acerto e até 3 imagens residuais no y do pé) e dos VFX das
## Maldições (R5b: fio de vínculo com estados normal/tenso/estourado e marca única do Virote em z = -5).
## Segue ADR-0011 §5, §8, Emenda Pactos e experimentos E5 e E6.

const MAX_IMAGENS_RESIDUAIS: int = 3
const CAMINHO_TRACO_SDF: String = "res://assets/shaders/sem_grading/traco_sdf.gdshader"
const CAMINHO_CHAR_GRUPO: String = "res://assets/shaders/char_tint/char_grupo.gdshader"

class EstadoCorpoJogador extends RefCounted:
	var passos_hitstop_inversao: int = 0
	var passos_vivos_inversao: int = 0
	var passos_vivos_invuln: int = 0
	var em_esquiva: bool = false

	func aplicar_dano_recebido(hitstop_passos: int, extra_inversao_passos: int, invuln_passos: int) -> void:
		if em_esquiva:
			return
		passos_hitstop_inversao = maxi(0, hitstop_passos)
		passos_vivos_inversao = maxi(0, extra_inversao_passos)
		passos_vivos_invuln = maxi(passos_vivos_invuln, invuln_passos)

	func aplicar_recusa(invuln_passos: int) -> void:
		passos_vivos_invuln = maxi(passos_vivos_invuln, invuln_passos)

	func avancar_passo(congelado_hitstop: bool) -> void:
		if congelado_hitstop:
			if passos_hitstop_inversao > 0:
				passos_hitstop_inversao -= 1
		else:
			if passos_vivos_inversao > 0:
				passos_vivos_inversao -= 1
			if passos_vivos_invuln > 0:
				passos_vivos_invuln -= 1

	func inversao_ativa(modo_impacto: int = 0) -> bool:
		if modo_impacto == EstadoVisual.ModoImpacto.RECUSA or modo_impacto == EstadoVisual.ModoImpacto.CHEFE:
			return false
		return passos_hitstop_inversao > 0 or passos_vivos_inversao > 0

	## AC-PV-80: A inversão substitui o tracejado enquanto ativa; o tracejado aparece no passo seguinte.
	func contorno_tracejado_ativo(modo_impacto: int = 0) -> bool:
		if modo_impacto == EstadoVisual.ModoImpacto.RECUSA or modo_impacto == EstadoVisual.ModoImpacto.CHEFE:
			return false
		if inversao_ativa(modo_impacto):
			return false
		return passos_vivos_invuln > 0


class EstadoFlashInimigo extends RefCounted:
	var passos_vivos_restantes: int = 0

	func iniciar(passos: int = 5) -> void:
		passos_vivos_restantes = maxi(passos_vivos_restantes, passos)

	func avancar_passo(congelado_hitstop: bool) -> void:
		if not congelado_hitstop and passos_vivos_restantes > 0:
			passos_vivos_restantes -= 1

	func ativo() -> bool:
		return passos_vivos_restantes > 0


var _tuning: VisualTuning
var _ancoras_residuais: Array[Node2D] = []
var _sprites_residuais: Array[Sprite2D] = []
var _pes_residuais: Array[Vector2] = []

var _no_fio: MeshInstance2D = null
var _mat_fio: ShaderMaterial = null
var _estado_fio: StringName = &"oculto" # &"oculto", &"normal", &"tenso", &"estourado"

var _no_marca_virote: MeshInstance2D = null
var _mat_marca_virote: ShaderMaterial = null
var _alvo_marca_id: int = -1


func _init(tuning: VisualTuning = null) -> void:
	_tuning = tuning


# --- Imagens residuais da esquiva no y do pé (AC-PV-83) -----------------------

func deixar_imagem_residual(camadas: CamadasDoMundo, pos_pe: Vector2, textura_pose: Texture2D = null) -> Node2D:
	if camadas == null:
		return null
	if _ancoras_residuais.size() >= MAX_IMAGENS_RESIDUAIS:
		var velha: Node2D = _ancoras_residuais.pop_front()
		_sprites_residuais.pop_front()
		_pes_residuais.pop_front()
		camadas.remover_ancora(velha)

	var sh_traco := load(CAMINHO_TRACO_SDF) as Shader
	var mat := ShaderMaterial.new()
	mat.shader = sh_traco
	mat.set_shader_parameter(&"modo_traco", 2)
	mat.set_shader_parameter(&"opacidade", 0.65)

	var ancora := camadas.registrar_ancora("residual_%d_%d" % [ int(pos_pe.y), _ancoras_residuais.size() ])
	ancora.position = pos_pe
	camadas.definir_pe(ancora, pos_pe)

	var spr := Sprite2D.new()
	spr.name = &"SpriteResidual"
	spr.texture = textura_pose
	spr.material = mat
	spr.light_mask = 0
	ancora.add_child(spr)

	_ancoras_residuais.append(ancora)
	_sprites_residuais.append(spr)
	_pes_residuais.append(pos_pe)
	return ancora


func limpar_imagens_residuais(camadas: CamadasDoMundo) -> void:
	if camadas != null:
		for a: Node2D in _ancoras_residuais:
			camadas.remover_ancora(a)
	_ancoras_residuais.clear()
	_sprites_residuais.clear()
	_pes_residuais.clear()


func quantidade_imagens_residuais() -> int:
	return _ancoras_residuais.size()


func pes_das_imagens_residuais() -> Array[Vector2]:
	return _pes_residuais.duplicate()


# --- R5b: Fio de vínculo e Marca do Virote em z = -5 (AC-PV-86, AC-PV-87) ----

func montar_vfx_maldicoes_em_z_menos_5(camadas: CamadasDoMundo) -> void:
	if camadas == null:
		return
	var raiz_pre := camadas.raiz(CamadasDoMundo.Camada.TELEGRAFO_PREENCHIMENTO)
	var sh_traco := load(CAMINHO_TRACO_SDF) as Shader

	_mat_fio = ShaderMaterial.new()
	_mat_fio.shader = sh_traco
	_mat_fio.set_shader_parameter(&"modo_traco", 0)
	_no_fio = MeshInstance2D.new()
	_no_fio.name = &"FioDeVinculo"
	_no_fio.mesh = MalhaDeBorda.criar_quad_preenchimento(VisualMathSdf.Forma.CIRCULO, Vector4(600, 0, 0, 0))
	_no_fio.material = _mat_fio
	_no_fio.visible = false
	_no_fio.light_mask = 0
	raiz_pre.add_child(_no_fio)
	raiz_pre.move_child(_no_fio, 0) # Primeiro filho em z = -5, abaixo de telégrafos e anéis de área

	_mat_marca_virote = ShaderMaterial.new()
	_mat_marca_virote.shader = sh_traco
	_mat_marca_virote.set_shader_parameter(&"modo_traco", 3)
	var r_virote: float = _tuning.raio_marca_virote_px if _tuning != null else 9.0
	_mat_marca_virote.set_shader_parameter(&"raio_anel", r_virote)
	_mat_marca_virote.set_shader_parameter(&"largura_px", 2.0)
	_mat_marca_virote.set_shader_parameter(&"opacidade", 0.85)
	_no_marca_virote = MeshInstance2D.new()
	_no_marca_virote.name = &"MarcaDoVirote"
	_no_marca_virote.mesh = MalhaDeBorda.criar_quad_preenchimento(VisualMathSdf.Forma.CIRCULO, Vector4(r_virote + 4.0, 0, 0, 0))
	_no_marca_virote.material = _mat_marca_virote
	_no_marca_virote.visible = false
	_no_marca_virote.light_mask = 0
	raiz_pre.add_child(_no_marca_virote)
	raiz_pre.move_child(_no_marca_virote, mini(1, raiz_pre.get_child_count() - 1))


func atualizar_fio_de_vinculo(
	em_campo: bool,
	pos_jogador: Vector2,
	pos_maldicao: Vector2,
	t_apres: float,
	alcance_fio_px: float = 480.0
) -> void:
	if not em_campo:
		_estado_fio = &"oculto"
		if _no_fio != null:
			_no_fio.visible = false
		return

	var dist: float = pos_jogador.distance_to(pos_maldicao)
	var limiar_tenso: float = 0.85 * alcance_fio_px # 408 px
	var larg: float = _tuning.largura_fio_px if _tuning != null else 2.0
	var op_base: float = _tuning.opacidade_fio if _tuning != null else 0.60
	var ciclo: float = _tuning.ciclo_fio_estourado_s if _tuning != null else 0.50

	var tracejado := false
	var estourado := false
	var op := op_base

	if dist > alcance_fio_px:
		_estado_fio = &"estourado"
		tracejado = true
		estourado = true
		var osc := 0.5 + 0.5 * sin(TAU * t_apres / maxf(ciclo, 0.1))
		op = lerpf(op_base, 1.0, osc)
	elif dist > limiar_tenso:
		_estado_fio = &"tenso"
		tracejado = true
	else:
		_estado_fio = &"normal"

	if _no_fio != null and _mat_fio != null:
		_no_fio.visible = true
		_no_fio.position = 0.5 * (pos_jogador + pos_maldicao)
		var meio := 0.5 * (pos_maldicao - pos_jogador)
		_mat_fio.set_shader_parameter(&"seg_a", -meio)
		_mat_fio.set_shader_parameter(&"seg_b", meio)
		_mat_fio.set_shader_parameter(&"largura_px", larg)
		_mat_fio.set_shader_parameter(&"opacidade", op)
		_mat_fio.set_shader_parameter(&"tracejado", tracejado)
		_mat_fio.set_shader_parameter(&"estourado", estourado)


func estado_do_fio() -> StringName:
	return _estado_fio


func no_fio() -> MeshInstance2D:
	return _no_fio


func atualizar_marca_virote(alvo_id: int, pos_alvo: Vector2 = Vector2.ZERO) -> void:
	_alvo_marca_id = alvo_id
	if _no_marca_virote != null:
		if alvo_id < 0:
			_no_marca_virote.visible = false
		else:
			_no_marca_virote.visible = true
			_no_marca_virote.position = pos_alvo


func alvo_marca_virote() -> int:
	return _alvo_marca_id


func no_marca_virote() -> MeshInstance2D:
	return _no_marca_virote
