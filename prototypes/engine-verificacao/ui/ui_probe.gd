# PROTOTYPE - NOT FOR PRODUCTION (EX-0012, story-008)
## E1 offset_transform x acerto; E2 ações ui_* esvaziadas x LineEdit; E4/E5 nomes via ClassDB;
## E6 plurais/contexto em CSV; CB clipboard. Arg: --evid=<pasta absoluta para PNG>. --modo=cb só clipboard.
extends Control

const APAGAR := ["ui_accept", "ui_select", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right", "ui_focus_next", "ui_focus_prev"]

var _evid := ""
var _modo := "tudo"
var _acertos: Array[String] = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--evid="):
			_evid = a.substr(7)
		if a.begins_with("--modo="):
			_modo = a.substr(7)
	print("EX|engine ", Engine.get_version_info().string)
	_clipboard()
	if _modo == "cb":
		get_tree().quit()
		return
	_nomes()
	_i18n()
	await _e1()
	await _e2()
	get_tree().quit()


func _clipboard() -> void:
	var seed_hex := "9f3a00c1d2e4b5a6"
	print("EX|cb has_feature(CLIPBOARD)=", DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD))
	DisplayServer.clipboard_set(seed_hex)
	print("EX|cb set '", seed_hex, "' get='", DisplayServer.clipboard_get(), "' igual=", DisplayServer.clipboard_get() == seed_hex)


func _nomes() -> void:
	var achados: Array[String] = []
	for p in ClassDB.class_get_property_list("Control", true):
		var n: String = p["name"]
		if n.contains("recursive") or n.begins_with("accessibility_") or n.begins_with("offset_transform"):
			achados.append(n)
	print("EX|nomes Control: ", achados)


func _i18n() -> void:
	for loc in ["en", "pt_BR"]:
		TranslationServer.set_locale(loc)
		print("EX|i18n locale=", loc, " tr_n(ITEM,ITEMS,1)='", tr_n("ITEM", "ITEMS", 1), "' n=2 '", tr_n("ITEM", "ITEMS", 2),
			"' n=0 '", tr_n("ITEM", "ITEMS", 0), "' tr(ABRIR,menu)='", tr("ABRIR", "menu"), "' tr(ABRIR,porta)='", tr("ABRIR", "porta"), "'")
	for arq in ["res://i18n/plural.en.translation", "res://i18n/plural.pt_BR.translation"]:
		if ResourceLoader.exists(arq):
			var t := load(arq) as Translation
			print("EX|i18n ", arq, " classe=", t.get_class(), " msgs=", t.get_message_list())
		else:
			print("EX|i18n ", arq, " AUSENTE")


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	if _evid != "":
		var img := get_viewport().get_texture().get_image()
		print("EX|foto ", nome, " save=", img.save_png(_evid.path_join(nome)))


func _clique(pos: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		get_viewport().push_input(ev)
	await get_tree().process_frame


func _marca(pos: Vector2, cor: Color) -> ColorRect:
	var m := ColorRect.new()
	m.color = cor
	m.size = Vector2(6, 6)
	m.position = pos - Vector2(3, 3)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	return m


func _e1() -> void:
	var caixa := HBoxContainer.new()
	caixa.position = Vector2(40, 60)
	add_child(caixa)
	var botoes: Array[Button] = []
	for nome in ["A", "B", "C"]:
		var b := Button.new()
		b.text = nome
		b.custom_minimum_size = Vector2(100, 50)
		b.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed:
				_acertos.append(nome))
		caixa.add_child(b)
		botoes.append(b)
	var b := botoes[1]
	var casos := [
		["c0_sem_offset", false, Vector2.ZERO, Vector2.ONE, true],
		["c1_pos60x80_visual", true, Vector2(60, 80), Vector2.ONE, true],
		["c2_escala1.5_visual", true, Vector2.ZERO, Vector2(1.5, 1.5), true],
		["c3_pos60x80_nao_visual", true, Vector2(60, 80), Vector2.ONE, false],
	]
	for c in casos:
		b.offset_transform_enabled = c[1]
		b.offset_transform_position = c[2]
		b.offset_transform_scale = c[3]
		b.offset_transform_visual_only = c[4]
		await get_tree().process_frame
		await get_tree().process_frame
		var rect_layout := Rect2(caixa.position + b.position, b.size)
		var centro_layout := rect_layout.get_center()
		var centro_visual := b.get_global_transform_with_canvas() * (b.size / 2.0)
		var m1 := _marca(centro_layout, Color.RED)
		var m2 := _marca(centro_visual, Color.GREEN)
		_acertos.clear()
		await _clique(centro_layout)
		var a1 := _acertos.duplicate()
		_acertos.clear()
		await _clique(centro_visual)
		var a2 := _acertos.duplicate()
		print("EX|e1 ", c[0], " b.position=", b.position, " get_global_rect=", b.get_global_rect(),
			" gtwc.origin=", b.get_global_transform_with_canvas().origin, " gtwc.scale=", b.get_global_transform_with_canvas().get_scale(),
			" clique_centro_layout", centro_layout, "->", a1, " clique_centro_visual", centro_visual, "->", a2)
		await _foto("ex-0012-e1-%s.png" % c[0])
		m1.queue_free()
		m2.queue_free()
	caixa.queue_free()


func _tecla(kc: Key, uni: int = 0, shift: bool = false, ctrl: bool = false) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = kc
		ev.physical_keycode = kc
		ev.unicode = uni if pressed else 0
		ev.shift_pressed = shift
		ev.ctrl_pressed = ctrl
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame
		await get_tree().process_frame


func _e2() -> void:
	for acao in APAGAR:
		InputMap.action_erase_events(acao)
	var resto: Array[String] = []
	for acao in InputMap.get_actions():
		if String(acao).begins_with("ui_text") and not InputMap.action_get_events(acao).is_empty():
			resto.append(String(acao))
	print("EX|e2 apagadas=", APAGAR, " eventos_restantes(ui_accept)=", InputMap.action_get_events("ui_accept").size(), " ui_text_* com eventos=", resto.size())
	var le := LineEdit.new()
	le.position = Vector2(40, 60)
	le.size = Vector2(400, 40)
	add_child(le)
	var enviados: Array[String] = []
	le.text_submitted.connect(func(t: String) -> void: enviados.append(t))
	le.grab_focus()
	await get_tree().process_frame
	for ch in "abcd":
		await _tecla(OS.find_keycode_from_string(ch.to_upper()), ch.unicode_at(0))
	print("EX|e2 digitar text='", le.text, "' caret=", le.caret_column)
	await _tecla(KEY_LEFT)
	await _tecla(KEY_LEFT)
	print("EX|e2 seta_esq x2 caret=", le.caret_column)
	await _tecla(KEY_BACKSPACE)
	print("EX|e2 backspace text='", le.text, "' caret=", le.caret_column)
	await _tecla(KEY_END, 0, true)
	print("EX|e2 shift+end selecionado='", le.get_selected_text(), "'")
	await _foto("ex-0012-e2-selecao.png")
	await _tecla(KEY_DELETE)
	print("EX|e2 delete text='", le.text, "'")
	await _tecla(KEY_A, 0, false, true)
	print("EX|e2 ctrl+a selecionado='", le.get_selected_text(), "'")
	await _tecla(KEY_X, "x".unicode_at(0))
	await _tecla(KEY_HOME)
	print("EX|e2 home caret=", le.caret_column, " text='", le.text, "'")
	await _tecla(KEY_ENTER)
	print("EX|e2 enter text_submitted=", enviados, " foco_ainda_no_lineedit=", le.has_focus())
	await _tecla(KEY_TAB)
	print("EX|e2 tab (ui_focus_next vazio) foco_no_lineedit=", le.has_focus())
	await _foto("ex-0012-e2-final.png")
