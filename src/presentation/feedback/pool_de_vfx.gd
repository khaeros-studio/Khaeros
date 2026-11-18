class_name PoolDeVfx
extends Node2D
## Pool pré-alocado de nós visuais de Feedback (`vfx_sprite.gdshader` e `traco_sdf.gdshader`).
## Respeita a ordenação de camadas (`R11`: decalque de chão < corpos < estrelas < telégrafos < HUD)
## e o limite de sinais de status por inimigo (`<= 3`, ou `1` quando `> 9` inimigos têm status).

const CAPACIDADE_VFX_PADRAO: int = 32
const SHADER_VFX_PATH: String = "res://assets/shaders/sem_grading/vfx_sprite.gdshader"

var _nos_vfx: Array[ColorRect] = []
var _materiais_vfx: Array[ShaderMaterial] = []
var _cursor: int = 0


func _ready() -> void:
	_inicializar_pool_se_necessario()


func configurar_pool(capacidade: int = CAPACIDADE_VFX_PADRAO) -> void:
	_inicializar_pool_se_necessario(capacidade)


func total_alocado() -> int:
	_inicializar_pool_se_necessario()
	return _nos_vfx.size()


func ocultar_todos() -> void:
	_inicializar_pool_se_necessario()
	for n: ColorRect in _nos_vfx:
		n.visible = false


func aplicar_pedidos(pedidos: Array[PedidosDeFeedback.PedidoVfx]) -> int:
	_inicializar_pool_se_necessario()
	ocultar_todos()
	var exibidos: int = 0
	for p: PedidosDeFeedback.PedidoVfx in pedidos:
		if p == null or exibidos >= _nos_vfx.size():
			break
		var no: ColorRect = _nos_vfx[exibidos]
		var mat: ShaderMaterial = _materiais_vfx[exibidos]
		no.visible = true
		no.z_index = p.camada_z
		no.position = p.pos - no.size * 0.5
		mat.set_shader_parameter(&"cor_vfx", p.cor)
		mat.set_shader_parameter(&"intensidade", 1.25 if p.eh_estrela_acerto else 1.0)
		exibidos += 1
	return exibidos


## Calcula quantos sinais visuais de status um inimigo pode exibir (`R8`:
## até 3 sinais por inimigo; reduz para 1 quando mais de 9 inimigos estão marcados).
static func calcular_limite_sinais_status_por_inimigo(inimigos_com_status: int) -> int:
	if inimigos_com_status > 9:
		return 1
	return 3


func _inicializar_pool_se_necessario(capacidade: int = CAPACIDADE_VFX_PADRAO) -> void:
	if not _nos_vfx.is_empty():
		return
	var cap: int = maxi(8, capacidade)
	var shader: Shader = load(SHADER_VFX_PATH) as Shader
	for i: int in range(cap):
		var rect: ColorRect = ColorRect.new()
		rect.name = "VfxSlot_%02d" % i
		rect.size = Vector2(24.0, 24.0)
		rect.visible = false
		rect.light_mask = 0
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = shader
		rect.material = mat
		add_child(rect)
		_nos_vfx.append(rect)
		_materiais_vfx.append(mat)
