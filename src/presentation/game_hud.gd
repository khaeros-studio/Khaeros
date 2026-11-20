extends Node2D
## Screen-fixed Portuguese UI with one focus shared by mouse and keyboard/gamepad.

const BONE := Color("e2dccb")
const MUTED := Color("9693a2")
const GOLD := Color("d7b778")
const PINK := Color("ed618f")
const CYAN := Color("38bdf8")
const VIOLET := Color("a855f7")
const PANEL := Color("11151f")
var app: Node
var font: Font = ThemeDB.fallback_font
var _ui_tex: Dictionary = {}
var _ui_loaded: bool = false

func _garantir_texturas_ui() -> void:
	if _ui_loaded:
		return
	_ui_loaded = true
	var mapas: Dictionary = {
		"moldura_comum": "res://assets/art/ui/cartas/moldura_comum.png",
		"moldura_rara": "res://assets/art/ui/cartas/moldura_rara.png",
		"moldura_epica": "res://assets/art/ui/cartas/moldura_epica.png",
		"coroa_lamina": "res://assets/art/ui/cartas/coroa_lamina.png",
		"coroa_ressonancia": "res://assets/art/ui/cartas/coroa_ressonancia.png",
		"coroa_pactos": "res://assets/art/ui/cartas/coroa_pactos.png",
		"silhueta_vulto": "res://assets/art/ui/maldicoes/silhueta_vulto_mudo_72.png",
		"icone_fragmento": "res://assets/art/ui/hud/icone_fragmento.png",
		"gota_fluxo": "res://assets/art/ui/hud/gota_fluxo.png",
		"mestre_halvar": "res://assets/art/ui/mestres/halvar.png",
		"mestre_maren": "res://assets/art/ui/mestres/maren.png",
		"mestre_oreth": "res://assets/art/ui/mestres/oreth.png",
		"prologo_01": "res://assets/art/ui/historia/prologo_01.png",
		"prologo_02": "res://assets/art/ui/historia/prologo_02.png",
	}
	for k: String in mapas.keys():
		var path: String = String(mapas[k])
		if ResourceLoader.exists(path):
			var t := load(path) as Texture2D
			if t != null:
				_ui_tex[k] = t
				continue
		if FileAccess.file_exists(path):
			var img := Image.load_from_file(path)
			if img != null and not img.is_empty():
				_ui_tex[k] = ImageTexture.create_from_image(img)

func _nome_doutrina() -> String:
	var w := StringName(&"lamina")
	if app != null and app.get("selected_weapon") != null:
		w = app.get("selected_weapon")
	match w:
		&"ressonancia":
			return "Ressonância de Sangue"
		&"pactos":
			return "Domador de Pactos"
		&"guardiao":
			return "Égide do Guardião"
		&"veu":
			return "Lâminas do Véu"
		_:
			return "Lâmina do Juramento"

func _nome_regiao_inicial() -> String:
	var idx: int = int(app.get("selected_region_index")) if app != null and app.get("selected_region_index") != null else 0
	var regioes: Array[Dictionary] = CatalogoCampanha.regioes()
	if idx >= 0 and idx < regioes.size():
		return String(regioes[idx].get("nome", "O Limiar"))
	return "O Limiar"

## Logical viewport rectangles shared by drawing, hover and confirmation.
func action_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	if app == null or not app.ready_to_play:
		return result
	var center: float = app.camera.width / 2
	match app.session.state:
		"menu":
			for i: int in range(7):
				result.append(Rect2(center - 240.0, 466.0 + float(i) * 54.0, 480.0, 46.0))
		"codex":
			for i: int in range(4):
				result.append(Rect2(center - 440.0 + float(i) * 224.0, 150.0, 212.0, 48.0))
			result.append(Rect2(center - 160.0, 930.0, 320.0, 52.0))
		"oficina":
			for i in range(5):
				result.append(Rect2(center-340, 305 + i * 86, 680, 72))
			result.append(Rect2(center-220, 765, 440, 62))
		"pausa":
			result = [Rect2(center-240,470,480,74),Rect2(center-240,570,480,64),Rect2(center-240,660,480,64)]
		"morte", "vitoria":
			result = [Rect2(center-240,570,480,74),Rect2(center-240,667,480,64)]
		"bencao":
			for i in range(3):
				result.append(Rect2(center-650+i*450,340,400,420))
	return result

func _draw() -> void:
	if app == null:
		return
	if not app.ready_to_play:
		draw_rect(Rect2(0,0,3000,1080),PANEL)
		_text("Não foi possível abrir Khaeros",Vector2(100,180),42,BONE)
		_wrapped(app.data_error,Rect2(100,240,1500,500),25,PINK)
		return
	_garantir_texturas_ui()
	var width: float = app.camera.width
	var state: String = app.session.state
	var intro_t: float = float(app.get("boss_intro_timer")) if app.get("boss_intro_timer") != null else 0.0
	var intro_ativa: bool = intro_t > 0.0 and state == "jogo"
	if not state in ["menu", "campus", "mestres", "prologo", "codex"] and not intro_ativa:
		_status(width)
	if state == "jogo":
		if intro_ativa:
			_draw_boss_intro(width, intro_t)
		else:
			_controls(width)
			var domain_t: float = float(app.get("domain_banner_timer")) if app.get("domain_banner_timer") != null else 0.0
			if domain_t > 0.0:
				_draw_domain_banner(width, domain_t)
			var door_idx: int = int(app.session.get("active_door_index")) if app.session.get("active_door_index") != null else -1
			var inter_idx: int = int(app.session.get("active_interactive_index")) if app.session.get("active_interactive_index") != null else -1
			var popup_ativo: bool = bool(app.get("lore_popup_ativo"))
			if (door_idx >= 0 or inter_idx >= 0) and not popup_ativo:
				_draw_interact_hint(width)
			if popup_ativo:
				_draw_lore_popup(width)
	elif state == "prologo":
		_draw_prologo(width)
	elif state == "codex":
		_draw_codex(width)
	elif state in ["campus", "mestres"]:
		_draw_campus_hud(width)
	elif state == "transicao":
		var progress: float = app.session.get("transition_progress")
		var opacity := 1.0-absf(progress*2-1)
		draw_rect(Rect2(0,0,width,1080),Color(PANEL,opacity))
	elif state in ["menu","pausa","bencao","morte","vitoria","oficina"]:
		draw_rect(Rect2(0,0,width,1080),Color(0.025,0.03,0.05,0.91 if state in ["menu","oficina"] else 0.85))
		var center := width/2
		match state:
			"menu":
				_center("K H A E R O S",230,80,BONE,width)
				_rule(center,272,300)
				_center("O LIMIAR",324,22,GOLD,width)
				_center(_nome_doutrina(),380,28,BONE,width)
				_center("Atravesse as câmaras das 4 Regiões. Escolha arma, bênçãos e pactos.",418,21,MUTED,width)
				var frag_saldo: int = app.saldo_fragmentos() if app.has_method("saldo_fragmentos") else 0
				var menu_boxes: Array[Rect2] = action_rects()
				_button(menu_boxes[0],"Entrar no Limiar",0)
				_button(menu_boxes[1],"Redução de movimento: "+("ligada" if app.reduced_motion else "desligada"),1,true)
				_button(menu_boxes[2],"Doutrina: "+_nome_doutrina(),2,true)
				_button(menu_boxes[3],"Oficina de Reforja (%d Frag.)" % frag_saldo,3,true)
				_button(menu_boxes[4],"Explorar Campus (Hub)",4,true)
				_button(menu_boxes[5],"Região Inicial: " + _nome_regiao_inicial(),5,true)
				_button(menu_boxes[6],"Grimório & História",6,true)
				var cat_ok := app.get("catalogo_real") != null
				_center("MVP KHAEROS • CATÁLOGO .TRES %s • 4 REGIÕES • 15 BÊNÇÃOS" % ["ATIVO" if cat_ok else "FALLBACK"],980,18,MUTED,width)
				_controls(width)
			"oficina":
				_center("OFICINA DE REFORJA", 160, 48, BONE, width)
				_rule(center, 195, 280)
				var frag_saldo: int = app.saldo_fragmentos() if app.has_method("saldo_fragmentos") else 0
				_center("Fragmentos disponíveis: %d" % frag_saldo, 245, 26, GOLD, width)
				var boxes := action_rects()
				var ids := OficinaDeReforja.ids_melhorias()
				var ofi: OficinaDeReforja = app.get("oficina") as OficinaDeReforja
				for i in range(ids.size()):
					var id_m: StringName = ids[i]
					var info: Dictionary = OficinaDeReforja.info_melhoria(id_m)
					var nv := ofi.nivel(id_m) if ofi != null else 0
					var max_nv := int(info.get("nivel_max", 1))
					var custo := ofi.custo_proximo(id_m) if ofi != null else 0
					var custo_txt := "MÁXIMO" if nv >= max_nv else ("%d Frag." % custo)
					var rotulo := "%s [%d/%d] — %s (%s)" % [
						String(info.get("nome", "")), nv, max_nv, String(info.get("descricao", "")), custo_txt
					]
					_button(boxes[i], rotulo, i, true)
				_button(boxes[ids.size()], "Voltar ao início", ids.size(), true)
			"pausa":
				_center("UMA PAUSA NA BEIRA",335,46,BONE,width)
				_center("O mundo espera por você.",390,24,MUTED,width)
				var boxes := action_rects()
				_button(boxes[0],"Continuar",0)
				_button(boxes[1],"Redução de movimento: "+("ligada" if app.reduced_motion else "desligada"),1,true)
				_button(boxes[2],"Voltar ao início",2,true)
			"bencao":
				_center("O QUE VOCÊ LEVA ADIANTE?",213,44,BONE,width)
				_center("Escolha uma bênção para continuar a travessia.",270,25,MUTED,width)
				for i in range(3):
					_card(action_rects()[i],i)
				_center("1 / 2 / 3 selecionam  •  Enter confirma  •  Esc pausa",835,22,MUTED,width)
				if app.screen_age < float(app.catalog.data.blessing_lock_s):
					_center("As marcas estão assentando…",885,20,GOLD,width)
			"morte":
				_center("A BEIRA FICOU COM VOCÊ",320,49,BONE,width)
				_rule(center,370,250)
				_center("Uma nova tentativa. Um novo juramento.",440,25,MUTED,width)
				_summary(width)
				_button(action_rects()[0],"Tentar novamente",0)
				_button(action_rects()[1],"Voltar ao início",1,true)
			"vitoria":
				_center("O SANTUÁRIO FOI ATRAVESSADO" if bool(app.session.get("extended_campaign")) else "O LIMIAR FOI ATRAVESSADO",320,49,BONE,width)
				_rule(center,370,250)
				_center("Você venceu os 4 Chefes desta campanha." if bool(app.session.get("extended_campaign")) else "Você venceu as três ondas desta travessia.",440,25,GOLD,width)
				_summary(width)
				_button(action_rects()[0],"Jogar novamente",0)
				_button(action_rects()[1],"Voltar ao início",1,true)
		if state != "bencao" and state != "menu":
			_center("Setas / direcional para escolher  •  Enter / A para confirmar",950,20,MUTED,width)

func _draw_campus_hud(width: float) -> void:
	draw_rect(Rect2(0, 0, width, 96), Color(0.035, 0.04, 0.065, 0.88))
	_text("CAMPUS DE KHAEROS", Vector2(60, 42), 24, GOLD)
	_text("Doutrina: " + _nome_doutrina(), Vector2(60, 74), 19, BONE)
	var frag_saldo: int = app.saldo_fragmentos() if app.has_method("saldo_fragmentos") else 0
	_text("Fragmentos: %d" % frag_saldo, Vector2(width - 260, 56), 22, GOLD)
	var campus: CampusHub = app.get("campus") as CampusHub
	if campus == null:
		return
	if bool(app.get("falar_mestre_ativo")):
		var fala: Dictionary = campus.fala_mestre_atual()
		var box := Rect2(width / 2.0 - 460.0, 690.0, 920.0, 260.0)
		draw_rect(box, Color(PANEL.r, PANEL.g, PANEL.b, 0.94))
		draw_rect(box, GOLD, false, 2.5)
		var m_id := String(fala.get("id", "halvar"))
		var m_tex: Texture2D = _ui_tex.get("mestre_" + m_id, null)
		var text_x := 36.0
		if m_tex != null:
			draw_texture_rect(m_tex, Rect2(box.position + Vector2(24, 24), Vector2(180, 180)), false)
			text_x = 224.0
		_text(String(fala.get("nome", "")), box.position + Vector2(text_x, 48), 30, GOLD)
		_text(String(fala.get("titulo", "")), box.position + Vector2(text_x, 80), 19, MUTED)
		_wrapped("\"%s\"" % String(fala.get("fala", "")), Rect2(box.position + Vector2(text_x, 108), Vector2(box.size.x - text_x - 36, 100)), 24, BONE)
		_center_in("[E / Enter] Próximo Mestre   •   [Esc] Fechar", box.end.y - 24, 18, MUTED, box)
	else:
		var focada := campus.zona_focada()
		if focada != &"":
			var nome_z := campus.nome_zona(focada)
			var prompt := "[E / Enter] Interagir: %s" % nome_z
			var p_box := Rect2(width / 2.0 - 280.0, 885.0, 560.0, 58.0)
			draw_rect(p_box, Color(PANEL.r, PANEL.g, PANEL.b, 0.92))
			draw_rect(p_box, GOLD, false, 2.0)
			_center_in(prompt, p_box.position.y + 38, 22, GOLD, p_box)
	draw_rect(Rect2(0, 1013, width, 67), Color(0.035, 0.04, 0.065, 0.93))
	_center("WASD / Setas  Mover     E / Enter  Interagir     Esc  Voltar ao Menu", 1054, 20, MUTED, width)


func _chefe_vivo() -> Dictionary:
	if app == null or app.session == null:
		return {}
	for e: Dictionary in app.session.enemies:
		if bool(e.get("is_boss", false)) and float(e.get("hp", 0.0)) > 0.0:
			return e
	return {}


func _draw_boss_intro(width: float, intro_t: float) -> void:
	var dur: float = maxf(0.01, float(app.get("boss_intro_duration")) if app.get("boss_intro_duration") != null else 2.6)
	var prog: float = clampf(1.0 - (intro_t / dur), 0.0, 1.0)
	var t_in: float = clampf(prog / 0.18, 0.0, 1.0)
	var ease_in: float = t_in * t_in * (3.0 - 2.0 * t_in)
	var t_out: float = clampf((1.0 - prog) / 0.16, 0.0, 1.0)
	var ease_out: float = t_out * t_out * (3.0 - 2.0 * t_out)
	var env: float = minf(ease_in, ease_out)
	var data_raw = app.get("boss_intro_data")
	var bdata: Dictionary = data_raw if data_raw is Dictionary else {}
	var b_nome: String = String(bdata.get("nome", "Chefe")).to_upper()
	var b_titulo: String = String(bdata.get("titulo", "ANOMALIA DO LIMIAR")).to_upper()
	var b_fala: String = String(bdata.get("fala", ""))
	var b_cor_raw = bdata.get("cor", GOLD)
	var b_cor: Color = b_cor_raw if b_cor_raw is Color else GOLD
	var center: float = width * 0.5
	# Barras cinematográficas (letterbox) deslizando no topo e na base
	var bar_h: float = 110.0 * env
	var bar_col := Color(0.015, 0.018, 0.028, 0.97)
	draw_rect(Rect2(0.0, 0.0, width, bar_h), bar_col)
	draw_rect(Rect2(0.0, 1080.0 - bar_h, width, bar_h), bar_col)
	draw_line(Vector2(0.0, bar_h), Vector2(width, bar_h), Color(b_cor, 0.35 * env), 1.5)
	draw_line(Vector2(0.0, 1080.0 - bar_h), Vector2(width, 1080.0 - bar_h), Color(b_cor, 0.35 * env), 1.5)
	# Envelope do banner central-inferior (surge logo após as barras)
	var b_in: float = clampf((prog - 0.06) / 0.20, 0.0, 1.0)
	var banner_alpha: float = minf(b_in * b_in * (3.0 - 2.0 * b_in), ease_out)
	if banner_alpha <= 0.01:
		return
	var slide_y: float = (1.0 - banner_alpha) * 18.0
	# Faixa escura sutil atrás do título/nome para máxima legibilidade
	var title_bg := Rect2(center - 470.0, 718.0 + slide_y, 940.0, 114.0)
	draw_rect(title_bg, Color(0.025, 0.028, 0.045, 0.68 * banner_alpha))
	# Título pequeno na cor do chefe
	_center(b_titulo, 748.0 + slide_y, 19, Color(b_cor, banner_alpha), width)
	# Linha dourada ornamentada expandindo do centro
	var line_prog: float = clampf((prog - 0.08) / 0.24, 0.0, 1.0)
	var half_line: float = 280.0 * (line_prog * line_prog * (3.0 - 2.0 * line_prog)) * env
	var line_y: float = 766.0 + slide_y
	if half_line > 14.0:
		draw_line(Vector2(center - half_line, line_y), Vector2(center - 12.0, line_y), Color(GOLD, 0.85 * banner_alpha), 1.8)
		draw_line(Vector2(center + 12.0, line_y), Vector2(center + half_line, line_y), Color(GOLD, 0.85 * banner_alpha), 1.8)
		draw_colored_polygon(PackedVector2Array([
			Vector2(center, line_y - 5.5),
			Vector2(center + 6.5, line_y),
			Vector2(center, line_y + 5.5),
			Vector2(center - 6.5, line_y),
		]), Color(b_cor, banner_alpha))
	# Nome do chefe grande e imponente (fonte 46, BONE, com sombra)
	var name_y: float = 816.0 + slide_y
	var name_size_x: float = font.get_string_size(b_nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x
	var name_x: float = (width - name_size_x) * 0.5
	_text(b_nome, Vector2(name_x + 2.0, name_y + 3.0), 46, Color(0.01, 0.01, 0.02, 0.85 * banner_alpha))
	_text(b_nome, Vector2(name_x, name_y), 46, Color(BONE, banner_alpha))
	# Caixa de fala estilizada (dark fantasy) abaixo do nome, acima da barra inferior
	if not b_fala.is_empty():
		var quote_txt: String = "\"%s\"" % b_fala
		var q_box := Rect2(center - 410.0, 848.0 + slide_y, 820.0, 84.0)
		draw_rect(q_box, Color(0.045, 0.05, 0.08, 0.86 * banner_alpha))
		draw_rect(q_box, Color(GOLD, 0.55 * banner_alpha), false, 1.5)
		var c: float = 10.0
		var acc := Color(b_cor, 0.90 * banner_alpha)
		var x0: float = q_box.position.x
		var y0: float = q_box.position.y
		var x1: float = q_box.end.x
		var y1: float = q_box.end.y
		draw_line(Vector2(x0, y0 + c), Vector2(x0, y0), acc, 2.0)
		draw_line(Vector2(x0, y0), Vector2(x0 + c, y0), acc, 2.0)
		draw_line(Vector2(x1 - c, y0), Vector2(x1, y0), acc, 2.0)
		draw_line(Vector2(x1, y0), Vector2(x1, y0 + c), acc, 2.0)
		draw_line(Vector2(x0, y1 - c), Vector2(x0, y1), acc, 2.0)
		draw_line(Vector2(x0, y1), Vector2(x0 + c, y1), acc, 2.0)
		draw_line(Vector2(x1 - c, y1), Vector2(x1, y1), acc, 2.0)
		draw_line(Vector2(x1, y1), Vector2(x1, y1 - c), acc, 2.0)
		var q_w: float = font.get_string_size(quote_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		if q_w <= q_box.size.x - 48.0:
			_center_in(quote_txt, q_box.position.y + 50.0, 22, Color(BONE, 0.95 * banner_alpha), q_box)
		else:
			_wrapped(quote_txt, Rect2(q_box.position + Vector2(28.0, 14.0), Vector2(q_box.size.x - 56.0, 62.0)), 20, Color(BONE, 0.95 * banner_alpha))
	# Dica discreta de pular na barra inferior após 0.6s
	if dur - intro_t >= 0.6:
		_center("[Espaço / Clique] Pular", 1044.0, 15, Color(MUTED, 0.62 * env), width)

func _draw_floating_panel(rect: Rect2) -> void:
	draw_rect(rect, Color(0.05, 0.06, 0.09, 0.72))
	draw_rect(rect, Color(GOLD, 0.38), false, 1.5)
	var c: float = 8.0
	var accent := Color(GOLD, 0.72)
	var x0: float = rect.position.x
	var y0: float = rect.position.y
	var x1: float = rect.end.x
	var y1: float = rect.end.y
	draw_line(Vector2(x0, y0 + c), Vector2(x0, y0), accent, 2.0)
	draw_line(Vector2(x0, y0), Vector2(x0 + c, y0), accent, 2.0)
	draw_line(Vector2(x1 - c, y0), Vector2(x1, y0), accent, 2.0)
	draw_line(Vector2(x1, y0), Vector2(x1, y0 + c), accent, 2.0)
	draw_line(Vector2(x0, y1 - c), Vector2(x0, y1), accent, 2.0)
	draw_line(Vector2(x0, y1), Vector2(x0 + c, y1), accent, 2.0)
	draw_line(Vector2(x1 - c, y1), Vector2(x1, y1), accent, 2.0)
	draw_line(Vector2(x1, y1), Vector2(x1, y1 - c), accent, 2.0)

func _status(width: float) -> void:
	var player: Dictionary = app.session.player
	if player.is_empty():
		return
	# Card flutuante compacto no canto superior esquerdo (Vida, Esquiva e Selo [Q])
	var left_card := Rect2(36.0, 22.0, 456.0, 118.0)
	_draw_floating_panel(left_card)
	_text(_nome_doutrina().to_upper(), Vector2(54.0, 46.0), 17, BONE)
	var bar_rect := Rect2(54.0, 56.0, 260.0, 16.0)
	var hp_val: float = float(player.hp)
	var max_hp_val: float = maxf(1.0, float(player.max_hp))
	var hp_ratio: float = clampf(hp_val / max_hp_val, 0.0, 1.0)
	draw_rect(bar_rect, Color(0.14, 0.12, 0.18, 0.92))
	if hp_ratio > 0.0:
		draw_rect(Rect2(bar_rect.position.x, bar_rect.position.y, bar_rect.size.x * hp_ratio, bar_rect.size.y), PINK)
		draw_rect(Rect2(bar_rect.position.x, bar_rect.position.y, bar_rect.size.x * hp_ratio, 4.0), Color(1.0, 0.80, 0.88, 0.45))
	var escudo_raw = app.session.get("player_shield")
	var escudo: float = float(escudo_raw) if escudo_raw != null else 0.0
	if escudo > 0.0:
		var esc_ratio: float = clampf(escudo / max_hp_val, 0.0, 1.0)
		draw_rect(Rect2(bar_rect.position.x, bar_rect.position.y, bar_rect.size.x * esc_ratio, 4.0), Color("7dd3fc"))
		draw_rect(Rect2(bar_rect.position.x, bar_rect.position.y, bar_rect.size.x * esc_ratio, bar_rect.size.y), Color(0.49, 0.83, 0.99, 0.28))
		_text("%d / %d (+%d)" % [ceili(hp_val), roundi(max_hp_val), ceili(escudo)], Vector2(326.0, 70.0), 16, Color("7dd3fc"))
	else:
		_text("%d / %d" % [ceili(hp_val), roundi(max_hp_val)], Vector2(326.0, 70.0), 16, BONE)
	draw_rect(bar_rect, Color(GOLD, 0.30), false, 1.0)
	# Losangos de esquiva + barra fina de recarga + aviso de recarga
	var charge_max: int = mini(int(player.charge_max), 10)
	var charges: int = int(player.charges)
	for i: int in range(charge_max):
		var pos := Vector2(64.0 + float(i) * 24.0, 89.0)
		var shape := PackedVector2Array([
			pos + Vector2(0.0, -7.0),
			pos + Vector2(7.0, 0.0),
			pos + Vector2(0.0, 7.0),
			pos + Vector2(-7.0, 0.0),
		])
		draw_colored_polygon(shape, BONE if i < charges else Color(0.24, 0.25, 0.31, 0.92))
		if i < charges:
			draw_polyline(PackedVector2Array([shape[0], shape[1], shape[2], shape[3], shape[0]]), Color(GOLD, 0.65), 1.0)
	var recharge_denom: float = maxf(1.0, roundf(float(app.catalog.data.esquiva.recarga_s) * 60.0))
	var recharge: float = clampf(float(player.recharge) / recharge_denom, 0.0, 1.0)
	if charges < int(player.charge_max):
		draw_rect(Rect2(54.0, 101.0, 120.0, 3.0), Color(0.18, 0.19, 0.24, 0.8))
		draw_rect(Rect2(54.0, 101.0, 120.0 * recharge, 3.0), GOLD)
	for effect: Dictionary in app.session.effects:
		if String(effect.get("kind", "")) == "dash_denied":
			_text("Esquiva recarregando", Vector2(282.0, 94.0), 15, PINK)
			break
	# Barra de Fluxo / Selo [Q]
	var flow_val: float = clampf(float(player.get("flow", 0.0)), 0.0, 100.0)
	var flow_ready: bool = flow_val >= 100.0
	var flow_ratio: float = flow_val / 100.0
	var p_time_raw = app.session.get("presentation_time")
	var p_time: float = float(p_time_raw) if p_time_raw != null else 0.0
	var flow_pulse: float = 1.0 if bool(app.get("reduced_motion")) else (0.74 + 0.26 * sin(p_time * 7.5))
	var flow_cyan := Color("7dd3fc")
	_text("SELO [Q]", Vector2(54.0, 128.0), 14, Color(GOLD, flow_pulse) if flow_ready else flow_cyan)
	var flow_rect := Rect2(138.0, 116.0, 232.0, 12.0)
	draw_rect(flow_rect, Color(0.10, 0.14, 0.20, 0.92))
	if flow_ratio > 0.0:
		var fill_w: float = flow_rect.size.x * flow_ratio
		if flow_ready:
			draw_rect(Rect2(flow_rect.position.x, flow_rect.position.y, fill_w, flow_rect.size.y), Color(GOLD.r, GOLD.g, GOLD.b, flow_pulse))
			draw_rect(Rect2(flow_rect.position.x, flow_rect.position.y, fill_w, 3.5), Color(1.0, 0.96, 0.78, 0.65 * flow_pulse))
		else:
			draw_rect(Rect2(flow_rect.position.x, flow_rect.position.y, fill_w, flow_rect.size.y), flow_cyan)
			draw_rect(Rect2(flow_rect.position.x, flow_rect.position.y, fill_w, 3.0), Color(0.85, 0.96, 1.0, 0.45))
	draw_rect(flow_rect, Color(GOLD, 0.85 * flow_pulse) if flow_ready else Color(flow_cyan, 0.40), false, 1.0)
	if flow_ready:
		_text("PRONTO!", Vector2(382.0, 128.0), 15, Color(1.0, 0.92, 0.52, flow_pulse))
	else:
		_text("%d%%" % floori(flow_val), Vector2(382.0, 128.0), 14, flow_cyan)
	# Esferas de Maldição Absorvidas (Domador de Pactos)
	if app.get("selected_weapon") == &"pactos":
		var absorbed: int = clampi(int(player.get("curses_absorbed", 0)), 0, 6)
		var curses_max: int = clampi(int(player.get("curses_max", 6)), 1, 6)
		var spheres_rect := Rect2(506.0, 26.0, 178.0, 68.0)
		_draw_floating_panel(spheres_rect)
		_text("ESFERAS (%d/%d)" % [absorbed, curses_max], Vector2(520.0, 47.0), 13, GOLD)
		for si: int in range(curses_max):
			var sp_pos := Vector2(528.0 + float(si) * 26.0, 72.0)
			if si < absorbed:
				draw_circle(sp_pos, 9.5, Color(0.56, 0.20, 0.78, 0.42))
				draw_circle(sp_pos, 7.0, VIOLET)
				draw_circle(sp_pos + Vector2(-2.0, -2.0), 2.3, Color("f0abfc"))
				draw_arc(sp_pos, 7.5, 0.0, TAU, 18, Color("e0259c"), 1.4, true)
			else:
				draw_circle(sp_pos, 6.5, Color(0.11, 0.10, 0.16, 0.90))
				draw_arc(sp_pos, 6.5, 0.0, TAU, 16, Color(MUTED, 0.48), 1.2, true)
	# Badge flutuante limpo no canto superior direito
	var right_badge := Rect2(width - 370.0, 26.0, 334.0, 86.0)
	_draw_floating_panel(right_badge)
	var reg: Dictionary = app.session.current_region if app.session.get("current_region") is Dictionary else {}
	if bool(app.session.get("extended_campaign")) and not reg.is_empty():
		var reg_num: int = int(app.session.get("region_index")) + 1
		var reg_nome: String = String(reg.get("nome", "O Limiar")).to_upper()
		var rw: int = int(app.session.get("region_wave_index"))
		var camara_txt: String = "CHEFE DA REGIÃO" if rw >= 2 else ("CÂMARA %d / 3" % (rw + 1))
		_text("REGIÃO %d/4 • %s" % [reg_num, reg_nome], Vector2(width - 352.0, 50.0), 16, GOLD)
		_text(camara_txt, Vector2(width - 352.0, 74.0), 18, Color("f29bb0") if rw >= 2 else BONE)
		_text("%d inimigos restantes" % app.session.enemies.size(), Vector2(width - 352.0, 98.0), 15, MUTED)
	else:
		_text("ONDA %d / %d" % [mini(app.session.wave_index + 1, app.catalog.data.ondas.size()), app.catalog.data.ondas.size()], Vector2(width - 352.0, 58.0), 22, GOLD)
		_text("%d inimigos restantes" % app.session.enemies.size(), Vector2(width - 352.0, 92.0), 17, MUTED)
	# Contador de Combo dinâmico + Rastreador discreto de Quest ativa (abaixo do badge direito)
	var right_cursor_y: float = 122.0
	var combo_hits: int = int(player.get("combo_hits", 0))
	if combo_hits >= 2:
		var is_unstoppable: bool = combo_hits >= 10
		var combo_col: Color = PINK if is_unstoppable else GOLD
		var combo_txt: String = ("x%d IMPARÁVEL!" if is_unstoppable else "x%d COMBO") % combo_hits
		var combo_rect := Rect2(width - 370.0, right_cursor_y, 334.0, 40.0)
		draw_rect(combo_rect, Color(0.08, 0.05, 0.10, 0.82))
		draw_rect(combo_rect, Color(combo_col, 0.82), false, 1.8)
		_center_in(combo_txt, combo_rect.position.y + 27.0, 20, combo_col, combo_rect)
		right_cursor_y += 48.0
	var quests_obj: Variant = app.get("quests")
	if quests_obj != null and quests_obj.has_method("quest_ativa"):
		var qa_raw: Variant = quests_obj.quest_ativa()
		if qa_raw is Dictionary and not qa_raw.is_empty():
			var qa: Dictionary = qa_raw
			var q_titulo: String = String(qa.get("titulo", ""))
			var q_prog: int = int(qa.get("progresso", qa.get("atual", 0)))
			var q_meta: int = int(qa.get("meta", qa.get("alvo", qa.get("total", 1))))
			var q_txt: String = "CONTRATO: %s (%d/%d)" % [q_titulo, q_prog, q_meta]
			var q_rect := Rect2(width - 370.0, right_cursor_y, 334.0, 36.0)
			draw_rect(q_rect, Color(0.05, 0.06, 0.09, 0.66))
			draw_rect(q_rect, Color(GOLD, 0.34), false, 1.0)
			_text(q_txt, Vector2(q_rect.position.x + 14.0, q_rect.position.y + 24.0), 15, Color(BONE, 0.90))
			right_cursor_y += 44.0
	var mapa_obj: Variant = app.session.get("mapa")
	if mapa_obj != null and mapa_obj.has_method("resumo_minimapa"):
		_draw_minimap(width, right_cursor_y, mapa_obj)
	# Banner dourado de "CONTRATO CONCLUÍDO!" no topo central (y = 32..96)
	var q_timer_raw: Variant = app.get("quest_toast_timer")
	var q_timer: float = float(q_timer_raw) if q_timer_raw != null else 0.0
	if q_timer > 0.0:
		var toast_elapsed: float = 3.2 - q_timer
		var q_alpha: float = minf(clampf(toast_elapsed / 0.25, 0.0, 1.0), clampf(q_timer / 0.45, 0.0, 1.0))
		var q_w: float = 460.0
		var q_box := Rect2((width - q_w) * 0.5, 32.0, q_w, 64.0)
		draw_rect(q_box, Color(0.06, 0.05, 0.03, 0.90 * q_alpha))
		draw_rect(q_box, Color(GOLD, 0.92 * q_alpha), false, 2.0)
		var toast_titulo_raw: Variant = app.get("quest_toast_titulo")
		var toast_titulo: String = String(toast_titulo_raw) if toast_titulo_raw != null else ""
		var toast_rec_raw: Variant = app.get("quest_toast_recompensa")
		var toast_rec: int = int(toast_rec_raw) if toast_rec_raw != null else 0
		_center_in("CONTRATO CONCLUÍDO", q_box.position.y + 24.0, 15, Color(GOLD, q_alpha), q_box)
		_center_in("%s  •  +%d Fragmentos" % [toast_titulo, toast_rec], q_box.position.y + 49.0, 18, Color(BONE, q_alpha), q_box)
	# Toast genérico de interação na sala (baú, fonte de cura, altar de pacto)
	var ev_timer_raw: Variant = app.get("evento_toast_timer")
	var ev_timer: float = float(ev_timer_raw) if ev_timer_raw != null else 0.0
	if ev_timer > 0.0:
		var ev_elapsed: float = 3.2 - ev_timer
		var ev_alpha: float = minf(clampf(ev_elapsed / 0.25, 0.0, 1.0), clampf(ev_timer / 0.45, 0.0, 1.0))
		var ev_w: float = 480.0
		var ev_y: float = 104.0 if q_timer > 0.0 else 32.0
		var ev_box := Rect2((width - ev_w) * 0.5, ev_y, ev_w, 64.0)
		draw_rect(ev_box, Color(0.05, 0.055, 0.085, 0.92 * ev_alpha))
		draw_rect(ev_box, Color(CYAN, 0.85 * ev_alpha), false, 2.0)
		var ev_titulo_raw: Variant = app.get("evento_toast_titulo")
		var ev_titulo: String = String(ev_titulo_raw) if ev_titulo_raw != null else ""
		var ev_texto_raw: Variant = app.get("evento_toast_texto")
		var ev_texto: String = String(ev_texto_raw) if ev_texto_raw != null else ""
		_center_in(ev_titulo, ev_box.position.y + 24.0, 14, Color(GOLD, ev_alpha), ev_box)
		_center_in(ev_texto, ev_box.position.y + 49.0, 18, Color(BONE, ev_alpha), ev_box)
	# Caixa narrativa atmosférica sutil na parte inferior-média (y = 890)
	var nar_timer_raw = app.get("narrativa_timer")
	var nar_timer: float = float(nar_timer_raw) if nar_timer_raw != null else 0.0
	var b_intro_raw = app.get("boss_intro_timer")
	var b_intro_t: float = float(b_intro_raw) if b_intro_raw != null else 0.0
	if nar_timer > 0.0 and b_intro_t <= 0.0:
		var nar_txt_raw = app.get("narrativa_texto")
		var nar_txt: String = String(nar_txt_raw) if nar_txt_raw != null else ""
		if not nar_txt.is_empty():
			var n_elapsed: float = 3.6 - nar_timer
			var n_alpha: float = minf(clampf(n_elapsed / 0.35, 0.0, 1.0), clampf(nar_timer / 0.55, 0.0, 1.0))
			var n_box := Rect2((width - 860.0) * 0.5, 864.0, 860.0, 44.0)
			draw_rect(n_box, Color(0.035, 0.04, 0.065, 0.64 * n_alpha))
			draw_line(Vector2(n_box.position.x + 80.0, n_box.position.y), Vector2(n_box.end.x - 80.0, n_box.position.y), Color(GOLD, 0.35 * n_alpha), 1.0)
			draw_line(Vector2(n_box.position.x + 80.0, n_box.end.y), Vector2(n_box.end.x - 80.0, n_box.end.y), Color(GOLD, 0.35 * n_alpha), 1.0)
			_center_in("« %s »" % nar_txt, 892.0, 19, Color(0.90, 0.85, 0.72, 0.94 * n_alpha), n_box)
	# Barra de Vida do Chefe na parte inferior central (estilo cinematográfico)
	var boss: Dictionary = _chefe_vivo()
	if not boss.is_empty():
		var b_center: float = width * 0.5
		var b_w: float = 640.0
		var b_x: float = b_center - b_w * 0.5
		var b_y: float = 975.0
		var b_h: float = 16.0
		var b_nome: String = String(boss.get("boss_name", "Chefe")).to_upper()
		var b_hp: float = float(boss.get("hp", 0.0))
		var b_max: float = maxf(1.0, float(boss.get("max_hp", 1.0)))
		var b_ratio: float = clampf(b_hp / b_max, 0.0, 1.0)
		_center(b_nome, 965.0, 20, GOLD, width)
		draw_rect(Rect2(b_x - 3.0, b_y - 3.0, b_w + 6.0, b_h + 6.0), Color(0.04, 0.04, 0.07, 0.88))
		draw_rect(Rect2(b_x, b_y, b_w, b_h), Color(0.16, 0.12, 0.19, 0.95))
		if b_ratio > 0.0:
			draw_rect(Rect2(b_x, b_y, b_w * b_ratio, b_h), PINK)
			draw_rect(Rect2(b_x, b_y, b_w * b_ratio, 3.5), Color(1.0, 0.84, 0.90, 0.55))
		draw_rect(Rect2(b_x - 2.0, b_y - 2.0, b_w + 4.0, b_h + 4.0), Color(GOLD, 0.85), false, 1.5)
		var mid_y: float = b_y + b_h * 0.5
		var left_d := PackedVector2Array([
			Vector2(b_x - 10.0, mid_y),
			Vector2(b_x - 4.0, mid_y - 6.0),
			Vector2(b_x + 2.0, mid_y),
			Vector2(b_x - 4.0, mid_y + 6.0),
		])
		var right_d := PackedVector2Array([
			Vector2(b_x + b_w - 2.0, mid_y),
			Vector2(b_x + b_w + 4.0, mid_y - 6.0),
			Vector2(b_x + b_w + 10.0, mid_y),
			Vector2(b_x + b_w + 4.0, mid_y + 6.0),
		])
		draw_colored_polygon(left_d, GOLD)
		draw_colored_polygon(right_d, GOLD)
		_center("%d / %d" % [ceili(b_hp), roundi(b_max)], 1012.0, 15, Color(BONE, 0.82), width)

func _controls(width: float) -> void:
	var text := "WASD  Mover     Mouse  Mirar     Clique / J  Atacar     Direito / K  Investida     Espaço  Esquiva     Esc  Pausa"
	if app.last_sample.get("source", "mouse") != "mouse":
		text = "Analógicos  Mover / Mirar     X  Atacar     Y  Investida     A  Esquiva     Start  Pausa"
	if app.session.state == "jogo":
		if _chefe_vivo().is_empty():
			_center(text, 1062.0, 15, Color(MUTED, 0.55), width)
		return
	draw_rect(Rect2(0, 1013, width, 67), Color(0.035, 0.04, 0.065, 0.93))
	_center(text, 1054, 20, MUTED, width)

func _card(rect: Rect2,index: int) -> void:
	var chosen: bool = app.selected == index
	var use_offer: bool = bool(app.session.get("extended_campaign")) and app.session.current_offer.size() > index
	var item: Dictionary = app.session.current_offer[index] if use_offer else app.catalog.data.bencaos[index]
	var raridade: String = String(item.get("raridade", "comum")).to_lower() if use_offer else ("rara" if chosen else "comum")
	var mold_key: String = "moldura_comum"
	var badge_txt: String = "[COMUM]"
	var badge_col: Color = MUTED
	if raridade == "epica":
		mold_key = "moldura_epica" if _ui_tex.has("moldura_epica") else "moldura_rara"
		badge_txt = "[ÉPICA]"
		badge_col = Color("c084fc")
	elif raridade == "rara":
		mold_key = "moldura_rara"
		badge_txt = "[RARA]"
		badge_col = GOLD
	var mold_tex: Texture2D = _ui_tex.get(mold_key, null)
	if mold_tex != null:
		var mod_c: Color = Color.WHITE if chosen else Color(0.78, 0.78, 0.84, 0.95)
		if raridade == "epica" and not _ui_tex.has("moldura_epica"):
			mod_c = Color(0.95, 0.78, 1.0, 1.0) if chosen else Color(0.80, 0.65, 0.90, 0.95)
		draw_texture_rect(mold_tex, rect, false, mod_c)
		if chosen:
			draw_rect(rect, GOLD if raridade != "epica" else Color("c084fc"), false, 3.0)
	else:
		draw_rect(rect,Color("242532") if chosen else PANEL)
		draw_rect(rect,badge_col if use_offer else (GOLD if chosen else Color("45404b")),false,3 if chosen else 1)
	if use_offer:
		_center_in(badge_txt, rect.position.y + 34, 18, badge_col, rect)
	var center := Vector2(rect.get_center().x,rect.position.y+95)
	match index:
		0:
			draw_line(center+Vector2(-24,30),center+Vector2(22,-35),BONE,6,true)
			draw_line(center+Vector2(-32,12),center+Vector2(-5,32),GOLD,4,true)
		1:
			for offset in [-22,22]:
				draw_polyline(PackedVector2Array([center+Vector2(offset-12,-20),center+Vector2(offset+12,0),center+Vector2(offset-12,20)]),BONE,5,true)
		2:
			draw_arc(center,35,-2.8,0.8,30,BONE,4,true)
			draw_line(center+Vector2(-25,27),center+Vector2(35,-30),GOLD,3,true)
	var item_nome: String = String(item.get("nome", ""))
	var item_texto: String = String(item.get("texto", item.get("descricao", "")))
	_center_in(item_nome,rect.position.y+198,26,BONE,rect)
	_wrapped(item_texto,Rect2(rect.position+Vector2(34,230),Vector2(rect.size.x-68,110)),22,MUTED)
	_center_in("[ %d ]   %s" % [index+1,"SELECIONADA" if chosen else "BÊNÇÃO"],rect.end.y-32,18,GOLD if chosen else MUTED,rect)

func _button(rect:Rect2,label:String,index:int,secondary:bool=false) -> void:
	var chosen: bool = index == app.selected
	draw_rect(rect,Color("3b3540") if chosen else PANEL)
	draw_rect(rect,GOLD if chosen else Color("49424d"),false,2 if chosen else 1)
	_center_in(label,rect.position.y+rect.size.y*.5+9,24 if secondary else 28,BONE if chosen else MUTED,rect)
	if chosen:
		_text("›",rect.position+Vector2(18,rect.size.y*.5+10),30,GOLD)

func _summary(width:float) -> void:
	_center("%d inimigos vencidos" % app.session.kills,493,22,MUTED,width)

func _text(text:String,pos:Vector2,size:int,color:Color) -> void:
	draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _center(text:String,y:float,size:int,color:Color,width:float) -> void:
	_text(text,Vector2((width-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)/2,y),size,color)

func _center_in(text:String,y:float,size:int,color:Color,rect:Rect2) -> void:
	_text(text,Vector2(rect.position.x+(rect.size.x-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)/2,y),size,color)

func _rule(center:float,y:float,width:float) -> void:
	draw_line(Vector2(center-width/2,y),Vector2(center-10,y),Color("71624f"),1)
	draw_line(Vector2(center+10,y),Vector2(center+width/2,y),Color("71624f"),1)
	draw_colored_polygon(PackedVector2Array([Vector2(center,y-5),Vector2(center+5,y),Vector2(center,y+5),Vector2(center-5,y)]),GOLD)

func _wrapped(text:String,rect:Rect2,size:int,color:Color) -> void:
	var y: float = rect.position.y + float(size)
	var paragrafos: PackedStringArray = text.split("\n")
	for p_idx: int in range(paragrafos.size()):
		var para: String = paragrafos[p_idx]
		if para.is_empty():
			y += float(size) * 1.15
			continue
		var line: String = ""
		var words: PackedStringArray = para.split(" ")
		for word: String in words:
			var next: String = word if line.is_empty() else (line + " " + word)
			if font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x and not line.is_empty():
				_text(line, Vector2(rect.position.x, y), size, color)
				y += float(size) * 1.38
				line = word
			else:
				line = next
		if not line.is_empty():
			_text(line, Vector2(rect.position.x, y), size, color)
			y += float(size) * 1.38


func _nome_regiao_por_id(reg_id: String) -> String:
	match reg_id:
		"limiar":
			return "O Limiar da Beira"
		"veio_instavel":
			return "Veio Instável"
		"fosso_das_cinzas":
			return "Fosso das Cinzas"
		"santuario_partido":
			return "Santuário Partido"
	return reg_id.capitalize()


func _grau_cor(grau: String) -> Color:
	if grau == "Grau Especial":
		return PINK
	if grau == "Grau 1":
		return CYAN
	if grau == "Grau 2":
		return Color("7dd3fc")
	return BONE


func _draw_minimap(width: float, top_y: float, mapa_obj: Variant) -> void:
	var resumo_raw: Variant = mapa_obj.call("resumo_minimapa")
	if not (resumo_raw is Dictionary):
		return
	var resumo: Dictionary = resumo_raw
	var salas_raw: Variant = resumo.get("salas", [])
	if not (salas_raw is Array):
		return
	var salas: Array = salas_raw
	if salas.is_empty():
		return
	var idx_atual: int = clampi(int(resumo.get("indice_atual", 0)), 0, salas.size() - 1)
	var camada_atual: int = int(resumo.get("camada_atual", 0))
	var box := Rect2(width - 256.0, top_y, 220.0, 110.0)
	draw_rect(box, Color(0.04, 0.045, 0.075, 0.78))
	draw_rect(box, Color(GOLD, 0.42), false, 1.4)
	_text("MAPA • CAMADA %d/5" % (camada_atual + 1), box.position + Vector2(12.0, 19.0), 12, GOLD)
	var posicoes: Array[Vector2] = []
	for i: int in range(salas.size()):
		var sala: Dictionary = salas[i] as Dictionary
		var camada: int = int(sala.get("camada", 0))
		var ramo: int = int(sala.get("ramo", 0))
		var nx: float = box.position.x + 26.0 + float(camada) * 42.0
		var ny: float = box.position.y + (66.0 if (camada == 0 or camada >= 3) else (45.0 if ramo == 0 else 86.0))
		posicoes.append(Vector2(nx, ny))
	var sala_atual: Dictionary = salas[idx_atual] as Dictionary
	var acessiveis: Dictionary = {}
	var prox_atual_raw: Variant = sala_atual.get("proximas", [])
	if prox_atual_raw is Array:
		var prox_atual: Array = prox_atual_raw
		for p_var: Variant in prox_atual:
			acessiveis[int(p_var)] = true
	for i: int in range(salas.size()):
		var sala_e: Dictionary = salas[i] as Dictionary
		var proximas_raw: Variant = sala_e.get("proximas", [])
		if not (proximas_raw is Array):
			continue
		var proximas_arr: Array = proximas_raw
		for dst_var: Variant in proximas_arr:
			var dst: int = int(dst_var)
			if dst < 0 or dst >= posicoes.size():
				continue
			var edge_col: Color = Color(GOLD, 0.78) if i == idx_atual else Color(MUTED, 0.42)
			var edge_w: float = 1.8 if i == idx_atual else 1.2
			draw_line(posicoes[i], posicoes[dst], edge_col, edge_w, true)
	for i: int in range(salas.size()):
		var sala_n: Dictionary = salas[i] as Dictionary
		var p_node: Vector2 = posicoes[i]
		var is_atual: bool = i == idx_atual
		var is_boss: bool = String(sala_n.get("tipo", "")) == "chefe" or i == 6
		var is_limpa: bool = bool(sala_n.get("limpa", false))
		var is_acessivel: bool = acessiveis.has(i)
		var fill_col: Color = Color(0.19, 0.21, 0.30, 0.94)
		if is_atual:
			fill_col = GOLD
		elif is_boss:
			fill_col = PINK
		elif is_limpa:
			fill_col = CYAN
		var rad: float = 8.0 if (is_atual or is_boss) else 6.5
		draw_circle(p_node, rad, fill_col)
		if is_atual:
			draw_arc(p_node, rad + 3.0, 0.0, TAU, 20, Color(1.0, 0.96, 0.78, 0.96), 1.8, true)
		elif is_acessivel:
			draw_arc(p_node, rad + 2.6, 0.0, TAU, 20, Color(0.92, 0.97, 1.0, 0.95), 1.7, true)
		elif is_boss:
			draw_arc(p_node, rad + 2.0, 0.0, TAU, 20, Color(PINK, 0.68), 1.3, true)
		else:
			draw_arc(p_node, rad + 0.5, 0.0, TAU, 16, Color(GOLD, 0.32), 1.0, true)


func _draw_domain_banner(width: float, domain_t: float) -> void:
	var elapsed: float = 1.9 - domain_t
	var alpha: float = minf(clampf(elapsed / 0.22, 0.0, 1.0), clampf(domain_t / 0.45, 0.0, 1.0))
	if alpha <= 0.01:
		return
	var center: float = width * 0.5
	var nome_raw: Variant = app.get("domain_banner_nome")
	var dom_nome: String = String(nome_raw).to_upper() if nome_raw != null else ""
	if dom_nome.is_empty():
		var w_raw: Variant = app.get("selected_weapon")
		var w_id: StringName = StringName(w_raw) if w_raw != null else &"lamina"
		dom_nome = CodexHistoria.nome_dominio(w_id).to_upper()
	var slide_y: float = (1.0 - clampf(elapsed / 0.22, 0.0, 1.0)) * 12.0
	var band := Rect2(center - 460.0, 198.0 + slide_y, 920.0, 118.0)
	draw_rect(band, Color(0.02, 0.022, 0.04, 0.86 * alpha))
	draw_line(Vector2(band.position.x + 40.0, band.position.y), Vector2(band.end.x - 40.0, band.position.y), Color(GOLD, 0.85 * alpha), 1.8)
	draw_line(Vector2(band.position.x + 40.0, band.end.y), Vector2(band.end.x - 40.0, band.end.y), Color(GOLD, 0.85 * alpha), 1.8)
	_center("EXPANSÃO DE DOMÍNIO", 232.0 + slide_y, 17, Color(GOLD, alpha), width)
	var line_y: float = 248.0 + slide_y
	var half_l: float = 240.0 * alpha
	draw_line(Vector2(center - half_l, line_y), Vector2(center - 12.0, line_y), Color(GOLD, 0.75 * alpha), 1.4)
	draw_line(Vector2(center + 12.0, line_y), Vector2(center + half_l, line_y), Color(GOLD, 0.75 * alpha), 1.4)
	draw_colored_polygon(PackedVector2Array([
		Vector2(center, line_y - 5.0),
		Vector2(center + 6.0, line_y),
		Vector2(center, line_y + 5.0),
		Vector2(center - 6.0, line_y),
	]), Color(PINK, alpha))
	var nome_w: float = font.get_string_size(dom_nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x
	var nome_x: float = (width - nome_w) * 0.5
	_text(dom_nome, Vector2(nome_x + 2.0, 294.0 + slide_y), 36, Color(0.01, 0.01, 0.02, 0.85 * alpha))
	_text(dom_nome, Vector2(nome_x, 292.0 + slide_y), 36, Color(BONE, alpha))


func _draw_interact_hint(width: float) -> void:
	var pill := Rect2(width * 0.5 - 116.0, 914.0, 232.0, 36.0)
	draw_rect(pill, Color(0.04, 0.045, 0.075, 0.84))
	draw_rect(pill, Color(GOLD, 0.75), false, 1.4)
	_center_in("[E] Interagir", pill.position.y + 24.0, 17, GOLD, pill)


func _draw_lore_popup(width: float) -> void:
	draw_rect(Rect2(0.0, 0.0, width, 1080.0), Color(0.015, 0.018, 0.032, 0.76))
	var eco_raw: Variant = app.get("lore_popup_data")
	var eco: Dictionary = eco_raw if eco_raw is Dictionary else {}
	var center: float = width * 0.5
	var box := Rect2(center - 440.0, 210.0, 880.0, 620.0)
	draw_rect(box, Color(0.045, 0.048, 0.075, 0.96))
	draw_rect(box, Color(GOLD, 0.88), false, 2.2)
	draw_rect(box.grow(-10.0), Color(GOLD, 0.30), false, 1.0)
	var c: float = 14.0
	var x0: float = box.position.x
	var y0: float = box.position.y
	var x1: float = box.end.x
	var y1: float = box.end.y
	draw_line(Vector2(x0, y0 + c), Vector2(x0, y0), GOLD, 3.0)
	draw_line(Vector2(x0, y0), Vector2(x0 + c, y0), GOLD, 3.0)
	draw_line(Vector2(x1 - c, y0), Vector2(x1, y0), GOLD, 3.0)
	draw_line(Vector2(x1, y0), Vector2(x1, y0 + c), GOLD, 3.0)
	draw_line(Vector2(x0, y1 - c), Vector2(x0, y1), GOLD, 3.0)
	draw_line(Vector2(x0, y1), Vector2(x0 + c, y1), GOLD, 3.0)
	draw_line(Vector2(x1 - c, y1), Vector2(x1, y1), GOLD, 3.0)
	draw_line(Vector2(x1, y1), Vector2(x1, y1 - c), GOLD, 3.0)
	var reg_nome: String = _nome_regiao_por_id(String(eco.get("regiao", "limiar"))).to_upper()
	_center_in("ECO DE MEMÓRIA  •  %s" % reg_nome, box.position.y + 52.0, 16, GOLD, box)
	_center_in(String(eco.get("titulo", "Monólito")), box.position.y + 98.0, 32, BONE, box)
	var autor: String = String(eco.get("autor", ""))
	if not autor.is_empty():
		_center_in(autor, box.position.y + 132.0, 18, Color(GOLD, 0.85), box)
	_rule(center, box.position.y + 156.0, 340.0)
	var texto_rect := Rect2(box.position.x + 56.0, box.position.y + 186.0, box.size.x - 112.0, 330.0)
	_wrapped(String(eco.get("texto", "")), texto_rect, 22, Color(BONE, 0.94))
	_center_in("[E / Enter / Clique] Fechar", box.end.y - 34.0, 18, MUTED, box)


func _draw_prologo(width: float) -> void:
	draw_rect(Rect2(0.0, 0.0, width, 1080.0), Color(0.02, 0.024, 0.04, 0.98))
	var atos: Array[Dictionary] = CodexHistoria.prologo_atos()
	var ato_raw: Variant = app.get("prologo_ato")
	var ato_idx: int = clampi(int(ato_raw) if ato_raw != null else 0, 0, maxi(0, atos.size() - 1))
	var ato: Dictionary = atos[ato_idx] if not atos.is_empty() else {}
	var center: float = width * 0.5
	var img_rect := Rect2(center - 480.0, 76.0, 960.0, 520.0)
	draw_rect(img_rect, Color(0.03, 0.035, 0.06, 0.95))
	var img_key: String = String(ato.get("img_key", "prologo_01"))
	var img_tex: Texture2D = _ui_tex.get(img_key, null)
	if img_tex != null:
		draw_texture_rect(img_tex, img_rect, false)
	draw_rect(img_rect, GOLD, false, 2.5)
	draw_rect(img_rect.grow(6.0), Color(GOLD, 0.28), false, 1.2)
	_center(String(ato.get("subtitulo", "")), 634.0, 20, GOLD, width)
	_center(String(ato.get("titulo", "")), 676.0, 36, BONE, width)
	_rule(center, 694.0, 340.0)
	var txt_box := Rect2(center - 520.0, 714.0, 1040.0, 212.0)
	draw_rect(txt_box, Color(0.045, 0.05, 0.08, 0.90))
	draw_rect(txt_box, Color(GOLD, 0.45), false, 1.5)
	_wrapped(String(ato.get("texto", "")), Rect2(txt_box.position + Vector2(36.0, 22.0), txt_box.size - Vector2(72.0, 40.0)), 21, Color(BONE, 0.95))
	_center("%d / %d" % [ato_idx + 1, maxi(1, atos.size())], 964.0, 20, GOLD, width)
	_center("[Enter / Clique] Avançar   •   [Esc] Pular Prólogo", 1020.0, 19, MUTED, width)


func _draw_codex(width: float) -> void:
	draw_rect(Rect2(0.0, 0.0, width, 1080.0), Color(0.025, 0.03, 0.05, 0.96))
	var center: float = width * 0.5
	_center("GRIMÓRIO DE KHAEROS", 82.0, 44, BONE, width)
	_rule(center, 108.0, 320.0)
	var aba_raw: Variant = app.get("codex_aba")
	var aba: int = clampi(int(aba_raw) if aba_raw != null else 0, 0, 3)
	var scroll_raw: Variant = app.get("codex_scroll")
	var scroll: int = maxi(0, int(scroll_raw) if scroll_raw != null else 0)
	var codex_obj: CodexHistoria = app.get("codex") as CodexHistoria
	var ecos_desc: int = codex_obj.total_ecos_descobertos() if codex_obj != null else 0
	var quests_obj: SistemaQuests = app.get("quests") as SistemaQuests
	var q_concluidas: int = quests_obj.total_concluidas() if quests_obj != null else 0
	var q_todas: Array[Dictionary] = quests_obj.todas_quests() if quests_obj != null else []
	var tab_labels: Array[String] = [
		"História & Doutrinas",
		"Ecos (%d/12)" % ecos_desc,
		"Bestiário",
		"Contratos (%d/%d)" % [q_concluidas, maxi(6, q_todas.size())],
	]
	var boxes: Array[Rect2] = action_rects()
	for i: int in range(mini(4, boxes.size())):
		var r_tab: Rect2 = boxes[i]
		var ativa: bool = i == aba
		var hover: bool = i == app.selected
		var bg_tab: Color = Color("3b3540") if ativa else (Color("242532") if hover else PANEL)
		var bd_tab: Color = GOLD if ativa else (Color(GOLD, 0.55) if hover else Color("49424d"))
		draw_rect(r_tab, bg_tab)
		draw_rect(r_tab, bd_tab, false, 2.2 if ativa else 1.2)
		_center_in(tab_labels[i], r_tab.position.y + r_tab.size.y * 0.5 + 6.0, 17, GOLD if ativa else (BONE if hover else MUTED), r_tab)
	var panel := Rect2(center - 560.0, 218.0, 1120.0, 684.0)
	draw_rect(panel, Color(0.04, 0.045, 0.075, 0.92))
	draw_rect(panel, Color(GOLD, 0.45), false, 1.6)
	var max_scroll: int = 0
	match aba:
		0:
			var doutrinas: Array[Dictionary] = CodexHistoria.doutrinas_codex()
			max_scroll = maxi(0, doutrinas.size() - 3)
			scroll = clampi(scroll, 0, max_scroll)
			_draw_codex_doutrinas(panel, doutrinas, scroll)
		1:
			var ecos: Array[Dictionary] = CodexHistoria.todos_ecos()
			max_scroll = maxi(0, ecos.size() - 4)
			scroll = clampi(scroll, 0, max_scroll)
			_draw_codex_ecos(panel, ecos, scroll, codex_obj)
		2:
			var monstros: Array[Dictionary] = CodexHistoria.bestiario()
			max_scroll = maxi(0, monstros.size() - 3)
			scroll = clampi(scroll, 0, max_scroll)
			_draw_codex_bestiario(panel, monstros, scroll)
		3:
			max_scroll = maxi(0, q_todas.size() - 6)
			scroll = clampi(scroll, 0, max_scroll)
			_draw_codex_contratos(panel, q_todas, scroll)
	if max_scroll > 0:
		var track := Rect2(panel.end.x - 14.0, panel.position.y + 18.0, 5.0, panel.size.y - 36.0)
		draw_rect(track, Color(0.14, 0.15, 0.22, 0.85))
		var thumb_h: float = maxf(36.0, track.size.y / float(max_scroll + 1))
		var thumb_y: float = track.position.y + (track.size.y - thumb_h) * (float(scroll) / float(max_scroll))
		draw_rect(Rect2(track.position.x, thumb_y, track.size.x, thumb_h), GOLD)
	if boxes.size() >= 5:
		_button(boxes[4], "Voltar ao Menu", 4, true)
	_center("[←/→] Trocar Aba   •   [↑/↓] Rolar   •   [Esc] Voltar", 1020.0, 19, MUTED, width)


func _draw_codex_doutrinas(panel: Rect2, doutrinas: Array[Dictionary], scroll: int) -> void:
	var visiveis: int = mini(3, doutrinas.size() - scroll)
	for slot: int in range(visiveis):
		var d: Dictionary = doutrinas[scroll + slot]
		var card := Rect2(panel.position.x + 26.0, panel.position.y + 22.0 + float(slot) * 214.0, panel.size.x - 66.0, 198.0)
		draw_rect(card, Color(0.065, 0.072, 0.115, 0.92))
		draw_rect(card, Color(GOLD, 0.36), false, 1.2)
		_text(String(d.get("nome", "")), card.position + Vector2(22.0, 34.0), 24, BONE)
		_text(String(d.get("papel", "")), card.position + Vector2(22.0, 58.0), 16, MUTED)
		_text("Expansão de Domínio: %s" % String(d.get("dominio", "")), card.position + Vector2(22.0, 82.0), 17, GOLD)
		_wrapped(String(d.get("descricao", "")), Rect2(card.position + Vector2(22.0, 94.0), Vector2(card.size.x - 44.0, 92.0)), 16, Color(BONE, 0.90))


func _draw_codex_ecos(panel: Rect2, ecos: Array[Dictionary], scroll: int, codex_obj: CodexHistoria) -> void:
	var visiveis: int = mini(4, ecos.size() - scroll)
	for slot: int in range(visiveis):
		var eco: Dictionary = ecos[scroll + slot]
		var eco_id: String = String(eco.get("id", ""))
		var descoberto: bool = codex_obj != null and codex_obj.foi_descoberto(eco_id)
		var card := Rect2(panel.position.x + 26.0, panel.position.y + 20.0 + float(slot) * 162.0, panel.size.x - 66.0, 148.0)
		draw_rect(card, Color(0.065, 0.072, 0.115, 0.92) if descoberto else Color(0.045, 0.048, 0.07, 0.85))
		draw_rect(card, Color(GOLD, 0.45) if descoberto else Color(MUTED, 0.25), false, 1.2)
		var reg_txt: String = _nome_regiao_por_id(String(eco.get("regiao", ""))).to_upper()
		if descoberto:
			_text(String(eco.get("titulo", "")), card.position + Vector2(20.0, 30.0), 21, GOLD)
			_text("%s  •  %s" % [reg_txt, String(eco.get("autor", ""))], card.position + Vector2(20.0, 52.0), 14, MUTED)
			_wrapped(String(eco.get("texto", "")), Rect2(card.position + Vector2(20.0, 62.0), Vector2(card.size.x - 40.0, 76.0)), 15, Color(BONE, 0.92))
		else:
			_text("??? — Monólito não lido nesta região", card.position + Vector2(20.0, 36.0), 20, MUTED)
			_text("REGIÃO: %s" % reg_txt, card.position + Vector2(20.0, 64.0), 14, Color(GOLD, 0.65))
			_text("Explore os monólitos nas câmaras desta região e pressione [E] para registrar este Eco.", card.position + Vector2(20.0, 96.0), 15, Color(MUTED, 0.72))


func _draw_codex_bestiario(panel: Rect2, monstros: Array[Dictionary], scroll: int) -> void:
	var visiveis: int = mini(3, monstros.size() - scroll)
	for slot: int in range(visiveis):
		var m: Dictionary = monstros[scroll + slot]
		var grau: String = String(m.get("grau", "Grau 3"))
		var g_cor: Color = _grau_cor(grau)
		var card := Rect2(panel.position.x + 26.0, panel.position.y + 22.0 + float(slot) * 214.0, panel.size.x - 66.0, 198.0)
		draw_rect(card, Color(0.065, 0.072, 0.115, 0.92))
		draw_rect(card, Color(GOLD if grau == "Grau Especial" else g_cor, 0.48), false, 1.4)
		_text(String(m.get("nome", "")), card.position + Vector2(22.0, 34.0), 24, BONE)
		var reg_txt: String = _nome_regiao_por_id(String(m.get("regiao", "")))
		_text("[%s]  •  %s" % [grau.to_upper(), reg_txt], card.position + Vector2(22.0, 58.0), 16, g_cor)
		_wrapped(String(m.get("descricao", "")), Rect2(card.position + Vector2(22.0, 68.0), Vector2(card.size.x - 44.0, 56.0)), 16, Color(BONE, 0.90))
		_wrapped("Tática: %s" % String(m.get("tatica", "")), Rect2(card.position + Vector2(22.0, 126.0), Vector2(card.size.x - 44.0, 60.0)), 15, Color(GOLD, 0.90))


func _draw_codex_contratos(panel: Rect2, quests_lista: Array[Dictionary], scroll: int) -> void:
	var visiveis: int = mini(6, quests_lista.size() - scroll)
	for slot: int in range(visiveis):
		var q: Dictionary = quests_lista[scroll + slot]
		var concluida: bool = bool(q.get("concluida", false))
		var prog: int = int(q.get("progresso", 0))
		var meta: int = maxi(1, int(q.get("meta", 1)))
		var rec: int = int(q.get("recompensa_frag", 0))
		var card := Rect2(panel.position.x + 26.0, panel.position.y + 18.0 + float(slot) * 108.0, panel.size.x - 66.0, 96.0)
		draw_rect(card, Color(0.065, 0.075, 0.11, 0.92))
		draw_rect(card, Color(GOLD, 0.65) if concluida else Color(MUTED, 0.32), false, 1.4)
		_text(String(q.get("titulo", "")), card.position + Vector2(20.0, 30.0), 20, GOLD if concluida else BONE)
		_text(String(q.get("descricao", "")), card.position + Vector2(20.0, 56.0), 15, MUTED)
		var status_txt: String = "CONCLUÍDO" if concluida else "EM ANDAMENTO (%d/%d)" % [prog, meta]
		var status_col: Color = Color("34d399") if concluida else Color("7dd3fc")
		_text(status_txt, Vector2(card.end.x - 240.0, card.position.y + 30.0), 15, status_col)
		_text("Recompensa: +%d Fragmentos" % rec, Vector2(card.end.x - 240.0, card.position.y + 56.0), 15, GOLD)
		var bar := Rect2(card.position.x + 20.0, card.end.y - 18.0, card.size.x - 40.0, 6.0)
		draw_rect(bar, Color(0.12, 0.13, 0.19, 0.9))
		var ratio: float = clampf(float(prog) / float(meta), 0.0, 1.0)
		if ratio > 0.0:
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color("34d399") if concluida else GOLD)
