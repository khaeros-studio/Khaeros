class_name VistaDoHud
extends Control
## Vista `Control` ancorada do HUD na `CanvasLayer` 100 (`story-006`).
## - Margem segura fixa de `48 px` **não escalada** por `escala_hud`.
## - Suporta escala de `80%` a `150%` (`0.80 .. 1.50`) sobre os blocos ancorados.
## - Bloco do Pacto (`332×88` / `228×88` a 100%) posicionado `12 px` acima do topo do grupo do jogador.
## - Usa `MOUSE_FILTER_IGNORE` em toda a árvore de combate e zero string literal visível.

const MARGEM_SEGURA_PX: float = 48.0
const GRUPO_JOGADOR_TAMANHO_BASE: Vector2 = Vector2(360.0, 112.0)
const CHEFE_BARRA_TAMANHO_BASE: Vector2 = Vector2(680.0, 44.0)
const SALDO_BLOCO_TAMANHO_BASE: Vector2 = Vector2(180.0, 48.0)

var _modelo: ModeloDoHud = null
var _ultima_versao_aplicada: int = -1

var _grupo_jogador: Control = null
var _bloco_pacto_ctrl: Control = null
var _barra_chefe_ctrl: Control = null
var _bloco_saldo_ctrl: Control = null
var _moldura_vida_baixa: ColorRect = null

var _rotulo_vida: Label = null
var _rotulo_saldo: Label = null
var _rotulo_ganho: Label = null
var _rotulo_chefe: Label = null
var _rotulo_prompt_porta: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_construir_arvore_se_necessario()


func vincular_modelo(modelo: ModeloDoHud) -> void:
	_modelo = modelo
	_construir_arvore_se_necessario()
	atualizar_vista()


func grupo_jogador_rect() -> Rect2:
	_construir_arvore_se_necessario()
	return Rect2(_grupo_jogador.position, _grupo_jogador.size)


func bloco_pacto_rect() -> Rect2:
	_construir_arvore_se_necessario()
	return Rect2(_bloco_pacto_ctrl.position, _bloco_pacto_ctrl.size)


func barra_chefe_rect() -> Rect2:
	_construir_arvore_se_necessario()
	return Rect2(_barra_chefe_ctrl.position, _barra_chefe_ctrl.size)


func bloco_pacto_visivel() -> bool:
	_construir_arvore_se_necessario()
	return _bloco_pacto_ctrl.visible


func atualizar_vista(tamanho_viewport: Vector2 = Vector2(1920.0, 1080.0)) -> void:
	_construir_arvore_se_necessario()
	if _modelo == null:
		return

	var opcoes: OpcoesDoHud = _modelo.opcoes()
	var s: float = clampf(opcoes.escala_hud, OpcoesDoHud.ESCALA_HUD_MIN, OpcoesDoHud.ESCALA_HUD_MAX)
	modulate.a = clampf(opcoes.opacidade_hud, 0.50, 1.00)

	# 1. Posicionamento com margem segura fixa de 48 px (não escalada)
	var tam_jg: Vector2 = GRUPO_JOGADOR_TAMANHO_BASE * s
	var pos_jg: Vector2 = Vector2(MARGEM_SEGURA_PX, tamanho_viewport.y - MARGEM_SEGURA_PX - tam_jg.y)
	_grupo_jogador.position = pos_jg
	_grupo_jogador.size = tam_jg

	# 2. Bloco do Pacto 12 px (escalados) acima do grupo do jogador
	var pacto_mod: ModeloDoBlocoDoPacto = _modelo.bloco_pacto_modelo()
	_bloco_pacto_ctrl.visible = pacto_mod.visivel()
	if pacto_mod.visivel():
		var tam_pacto: Vector2 = pacto_mod.tamanho_bloco_100() * s
		var gap_y: float = ModeloDoBlocoDoPacto.OFFSET_ACIMA_GRUPO_JOGADOR_PX * s
		var dx_sacudida: float = pacto_mod.deslocamento_sacudida_px() * s
		_bloco_pacto_ctrl.size = tam_pacto
		_bloco_pacto_ctrl.position = Vector2(MARGEM_SEGURA_PX + dx_sacudida, pos_jg.y - gap_y - tam_pacto.y)

	# 3. Barra de Chefe no topo central (margem segura de 48 px)
	var rec_mod: ModeloRecursosEMundo = _modelo.recursos_mundo_modelo()
	var tam_chefe: Vector2 = CHEFE_BARRA_TAMANHO_BASE * s
	_barra_chefe_ctrl.size = tam_chefe
	_barra_chefe_ctrl.position = Vector2((tamanho_viewport.x - tam_chefe.x) * 0.5, MARGEM_SEGURA_PX)
	_barra_chefe_ctrl.visible = rec_mod.chefe_visivel()

	# 4. Bloco de Saldo no canto inferior direito (margem segura de 48 px)
	var tam_saldo: Vector2 = SALDO_BLOCO_TAMANHO_BASE * s
	_bloco_saldo_ctrl.size = tam_saldo
	_bloco_saldo_ctrl.position = Vector2(
		tamanho_viewport.x - MARGEM_SEGURA_PX - tam_saldo.x,
		tamanho_viewport.y - MARGEM_SEGURA_PX - tam_saldo.y
	)

	# 5. Textos numéricos e chaves de tradução (zero literal de idioma)
	var vida_mod: ModeloDaVida = _modelo.vida_modelo()
	_rotulo_vida.text = vida_mod.texto_vida_formatado()
	_rotulo_saldo.text = rec_mod.saldo_fragmentos_formatado()
	_rotulo_ganho.text = rec_mod.ganho_agregado_formatado()
	_rotulo_ganho.visible = (_rotulo_ganho.text != "")
	if rec_mod.chefe_visivel():
		_rotulo_chefe.text = tr(String(rec_mod.chave_nome_chefe()))
	_rotulo_prompt_porta.visible = rec_mod.porta_interagivel_visivel()
	if _rotulo_prompt_porta.visible:
		_rotulo_prompt_porta.text = tr(String(rec_mod.chave_prompt_porta()))

	var op_vb: float = vida_mod.opacidade_moldura_vida_baixa(opcoes.aviso_vida_baixa)
	_moldura_vida_baixa.visible = (op_vb > 0.001)
	_moldura_vida_baixa.color = Color(0.784, 0.216, 0.290, op_vb)
	_ultima_versao_aplicada = _modelo.versao_suja()


func _construir_arvore_se_necessario() -> void:
	if _grupo_jogador != null:
		return
	_moldura_vida_baixa = ColorRect.new()
	_moldura_vida_baixa.name = "MolduraVidaBaixa"
	_moldura_vida_baixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moldura_vida_baixa.visible = false
	add_child(_moldura_vida_baixa)

	_grupo_jogador = Control.new()
	_grupo_jogador.name = "GrupoJogador"
	_grupo_jogador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_grupo_jogador)

	_rotulo_vida = Label.new()
	_rotulo_vida.name = "RotuloVida"
	_rotulo_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grupo_jogador.add_child(_rotulo_vida)

	_bloco_pacto_ctrl = Control.new()
	_bloco_pacto_ctrl.name = "BlocoDoPacto"
	_bloco_pacto_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bloco_pacto_ctrl.visible = false
	add_child(_bloco_pacto_ctrl)

	_barra_chefe_ctrl = Control.new()
	_barra_chefe_ctrl.name = "BarraDoChefe"
	_barra_chefe_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_chefe_ctrl.visible = false
	add_child(_barra_chefe_ctrl)

	_rotulo_chefe = Label.new()
	_rotulo_chefe.name = "RotuloNomeChefe"
	_rotulo_chefe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_chefe_ctrl.add_child(_rotulo_chefe)

	_bloco_saldo_ctrl = Control.new()
	_bloco_saldo_ctrl.name = "BlocoSaldo"
	_bloco_saldo_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bloco_saldo_ctrl)

	_rotulo_saldo = Label.new()
	_rotulo_saldo.name = "RotuloSaldo"
	_rotulo_saldo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bloco_saldo_ctrl.add_child(_rotulo_saldo)

	_rotulo_ganho = Label.new()
	_rotulo_ganho.name = "RotuloGanhoAgregado"
	_rotulo_ganho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bloco_saldo_ctrl.add_child(_rotulo_ganho)

	_rotulo_prompt_porta = Label.new()
	_rotulo_prompt_porta.name = "RotuloPromptPorta"
	_rotulo_prompt_porta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo_prompt_porta.visible = false
	add_child(_rotulo_prompt_porta)
