class_name CartaView
extends Control
## Vista `Control` de uma carta `320×500` com as 6 zonas da Art Bible §7.5 (`story-005`).
## - Usa `offset_transform_enabled = true`, `offset_transform_scale`, `offset_transform_offset`
##   e `offset_transform_visual_only = true` (Godot 4.7) para aplicar o destaque de foco
##   (`1.06×` e `-12 px` no eixo Y) sem deslocar as cartas vizinhas na fileira.
## - Todos os nós internos usam `MOUSE_FILTER_IGNORE` e zero string literal visível.

const LARGURA_PADRAO: float = 320.0
const ALTURA_PADRAO: float = 500.0

var _dados: DadosDaCarta = null
var _em_foco: bool = false
var _tuning: TelaBencaoTuning = TelaBencaoTuning.new()
var _reduzir_movimento: bool = false
var _alto_contraste: bool = false

var _zona_moldura: TextureRect = null
var _zona_glifo: TextureRect = null
var _zona_ilustracao: TextureRect = null
var _zona_titulo: Label = null
var _zona_corpo: Label = null
var _zona_rodape_preco: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(LARGURA_PADRAO, ALTURA_PADRAO)
	size = Vector2(LARGURA_PADRAO, ALTURA_PADRAO)
	pivot_offset = Vector2(LARGURA_PADRAO * 0.5, ALTURA_PADRAO * 0.5)
	offset_transform_enabled = true
	offset_transform_visual_only = true
	_construir_zonas_se_necessario()


func configurar_carta(
	dados: DadosDaCarta,
	tuning: TelaBencaoTuning = null,
	reduzir_movimento: bool = false,
	alto_contraste: bool = false
) -> void:
	_dados = dados
	if tuning != null:
		_tuning = tuning
	_reduzir_movimento = reduzir_movimento
	_alto_contraste = alto_contraste
	_construir_zonas_se_necessario()
	_aplicar_dados_nas_6_zonas()
	aplicar_estado_foco(_em_foco)


func aplicar_estado_foco(focado: bool) -> void:
	_em_foco = focado
	offset_transform_enabled = true
	offset_transform_visual_only = true
	if focado:
		var esc: float = 1.0 if _reduzir_movimento else _tuning.foco_escala
		var dy: float = 0.0 if _reduzir_movimento else -_tuning.foco_subida_px
		offset_transform_scale = Vector2(esc, esc)
		offset_transform_offset = Vector2(0.0, dy)
	else:
		offset_transform_scale = Vector2.ONE
		offset_transform_offset = Vector2.ZERO


func esta_em_foco() -> bool:
	return _em_foco


func dados() -> DadosDaCarta:
	return _dados


func _aplicar_dados_nas_6_zonas() -> void:
	if _dados == null:
		return
	if _dados.caminho_moldura != "" and ResourceLoader.exists(_dados.caminho_moldura):
		_zona_moldura.texture = load(_dados.caminho_moldura) as Texture2D
	if _dados.caminho_glifo != "" and ResourceLoader.exists(_dados.caminho_glifo):
		_zona_glifo.texture = load(_dados.caminho_glifo) as Texture2D
	if _dados.caminho_ilustracao != "" and ResourceLoader.exists(_dados.caminho_ilustracao):
		_zona_ilustracao.texture = load(_dados.caminho_ilustracao) as Texture2D
		_zona_ilustracao.visible = true
	else:
		_zona_ilustracao.visible = false

	_zona_titulo.text = tr(String(_dados.chave_titulo)) if _dados.chave_titulo != &"" else ""
	_zona_corpo.text = tr(String(_dados.chave_corpo)) if _dados.chave_corpo != &"" else ""

	if _dados.preco_vida > 0 and _dados.chave_preco != &"":
		_zona_rodape_preco.text = "%s: -%d" % [tr(String(_dados.chave_preco)), _dados.preco_vida]
		_zona_rodape_preco.visible = true
	elif _dados.aviso_texto != &"":
		_zona_rodape_preco.text = tr(String(_dados.aviso_texto))
		_zona_rodape_preco.visible = true
	else:
		_zona_rodape_preco.text = ""
		_zona_rodape_preco.visible = false


func _construir_zonas_se_necessario() -> void:
	if _zona_moldura != null:
		return
	_zona_moldura = TextureRect.new()
	_zona_moldura.name = "Zona1_Moldura"
	_zona_moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zona_moldura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_zona_moldura)

	_zona_glifo = TextureRect.new()
	_zona_glifo.name = "Zona2_GlifoDoutrina"
	_zona_glifo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zona_glifo.position = Vector2(24.0, 20.0)
	_zona_glifo.size = Vector2(36.0, 36.0)
	add_child(_zona_glifo)

	_zona_ilustracao = TextureRect.new()
	_zona_ilustracao.name = "Zona3_Ilustracao"
	_zona_ilustracao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zona_ilustracao.position = Vector2(96.0, 68.0)
	_zona_ilustracao.size = Vector2(128.0, 128.0)
	add_child(_zona_ilustracao)

	_zona_titulo = Label.new()
	_zona_titulo.name = "Zona4_Titulo"
	_zona_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zona_titulo.position = Vector2(24.0, 212.0)
	_zona_titulo.size = Vector2(272.0, 40.0)
	add_child(_zona_titulo)

	_zona_corpo = Label.new()
	_zona_corpo.name = "Zona5_CorpoRegra"
	_zona_corpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zona_corpo.autowrap_mode = TextServer.AutowrapMode.AUTOWRAP_WORD_SMART
	_zona_corpo.position = Vector2(24.0, 260.0)
	_zona_corpo.size = Vector2(272.0, 160.0)
	add_child(_zona_corpo)

	_zona_rodape_preco = Label.new()
	_zona_rodape_preco.name = "Zona6_RodapePrecoAviso"
	_zona_rodape_preco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zona_rodape_preco.position = Vector2(24.0, 436.0)
	_zona_rodape_preco.size = Vector2(272.0, 40.0)
	add_child(_zona_rodape_preco)
