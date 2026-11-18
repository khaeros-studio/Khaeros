class_name TelaDeErrosDoCatalogo
extends Control
## Tela de Erros do Catálogo (design/ux/tela-erros-do-catalogo.md; GDD de Conteúdo R4,
## R7, R9; ADR-0004; ADR-0006 "Sem catálogo"; ADR-0012; story 009).
## Exibida quando [CarregadorDeCatalogo] entra em [code]FALHOU[/code]. Bloqueia o
## início de qualquer partida, lista todos os erros (primeiro) e avisos (depois),
## opera exclusivamente com entradas digitais (D-pad e teclado, ignorando analógicos)
## e traz textos fixos de apoio em PT-BR caso a tabela de localização tenha falhado.
##
## Exemplo:
## [codeblock]
## var tela := TelaDeErrosDoCatalogo.new()
## tela.configurar(carregador.diagnosticos(), true)
## [/codeblock]

signal copiar_solicitado(relatorio: String)
signal recarregar_solicitado
signal sair_solicitado

## Paleta da Bíblia de Arte (design/ux/tela-erros-do-catalogo.md §3).
const COR_FUNDO := Color("#0D0E14")
const COR_FUNDO_LISTA := Color(0.051, 0.055, 0.078, 0.92)
const COR_MOLDURA := Color("#CFC6B4")
const COR_DIVISOR := Color(0.812, 0.776, 0.706, 0.30)
const COR_TEXTO := Color("#E6DFCF")
const COR_TEXTO_SECUNDARIO := Color("#CFC6B4")
const COR_ERRO := Color("#E0259C")
const COR_AVISO := Color("#CFC6B4")

const PASSO_ROLAGEM_PX := 48

## Textos fixos em PT-BR caso a tabela de tradução não tenha carregado (exceção da R7).
const TEXTOS_APOIO: Dictionary[String, String] = {
	"CATALOGO_ERRO_TITULO": "Catálogo de dados inválido — a partida não pode começar.",
	"CATALOGO_ERRO_CONTAGEM": "%d erros · %d avisos",
	"CATALOGO_ERRO_COPIAR": "Copiar relatório",
	"CATALOGO_ERRO_COPIADO": "Copiado",
	"CATALOGO_ERRO_RECARREGAR": "Recarregar catálogo",
	"CATALOGO_ERRO_SAIR": "Sair",
	"CATALOGO_ERRO_VAZIO": "Falha ao abrir o manifesto do catálogo.",
}


## Porta de área de transferência injetável para testes sem depender do SO.
class PortaDaAreaDeTransferencia:
	extends RefCounted
	var ultimo_texto: String = ""
	var chamadas: int = 0

	func copiar(texto: String) -> void:
		ultimo_texto = texto
		chamadas += 1
		DisplayServer.clipboard_set(texto)


var _diagnosticos: Array[Diagnostico] = []
var _diagnosticos_ordenados: Array[Diagnostico] = []
var _debug_build: bool = OS.is_debug_build()
var _porta_transferencia: PortaDaAreaDeTransferencia = PortaDaAreaDeTransferencia.new()
var _ao_recarregar: Callable = Callable()
var _ao_sair: Callable = Callable()
var _indice_foco: int = 0
var _rolagem_y: int = 0

var _lbl_titulo: Label
var _lbl_contagem: Label
var _scroll: ScrollContainer
var _lista_box: VBoxContainer
var _btn_copiar: Button
var _btn_recarregar: Button
var _btn_sair: Button
var _botoes_ativos: Array[Button] = []


func _init(
	porta_transferencia: PortaDaAreaDeTransferencia = null,
	debug_build: bool = OS.is_debug_build()
) -> void:
	if porta_transferencia != null:
		_porta_transferencia = porta_transferencia
	_debug_build = debug_build
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = Vector2(1280, 720)
	_construir_arvore()
	_atualizar_rodape()


func _ready() -> void:
	set_process_input(true)
	_aplicar_foco_visual()


## Define a porta de área de transferência (para testes unitários).
func definir_porta_transferencia(porta: PortaDaAreaDeTransferencia) -> void:
	_porta_transferencia = porta


## Define callbacks para os botões de recarga e saída.
func definir_callbacks(ao_recarregar: Callable = Callable(), ao_sair: Callable = Callable()) -> void:
	_ao_recarregar = ao_recarregar
	_ao_sair = ao_sair


## Configura a tela com a lista de diagnósticos e a flag de build de debug.
func configurar(diagnosticos: Array[Diagnostico], debug_build: bool = _debug_build) -> void:
	_debug_build = debug_build
	_diagnosticos = diagnosticos.duplicate()
	_diagnosticos_ordenados = _ordenar_erros_primeiro(_diagnosticos)
	_rolagem_y = 0
	if _scroll != null:
		_scroll.scroll_vertical = 0
	_atualizar_cabecalho()
	_reconstruir_lista()
	_atualizar_rodape()


## Diagnósticos exibidos na tela (erros primeiro, avisos depois).
func diagnosticos_exibidos() -> Array[Diagnostico]:
	return _diagnosticos_ordenados.duplicate()


## Texto completo do relatório pronto para copiar (mesmo formato do console, 1 linha por item).
func texto_do_relatorio() -> String:
	if _diagnosticos_ordenados.is_empty():
		return _traduzir("CATALOGO_ERRO_VAZIO")
	var linhas := PackedStringArray()
	for d in _diagnosticos_ordenados:
		linhas.append(d.texto())
	return "\n".join(linhas)


## Botões atualmente visíveis e focáveis no rodapé.
func botoes_visiveis() -> Array[Button]:
	return _botoes_ativos.duplicate()


## Índice do botão atualmente focado em [method botoes_visiveis].
func indice_foco() -> int:
	return _indice_foco


## Botão atualmente focado.
func botao_focado() -> Button:
	if _botoes_ativos.is_empty():
		return null
	return _botoes_ativos[clampi(_indice_foco, 0, _botoes_ativos.size() - 1)]


## Posição vertical atual da rolagem da lista em pixels.
func rolagem_vertical() -> int:
	return _rolagem_y


## Processa entradas exclusivamente digitais (D-pad / teclado), ignorando analógicos (AC-51).
func _input(event: InputEvent) -> void:
	if processar_evento_entrada(event):
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()


## Retorna [code]true[/code] se o evento foi consumido pela tela.
## Eventos de movimento analógico do gamepad são sempre ignorados (modo "Sem catálogo", ADR-0006).
func processar_evento_entrada(event: Object) -> bool:
	if event == null:
		return false
	var classe_ev: String = event.get_class()
	if classe_ev.ends_with("JoypadMotion"):
		return false
	if classe_ev.ends_with("Key"):
		var pressionado := bool(event.get("pressed"))
		var eco := bool(event.get("echo"))
		if not pressionado or eco:
			return false
		var codigo_tecla := int(event.get("keycode"))
		match codigo_tecla:
			KEY_UP, KEY_W:
				rolar_lista(-1)
				return true
			KEY_DOWN, KEY_S:
				rolar_lista(1)
				return true
			KEY_LEFT, KEY_A:
				mover_foco(-1)
				return true
			KEY_RIGHT, KEY_D:
				mover_foco(1)
				return true
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
				ativar_botao_focado()
				return true
			KEY_C:
				acionar_copiar()
				return true
			KEY_R:
				if _debug_build:
					acionar_recarregar()
					return true
				return false
			KEY_ESCAPE:
				# ui_voltar não faz nada: não há como iniciar run nem fechar a tela.
				return true
	if classe_ev.ends_with("JoypadButton"):
		var btn_pressionado := bool(event.get("pressed"))
		if not btn_pressionado:
			return false
		var indice_botao := int(event.get("button_index"))
		match indice_botao:
			JOY_BUTTON_DPAD_UP:
				rolar_lista(-1)
				return true
			JOY_BUTTON_DPAD_DOWN:
				rolar_lista(1)
				return true
			JOY_BUTTON_DPAD_LEFT:
				mover_foco(-1)
				return true
			JOY_BUTTON_DPAD_RIGHT:
				mover_foco(1)
				return true
			JOY_BUTTON_A:
				ativar_botao_focado()
				return true
			JOY_BUTTON_X:
				acionar_copiar()
				return true
			JOY_BUTTON_Y:
				if _debug_build:
					acionar_recarregar()
					return true
				return false
			JOY_BUTTON_B:
				return true
	return false


## Rola a lista de diagnósticos verticalmente ([param direcao] < 0 sobe, > 0 desce).
func rolar_lista(direcao: int) -> void:
	_rolagem_y = maxi(0, _rolagem_y + direcao * PASSO_ROLAGEM_PX)
	if _scroll != null:
		_scroll.scroll_vertical = _rolagem_y


## Move o foco horizontalmente entre os botões visíveis do rodapé.
func mover_foco(delta: int) -> void:
	if _botoes_ativos.is_empty():
		return
	var n := _botoes_ativos.size()
	_indice_foco = posmod(_indice_foco + delta, n)
	_aplicar_foco_visual()


## Ativa o botão atualmente focado no rodapé.
func ativar_botao_focado() -> void:
	var btn := botao_focado()
	if btn == null:
		return
	if btn == _btn_copiar:
		acionar_copiar()
	elif btn == _btn_recarregar:
		acionar_recarregar()
	elif btn == _btn_sair:
		acionar_sair()


## Copia o relatório completo para a área de transferência.
func acionar_copiar() -> void:
	var rel := texto_do_relatorio()
	if _porta_transferencia != null:
		_porta_transferencia.copiar(rel)
	if _btn_copiar != null:
		_btn_copiar.text = _traduzir("CATALOGO_ERRO_COPIADO")
	copiar_solicitado.emit(rel)


## Solicita a recarga do catálogo (apenas em build de debug).
func acionar_recarregar() -> void:
	if not _debug_build:
		return
	if _ao_recarregar.is_valid():
		_ao_recarregar.call()
	recarregar_solicitado.emit()


## Solicita o encerramento do jogo.
func acionar_sair() -> void:
	if _ao_sair.is_valid():
		_ao_sair.call()
	sair_solicitado.emit()


static func _ordenar_erros_primeiro(lista: Array[Diagnostico]) -> Array[Diagnostico]:
	var erros: Array[Diagnostico] = []
	var avisos: Array[Diagnostico] = []
	for d in lista:
		if d.e_erro():
			erros.append(d)
		else:
			avisos.append(d)
	var out: Array[Diagnostico] = []
	out.append_array(erros)
	out.append_array(avisos)
	return out


static func _traduzir(chave: String) -> String:
	var tr_val := TranslationServer.translate(chave)
	if tr_val != "" and tr_val != chave:
		return tr_val
	return TEXTOS_APOIO.get(chave, chave)


func _construir_arvore() -> void:
	var fundo := ColorRect.new()
	fundo.name = "Fundo"
	fundo.color = COR_FUNDO
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var margem := MarginContainer.new()
	margem.name = "MargemSegura"
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 96)
	margem.add_theme_constant_override("margin_right", 96)
	margem.add_theme_constant_override("margin_top", 48)
	margem.add_theme_constant_override("margin_bottom", 48)
	add_child(margem)

	var moldura := PanelContainer.new()
	moldura.name = "Moldura"
	var estilo_moldura := StyleBoxFlat.new()
	estilo_moldura.bg_color = COR_FUNDO_LISTA
	estilo_moldura.border_color = COR_MOLDURA
	estilo_moldura.set_border_width_all(3)
	estilo_moldura.set_content_margin_all(24)
	moldura.add_theme_stylebox_override("panel", estilo_moldura)
	margem.add_child(moldura)

	var coluna := VBoxContainer.new()
	coluna.name = "ColunaPrincipal"
	coluna.add_theme_constant_override("separation", 16)
	moldura.add_child(coluna)

	# Cabeçalho (64 px)
	var cabecalho := HBoxContainer.new()
	cabecalho.name = "Cabecalho"
	cabecalho.custom_minimum_size = Vector2(0, 64)
	coluna.add_child(cabecalho)

	_lbl_titulo = Label.new()
	_lbl_titulo.name = "Titulo"
	_lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_titulo.add_theme_font_size_override("font_size", 28)
	_lbl_titulo.add_theme_color_override("font_color", COR_ERRO)
	cabecalho.add_child(_lbl_titulo)

	_lbl_contagem = Label.new()
	_lbl_contagem.name = "Contagem"
	_lbl_contagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_contagem.add_theme_font_size_override("font_size", 20)
	_lbl_contagem.add_theme_color_override("font_color", COR_TEXTO_SECUNDARIO)
	cabecalho.add_child(_lbl_contagem)

	var sep_topo := HSeparator.new()
	sep_topo.add_theme_color_override("separator", COR_MOLDURA)
	coluna.add_child(sep_topo)

	# Corpo rolável (480 px)
	_scroll = ScrollContainer.new()
	_scroll.name = "CorpoRolavel"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = Vector2(0, 440)
	coluna.add_child(_scroll)

	_lista_box = VBoxContainer.new()
	_lista_box.name = "ListaDiagnosticos"
	_lista_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista_box.add_theme_constant_override("separation", 12)
	_scroll.add_child(_lista_box)

	var sep_base := HSeparator.new()
	sep_base.add_theme_color_override("separator", COR_MOLDURA)
	coluna.add_child(sep_base)

	# Rodapé (64 px)
	var rodape := HBoxContainer.new()
	rodape.name = "Rodape"
	rodape.custom_minimum_size = Vector2(0, 64)
	rodape.alignment = BoxContainer.ALIGNMENT_END
	rodape.add_theme_constant_override("separation", 16)
	coluna.add_child(rodape)

	_btn_copiar = _criar_botao("BtnCopiar", _traduzir("CATALOGO_ERRO_COPIAR"), acionar_copiar)
	_btn_recarregar = _criar_botao("BtnRecarregar", _traduzir("CATALOGO_ERRO_RECARREGAR"), acionar_recarregar)
	_btn_sair = _criar_botao("BtnSair", _traduzir("CATALOGO_ERRO_SAIR"), acionar_sair)

	rodape.add_child(_btn_copiar)
	rodape.add_child(_btn_recarregar)
	rodape.add_child(_btn_sair)

	_atualizar_cabecalho()
	_reconstruir_lista()


func _criar_botao(nome_no: String, rotulo_texto: String, callback: Callable) -> Button:
	var b := Button.new()
	b.name = nome_no
	b.text = rotulo_texto
	b.custom_minimum_size = Vector2(220, 48)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", COR_TEXTO)
	var est_normal := StyleBoxFlat.new()
	est_normal.bg_color = COR_FUNDO
	est_normal.border_color = COR_MOLDURA
	est_normal.set_border_width_all(2)
	est_normal.set_content_margin_all(10)
	var est_foco := StyleBoxFlat.new()
	est_foco.bg_color = Color(0.14, 0.10, 0.18, 1.0)
	est_foco.border_color = COR_ERRO
	est_foco.set_border_width_all(3)
	est_foco.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", est_normal)
	b.add_theme_stylebox_override("hover", est_foco)
	b.add_theme_stylebox_override("focus", est_foco)
	b.pressed.connect(callback)
	return b


func _atualizar_cabecalho() -> void:
	if _lbl_titulo == null or _lbl_contagem == null:
		return
	_lbl_titulo.text = _traduzir("CATALOGO_ERRO_TITULO")
	var n_erros := Diagnostico.contar_erros(_diagnosticos_ordenados)
	var n_avisos := _diagnosticos_ordenados.size() - n_erros
	_lbl_contagem.text = _traduzir("CATALOGO_ERRO_CONTAGEM") % [n_erros, n_avisos]


func _reconstruir_lista() -> void:
	if _lista_box == null:
		return
	for filho in _lista_box.get_children():
		_lista_box.remove_child(filho)
		filho.free()
	if _diagnosticos_ordenados.is_empty():
		var vazio := Label.new()
		vazio.name = "MensagemVazia"
		vazio.text = _traduzir("CATALOGO_ERRO_VAZIO")
		vazio.add_theme_font_size_override("font_size", 16)
		vazio.add_theme_color_override("font_color", COR_TEXTO)
		_lista_box.add_child(vazio)
		return
	for i in _diagnosticos_ordenados.size():
		var d := _diagnosticos_ordenados[i]
		var item_box := VBoxContainer.new()
		item_box.name = "ItemDiagnostico_%d" % i
		item_box.add_theme_constant_override("separation", 4)

		var l1 := Label.new()
		l1.name = "LinhaCabecalho"
		var selo := "[✖ ERRO]" if d.e_erro() else "[▲ AVISO]"
		var ident := String(d.tipo) if d.id == &"" else "%s (%s)" % [d.tipo, d.id]
		if ident.is_empty():
			ident = "Catálogo"
		l1.text = "%s [%s]  %s — %s" % [selo, d.regra, ident, d.arquivo]
		l1.add_theme_font_size_override("font_size", 16)
		l1.add_theme_color_override("font_color", COR_ERRO if d.e_erro() else COR_AVISO)
		item_box.add_child(l1)

		var l2 := Label.new()
		l2.name = "LinhaDetalhe"
		var cpo := d.campo if not d.campo.is_empty() else "(recurso)"
		l2.text = "    %s: %s  —  %s" % [cpo, str(d.valor), d.mensagem]
		l2.add_theme_font_size_override("font_size", 15)
		l2.add_theme_color_override("font_color", COR_TEXTO)
		item_box.add_child(l2)

		var div := HSeparator.new()
		div.add_theme_color_override("separator", COR_DIVISOR)
		item_box.add_child(div)

		_lista_box.add_child(item_box)


func _atualizar_rodape() -> void:
	if _btn_copiar == null or _btn_recarregar == null or _btn_sair == null:
		return
	_btn_copiar.text = _traduzir("CATALOGO_ERRO_COPIAR")
	_btn_recarregar.text = _traduzir("CATALOGO_ERRO_RECARREGAR")
	_btn_sair.text = _traduzir("CATALOGO_ERRO_SAIR")
	_btn_recarregar.visible = _debug_build
	_btn_recarregar.focus_mode = Control.FOCUS_ALL if _debug_build else Control.FOCUS_NONE
	_botoes_ativos = [_btn_copiar]
	if _debug_build:
		_botoes_ativos.append(_btn_recarregar)
	_botoes_ativos.append(_btn_sair)
	_indice_foco = clampi(_indice_foco, 0, _botoes_ativos.size() - 1)
	_aplicar_foco_visual()


func _aplicar_foco_visual() -> void:
	var focado := botao_focado()
	if focado != null and focado.is_inside_tree():
		focado.grab_focus()
