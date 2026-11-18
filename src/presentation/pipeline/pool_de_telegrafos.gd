class_name PoolDeTelegrafos
extends RefCounted
## Pool fixo de 24 slots de telégrafo (48 nós `MeshInstance2D` pré-instanciados:
## 24 quads de preenchimento em `TelegrafoPreenchimento` z = -5 e 24 malhas de borda `ArrayMesh`
## em `TelegrafoContorno` z = 5; GDD pipeline-visual.md R5, R5a, F4; ADR-0011 §5, ADR-0014).

const TETO_SLOTS: int = 24
const CAMINHO_SHADER_TEL: String = "res://assets/shaders/sem_grading/tel_sdf.gdshader"

class EstadoSlot extends RefCounted:
	var slot: int
	var ativo: bool = false
	var estado: int = TelegrafoTipos.Estado.LIVRE
	var passos_restantes_terminal: int = 0
	var flash_aceito: bool = true
	var opacidade_estado: float = 1.0
	var contorno_secundario_visivel: bool = false
	var contorno_secundario_raio: float = 0.0
	var cor_preenchimento: Color = VisualMath.COR_NUCLEO_TEL
	var cor_contorno: Color = VisualMath.COR_TINTA

	func _init(p_slot: int) -> void:
		slot = p_slot


var _tuning: VisualTuning
var _estado_visual: EstadoVisual
var _nos_preenchimento: Array[MeshInstance2D] = []
var _nos_contorno: Array[MeshInstance2D] = []
var _mats_preenchimento: Array[ShaderMaterial] = []
var _mats_contorno: Array[ShaderMaterial] = []
var _slots: Array[EstadoSlot] = []
var _no_aneis_area: Node2D = null
var _avisos_acima_teto: int = 0


func _init(tuning: VisualTuning = null, estado_visual: EstadoVisual = null) -> void:
	_tuning = tuning
	_estado_visual = estado_visual
	for i in TETO_SLOTS:
		_slots.append(EstadoSlot.new(i))


func configurar(tuning: VisualTuning, estado_visual: EstadoVisual) -> void:
	_tuning = tuning
	_estado_visual = estado_visual


## Pré-instancia o nó irmão anterior de anéis de área e os 48 nós dos 24 slots nas camadas do Mundo.
func pre_instanciar(camadas: CamadasDoMundo) -> void:
	_nos_preenchimento.clear()
	_nos_contorno.clear()
	_mats_preenchimento.clear()
	_mats_contorno.clear()

	var sh_tel := load(CAMINHO_SHADER_TEL) as Shader
	var raiz_pre := camadas.raiz(CamadasDoMundo.Camada.TELEGRAFO_PREENCHIMENTO)
	var raiz_cont := camadas.raiz(CamadasDoMundo.Camada.TELEGRAFO_CONTORNO)

	# Nó irmão anterior para anéis de área e explosão em z = -5 (R6, AC-PV-25)
	_no_aneis_area = Node2D.new()
	_no_aneis_area.name = &"AneisDeAreaVfx"
	raiz_pre.add_child(_no_aneis_area)

	var quad_padrao := MalhaDeBorda.criar_quad_preenchimento(VisualMathSdf.Forma.CIRCULO, Vector4(120, 0, 0, 0))
	var borda_padrao := MalhaDeBorda.criar_malha_borda(VisualMathSdf.Forma.CIRCULO, Vector4(120, 0, 0, 0), 4.0)

	for i in TETO_SLOTS:
		var mp := ShaderMaterial.new()
		mp.shader = sh_tel
		mp.set_shader_parameter(&"passada", 0)
		var np := MeshInstance2D.new()
		np.name = "TelPreenchimento_%02d" % i
		np.mesh = quad_padrao
		np.material = mp
		np.visible = false
		np.light_mask = 0 # R9: sem_grading fora da máscara de PointLight2D
		raiz_pre.add_child(np)
		_nos_preenchimento.append(np)
		_mats_preenchimento.append(mp)

		var mc := ShaderMaterial.new()
		mc.shader = sh_tel
		mc.set_shader_parameter(&"passada", 1)
		var nc := MeshInstance2D.new()
		nc.name = "TelContorno_%02d" % i
		nc.mesh = borda_padrao
		nc.material = mc
		nc.visible = false
		nc.light_mask = 0
		raiz_cont.add_child(nc)
		_nos_contorno.append(nc)
		_mats_contorno.append(mc)


func no_aneis_area() -> Node2D:
	return _no_aneis_area


func no_preenchimento(slot: int) -> MeshInstance2D:
	return _nos_preenchimento[slot] if slot >= 0 and slot < _nos_preenchimento.size() else null


func no_contorno(slot: int) -> MeshInstance2D:
	return _nos_contorno[slot] if slot >= 0 and slot < _nos_contorno.size() else null


func estado_slot(slot: int) -> EstadoSlot:
	return _slots[slot]


func avisos_acima_teto() -> int:
	return _avisos_acima_teto


func passos_flash_disparo() -> int:
	var dur := _tuning.duracao_flash_telegrafo_s if _tuning != null else (2.0 / 60.0)
	return maxi(1, int(round(dur * 60.0)))


## Atualiza os 24 slots a partir da lista publicada por `Telegrafos.publicar()`.
func aplicar_vistas(vistas: Array[VistaDeTelegrafo], quantas: int = -1, zoom_camera: float = 1.0) -> void:
	var total := vistas.size() if quantas < 0 else mini(quantas, vistas.size())
	if total > TETO_SLOTS:
		_avisos_acima_teto += 1

	var vistos: PackedByteArray = PackedByteArray()
	vistos.resize(TETO_SLOTS)
	vistos.fill(0)

	# 1. Soma a área dos telégrafos que entraram em DISPARO neste passo (F6)
	var area_disparo_passo := 0.0
	for idx in mini(total, TETO_SLOTS):
		var v := vistas[idx]
		if v == null or v.slot < 0 or v.slot >= TETO_SLOTS:
			continue
		if v.estado == TelegrafoTipos.Estado.DISPARO and v.passos_no_estado == 0:
			area_disparo_passo += _area_da_vista(v)

	var flash_passo_aceito := true
	if area_disparo_passo > 0.0 and _estado_visual != null:
		flash_passo_aceito = _estado_visual.pedir_flash_telegrafo(area_disparo_passo, zoom_camera)

	var w_contorno := _estado_visual.contorno_telegrafo_efetivo_px() if _estado_visual != null else 4.0

	for idx in mini(total, TETO_SLOTS):
		var v := vistas[idx]
		if v == null or v.slot < 0 or v.slot >= TETO_SLOTS:
			continue
		var s := _slots[v.slot]
		if v.estado == TelegrafoTipos.Estado.LIVRE:
			_desativar_slot(v.slot)
			continue

		var dur_disp := passos_flash_disparo()
		if v.estado == TelegrafoTipos.Estado.DISPARO and v.passos_no_estado >= dur_disp:
			_desativar_slot(v.slot)
			continue
		if (v.estado == TelegrafoTipos.Estado.QUEBRADO or v.estado == TelegrafoTipos.Estado.CANCELADO) and v.passos_no_estado >= 2:
			_desativar_slot(v.slot)
			continue

		vistos[v.slot] = 1
		s.ativo = true
		s.estado = v.estado
		if v.estado == TelegrafoTipos.Estado.DISPARO and v.passos_no_estado == 0:
			s.flash_aceito = flash_passo_aceito

		if v.estado == TelegrafoTipos.Estado.CANCELADO:
			s.opacidade_estado = 1.0 if v.passos_no_estado == 0 else 0.5
		else:
			s.opacidade_estado = 1.0

		if v.estado == TelegrafoTipos.Estado.DISPARO:
			s.cor_preenchimento = VisualMath.COR_OSSO_PLENO if s.flash_aceito else VisualMath.COR_NUCLEO_TEL
			s.contorno_secundario_visivel = false
			s.contorno_secundario_raio = 0.0
		else:
			s.cor_preenchimento = VisualMath.COR_NUCLEO_TEL
			s.contorno_secundario_raio = v.contorno_secundario_raio
			s.contorno_secundario_visivel = v.contorno_secundario_raio > 0.0

		s.cor_contorno = VisualMath.COR_TINTA if v.alvo_faccao == TelegrafoTipos.FaccaoAlvo.JOGADOR else VisualMath.COR_ANEL_TEL

		_sincronizar_nos_do_slot(v, s, w_contorno)

	for i in TETO_SLOTS:
		if vistos[i] == 0:
			_desativar_slot(i)


func _desativar_slot(slot: int) -> void:
	var s := _slots[slot]
	s.ativo = false
	s.estado = TelegrafoTipos.Estado.LIVRE
	s.contorno_secundario_visivel = false
	s.contorno_secundario_raio = 0.0
	if slot < _nos_preenchimento.size():
		_nos_preenchimento[slot].visible = false
		_nos_contorno[slot].visible = false


func _sincronizar_nos_do_slot(v: VistaDeTelegrafo, s: EstadoSlot, w_contorno: float) -> void:
	if v.slot >= _nos_preenchimento.size():
		return
	var forma_sdf := _mapear_forma(v.forma)
	var modo_sdf := _mapear_modo(v.modo)
	var dims := _montar_dims(v)
	var d_max := VisualMathSdf.raio_interno_maximo(forma_sdf, dims)
	var estado_int := _mapear_estado(v.estado)

	var np := _nos_preenchimento[v.slot]
	var nc := _nos_contorno[v.slot]
	np.position = v.pos
	np.rotation = v.rot
	np.mesh = MalhaDeBorda.criar_quad_preenchimento(forma_sdf, dims)
	np.visible = true

	nc.position = v.pos
	nc.rotation = v.rot
	nc.mesh = MalhaDeBorda.criar_malha_borda(forma_sdf, dims, w_contorno, 2.0, s.contorno_secundario_raio)
	nc.visible = true

	for m: ShaderMaterial in [_mats_preenchimento[v.slot], _mats_contorno[v.slot]]:
		m.set_shader_parameter(&"forma", forma_sdf)
		m.set_shader_parameter(&"dims", dims)
		m.set_shader_parameter(&"p", clampf(v.p, 0.0, 1.0))
		m.set_shader_parameter(&"modo_crescimento", modo_sdf)
		m.set_shader_parameter(&"estado", estado_int)
		m.set_shader_parameter(&"flash_aceito", s.flash_aceito)
		m.set_shader_parameter(&"alvo_faccao", int(v.alvo_faccao))
		m.set_shader_parameter(&"contorno_secundario_raio", s.contorno_secundario_raio)
		m.set_shader_parameter(&"contorno_px", w_contorno)
		m.set_shader_parameter(&"d_max", d_max)
		m.set_shader_parameter(&"opacidade_estado", s.opacidade_estado)


static func _area_da_vista(v: VistaDeTelegrafo) -> float:
	match v.forma:
		TelegrafoTipos.Forma.CIRCULO:
			return PI * v.raio * v.raio
		TelegrafoTipos.Forma.ANEL:
			return PI * maxf(0.0, v.r_ext * v.r_ext - v.r_int * v.r_int)
		TelegrafoTipos.Forma.RETANGULO:
			return v.comprimento * v.largura
		TelegrafoTipos.Forma.SETOR:
			var alpha := deg_to_rad(v.meio_angulo_graus)
			return alpha * v.raio * v.raio
	return 0.0


static func _mapear_forma(f: TelegrafoTipos.Forma) -> int:
	match f:
		TelegrafoTipos.Forma.CIRCULO: return VisualMathSdf.Forma.CIRCULO
		TelegrafoTipos.Forma.ANEL: return VisualMathSdf.Forma.ANEL
		TelegrafoTipos.Forma.RETANGULO: return VisualMathSdf.Forma.RETANGULO
		TelegrafoTipos.Forma.SETOR: return VisualMathSdf.Forma.SETOR
	return VisualMathSdf.Forma.CIRCULO


static func _mapear_modo(m: TelegrafoTipos.Modo) -> int:
	match m:
		TelegrafoTipos.Modo.BORDA_AO_CENTRO: return VisualMathSdf.ModoCrescimento.BORDA_AO_CENTRO
		TelegrafoTipos.Modo.CENTRO_A_BORDA: return VisualMathSdf.ModoCrescimento.CENTRO_A_BORDA
		TelegrafoTipos.Modo.AO_LONGO_DO_EIXO: return VisualMathSdf.ModoCrescimento.AO_LONGO_DO_EIXO
	return VisualMathSdf.ModoCrescimento.BORDA_AO_CENTRO


static func _mapear_estado(e: TelegrafoTipos.Estado) -> int:
	match e:
		TelegrafoTipos.Estado.CRESCENDO: return 0
		TelegrafoTipos.Estado.DISPARO: return 1
		TelegrafoTipos.Estado.QUEBRADO: return 2
		TelegrafoTipos.Estado.CANCELADO: return 3
	return 0


static func _montar_dims(v: VistaDeTelegrafo) -> Vector4:
	match v.forma:
		TelegrafoTipos.Forma.CIRCULO:
			return Vector4(v.raio, 0.0, 0.0, 0.0)
		TelegrafoTipos.Forma.ANEL:
			return Vector4(v.r_ext, v.r_int, v.r_ext, 0.0)
		TelegrafoTipos.Forma.RETANGULO:
			return Vector4(v.comprimento, v.largura, 0.0, 0.0)
		TelegrafoTipos.Forma.SETOR:
			return Vector4(v.raio, 0.0, 0.0, deg_to_rad(v.meio_angulo_graus))
	return Vector4(120.0, 0.0, 0.0, 0.0)
