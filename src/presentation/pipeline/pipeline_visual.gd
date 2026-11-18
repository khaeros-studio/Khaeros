class_name PipelineVisual
extends Node
## Único escritor de globais de shader e uniforms de passe de tela (ADR-0011 §1, §2, §5, Key Interfaces).
## Escreve `t_vivo` e `t_apres` em todo quadro, os demais globais só quando sujos no `EstadoVisual`,
## e atualiza os três `ColorRect` opacos na camada Pós (`pass_vinheta`, `pass_wipe`, `pass_morte`),
## mantendo `visible = false` (0 draw calls) quando inativos.

class PonteDeRelogios extends PipelineDeRelogios:
	var _estado: EstadoVisual

	func _init(p_estado: EstadoVisual) -> void:
		_estado = p_estado

	func receber_relogios(t_vivo: float, t_apres: float) -> void:
		if _estado != null:
			_estado.receber_relogios(t_vivo, t_apres)

	func progresso_wipe() -> float:
		if _estado == null or _estado.passe_atual() == null:
			return 0.0
		return _estado.passe_atual().progresso()


var _estado: EstadoVisual
var _orquestrador: Object
var _escritor: EscritorDeGlobais
var _ponte_relogios: PonteDeRelogios

var _rect_vinheta: ColorRect
var _rect_wipe: ColorRect
var _rect_morte: ColorRect
var _mat_vinheta: ShaderMaterial
var _mat_wipe: ShaderMaterial
var _mat_morte: ShaderMaterial


func _init() -> void:
	name = &"PipelineVisual"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func configurar(estado: EstadoVisual, orq: Object = null, escritor: EscritorDeGlobais = null) -> void:
	_estado = estado
	_orquestrador = orq
	_escritor = escritor if escritor != null else EscritorGlobalRS.new()
	_ponte_relogios = PonteDeRelogios.new(_estado)


func ponte_de_relogios() -> PipelineDeRelogios:
	if _ponte_relogios == null:
		_ponte_relogios = PonteDeRelogios.new(_estado)
	return _ponte_relogios


func montar_passes_na_camada_pos(camada_pos: Node) -> void:
	if camada_pos == null:
		return
	var sh_vinheta := load("res://assets/shaders/passes/pass_vinheta.gdshader") as Shader
	var sh_wipe := load("res://assets/shaders/passes/pass_wipe.gdshader") as Shader
	var sh_morte := load("res://assets/shaders/passes/pass_morte.gdshader") as Shader

	_mat_vinheta = ShaderMaterial.new()
	_mat_vinheta.shader = sh_vinheta
	_rect_vinheta = _criar_color_rect(&"PassVinheta", _mat_vinheta)
	camada_pos.add_child(_rect_vinheta)

	_mat_wipe = ShaderMaterial.new()
	_mat_wipe.shader = sh_wipe
	_rect_wipe = _criar_color_rect(&"PassWipe", _mat_wipe)
	camada_pos.add_child(_rect_wipe)

	_mat_morte = ShaderMaterial.new()
	_mat_morte.shader = sh_morte
	_rect_morte = _criar_color_rect(&"PassMorte", _mat_morte)
	camada_pos.add_child(_rect_morte)


func _criar_color_rect(p_nome: StringName, mat: ShaderMaterial) -> ColorRect:
	var r := ColorRect.new()
	r.name = p_nome
	r.size = Vector2(1920, 1080)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.material = mat
	r.visible = false
	return r


## Chamado pelo `Main._process` exatamente 1 vez por quadro, após `orquestrador.quadro()` e a Cena.
func aplicar_quadro() -> void:
	if _estado == null or _escritor == null:
		return
	var tv := _estado.t_vivo()
	var ta := _estado.t_apres()
	if _orquestrador != null:
		if _orquestrador.has_method("t_vivo"):
			tv = float(_orquestrador.call("t_vivo"))
		if _orquestrador.has_method("t_apres"):
			ta = float(_orquestrador.call("t_apres"))
		_estado.receber_relogios(tv, ta)

	_escritor.escrever(&"t_vivo", tv)
	_escritor.escrever(&"t_apres", ta)

	var sujos := _estado.globais_sujos()
	for chave: StringName in sujos:
		_escritor.escrever(chave, sujos[chave])

	_atualizar_passes()


func _atualizar_passes() -> void:
	if _rect_vinheta != null and _mat_vinheta != null:
		var iv := _estado.intensidade_vinheta()
		_rect_vinheta.visible = iv > 1e-4
		if _rect_vinheta.visible:
			_mat_vinheta.set_shader_parameter(&"intensidade_vinheta", iv)

	var passe := _estado.passe_atual()
	if _rect_wipe != null and _mat_wipe != null:
		var em_wipe := passe != null and passe.ativo() and passe.tipo() != &"morte"
		_rect_wipe.visible = em_wipe
		if em_wipe:
			_mat_wipe.set_shader_parameter(&"progresso_wipe", passe.progresso())
			_mat_wipe.set_shader_parameter(&"modo_fade", passe.eh_fade())

	if _rect_morte != null and _mat_morte != null:
		var em_morte := passe != null and passe.ativo() and passe.tipo() == &"morte"
		_rect_morte.visible = em_morte
		if em_morte:
			_mat_morte.set_shader_parameter(&"progresso_morte", passe.progresso())


func passes_visiveis() -> int:
	var n := 0
	if _rect_vinheta != null and _rect_vinheta.visible:
		n += 1
	if _rect_wipe != null and _rect_wipe.visible:
		n += 1
	if _rect_morte != null and _rect_morte.visible:
		n += 1
	return n
