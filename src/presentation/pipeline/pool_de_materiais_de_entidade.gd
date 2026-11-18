class_name PoolDeMateriaisDeEntidade
extends RefCounted
## Pool e fábrica de `ShaderMaterial` individuais por entidade no y-sort e controle de congelamento
## de emissores/animações no relógio vivo (GDD pipeline-visual.md R6, R8, AC-PV-46, AC-PV-74; ADR-0011 §5, E3, E7).

const CAMINHO_CHAR_SPRITE: String = "res://assets/shaders/char_tint/char_sprite.gdshader"
const CAMINHO_AMB_SPRITE: String = "res://assets/shaders/amb_graded/amb_sprite.gdshader"

var _shader_char: Shader
var _shader_amb: Shader
var _livres_char: Array[ShaderMaterial] = []
var _livres_amb: Array[ShaderMaterial] = []
var _ativos: Dictionary = {} # id_entidade -> ShaderMaterial


func _init() -> void:
	_shader_char = load(CAMINHO_CHAR_SPRITE) as Shader
	_shader_amb = load(CAMINHO_AMB_SPRITE) as Shader


func adquirir_para_entidade(id_entidade: int, papel: int = 1, forca_grading: float = 0.15) -> ShaderMaterial:
	var mat: ShaderMaterial
	if _livres_char.is_empty():
		mat = ShaderMaterial.new()
		mat.shader = _shader_char
	else:
		mat = _livres_char.pop_back()
	mat.set_shader_parameter(&"papel", papel)
	mat.set_shader_parameter(&"flash", 0.0)
	mat.set_shader_parameter(&"forca_grading_personagem", forca_grading)
	mat.set_shader_parameter(&"eh_elite", false)
	mat.set_shader_parameter(&"abalo_ativo", false)
	_ativos[id_entidade] = mat
	return mat


func adquirir_para_oclusor(id_oclusor: int) -> ShaderMaterial:
	var mat: ShaderMaterial
	if _livres_amb.is_empty():
		mat = ShaderMaterial.new()
		mat.shader = _shader_amb
	else:
		mat = _livres_amb.pop_back()
	mat.set_shader_parameter(&"recebe_profundidade", true)
	mat.set_shader_parameter(&"alfa_oclusao", 1.0)
	_ativos[id_oclusor] = mat
	return mat


func devolver_entidade(id_entidade: int) -> void:
	if not _ativos.has(id_entidade):
		return
	var mat: ShaderMaterial = _ativos[id_entidade]
	_ativos.erase(id_entidade)
	if mat.shader == _shader_char:
		_livres_char.append(mat)
	elif mat.shader == _shader_amb:
		_livres_amb.append(mat)


func material_de(id_entidade: int) -> ShaderMaterial:
	return _ativos.get(id_entidade, null)


func definir_flash(id_entidade: int, flash: float) -> void:
	var mat := material_de(id_entidade)
	if mat != null:
		mat.set_shader_parameter(&"flash", clampf(flash, 0.0, 1.0))


func definir_alfa_oclusao(id_oclusor: int, alfa: float) -> void:
	var mat := material_de(id_oclusor)
	if mat != null:
		mat.set_shader_parameter(&"alfa_oclusao", clampf(alfa, 0.0, 1.0))


## E3 / AC-PV-46: Congela ou retoma `GPUParticles2D`, `CPUParticles2D` e `AnimatedSprite2D`
## conforme o relógio que os governa (`vivo` congela em hitstop/pausa/bênção; `apres` congela em pausa/bênção).
static func aplicar_congelamento_emissor(no: Node, congelado: bool) -> void:
	if no is GPUParticles2D:
		(no as GPUParticles2D).speed_scale = 0.0 if congelado else 1.0
	elif no is CPUParticles2D:
		(no as CPUParticles2D).speed_scale = 0.0 if congelado else 1.0
	elif no is AnimatedSprite2D:
		(no as AnimatedSprite2D).speed_scale = 0.0 if congelado else 1.0
