extends Node2D
## Screen-fixed Portuguese UI with one focus shared by mouse and keyboard/gamepad.

const BONE := Color("e2dccb")
const MUTED := Color("9693a2")
const GOLD := Color("d7b778")
const PINK := Color("ed618f")
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
	}
	for k: String in mapas.keys():
		var path: String = mapas[k]
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
			result = [
				Rect2(center-240,500,480,54),
				Rect2(center-240,562,480,50),
				Rect2(center-240,620,480,50),
				Rect2(center-240,678,480,50),
				Rect2(center-240,736,480,50),
				Rect2(center-240,794,480,50),
			]
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
	if not state in ["menu", "campus", "mestres"]:
		_status(width)
	if state == "jogo":
		_controls(width)
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
				_center("K H A E R O S",270,80,BONE,width)
				_rule(center,312,300)
				_center("O LIMIAR",368,22,GOLD,width)
				_center(_nome_doutrina(),430,28,BONE,width)
				_center("Atravesse as câmaras das 4 Regiões. Escolha arma, bênçãos e pactos.",468,21,MUTED,width)
				var frag_saldo: int = app.saldo_fragmentos() if app.has_method("saldo_fragmentos") else 0
				var menu_boxes: Array[Rect2] = action_rects()
				_button(menu_boxes[0],"Entrar no Limiar",0)
				_button(menu_boxes[1],"Redução de movimento: "+("ligada" if app.reduced_motion else "desligada"),1,true)
				_button(menu_boxes[2],"Doutrina: "+_nome_doutrina(),2,true)
				_button(menu_boxes[3],"Oficina de Reforja (%d Frag.)" % frag_saldo,3,true)
				_button(menu_boxes[4],"Explorar Campus (Hub)",4,true)
				_button(menu_boxes[5],"Região Inicial: " + _nome_regiao_inicial(),5,true)
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


func _status(width: float) -> void:
	var player: Dictionary = app.session.player
	if player.is_empty():
		return
	draw_rect(Rect2(0,0,width,116),Color(0.035,0.04,0.065,0.84))
	draw_line(Vector2(0,116),Vector2(width,116),Color(GOLD.r,GOLD.g,GOLD.b,0.28),1.5)
	_text(_nome_doutrina().to_upper(),Vector2(54,32),19,BONE)
	if app.get("selected_weapon") == &"pactos" and _ui_tex.has("silhueta_vulto"):
		draw_texture_rect(_ui_tex["silhueta_vulto"], Rect2(500, 22, 54, 54), false)
		_text("VULTO MUDO (ALIADO)", Vector2(562, 56), 15, GOLD)
	_text("VIDA",Vector2(54,66),16,MUTED)
	draw_rect(Rect2(114,49,290,18),Color("34313f"))
	draw_rect(Rect2(114,49,290*clampf(float(player.hp)/float(player.max_hp),0,1),18),PINK)
	var escudo: float = float(app.session.get("player_shield")) if app.session.get("player_shield") != null else 0.0
	if escudo > 0.0:
		var esc_ratio: float = clampf(escudo / maxf(1.0, float(player.max_hp)), 0.0, 1.0)
		draw_rect(Rect2(114, 49, 290.0 * esc_ratio, 5), Color("7dd3fc"))
		draw_rect(Rect2(114, 49, 290.0 * esc_ratio, 18), Color(0.49, 0.83, 0.99, 0.25))
		_text("%d / %d (+%d)" % [ceili(float(player.hp)), roundi(float(player.max_hp)), ceili(escudo)], Vector2(418, 66), 18, Color("7dd3fc"))
	else:
		_text("%d / %d" % [ceili(float(player.hp)), roundi(float(player.max_hp))],Vector2(418,66),18,BONE)
	_text("ESQUIVA",Vector2(54,99),16,MUTED)
	for i in range(mini(int(player.charge_max),10)):
		var pos := Vector2(154+i*28,92)
		var shape := PackedVector2Array([pos+Vector2(-9,-7),pos+Vector2(0,4),pos+Vector2(9,-7),pos+Vector2(9,0),pos+Vector2(0,11),pos+Vector2(-9,0)])
		draw_colored_polygon(shape,BONE if i<int(player.charges) else Color("3e404d"))
	var reg: Dictionary = app.session.current_region if app.session.get("current_region") is Dictionary else {}
	if bool(app.session.get("extended_campaign")) and not reg.is_empty():
		var reg_num: int = int(app.session.get("region_index")) + 1
		var reg_nome: String = String(reg.get("nome", "O Limiar")).to_upper()
		var rw: int = int(app.session.get("region_wave_index"))
		var camara_txt: String = "CHEFE DA REGIÃO" if rw >= 2 else ("CÂMARA %d / 3" % (rw + 1))
		_text("REGIÃO %d/4 • %s" % [reg_num, reg_nome], Vector2(width - 420, 34), 19, GOLD)
		_text(camara_txt, Vector2(width - 420, 64), 20, PINK if rw >= 2 else BONE)
		_text("%d inimigos restantes" % app.session.enemies.size(), Vector2(width - 420, 94), 17, MUTED)
	else:
		_text("ONDA %d / %d" % [mini(app.session.wave_index+1,app.catalog.data.ondas.size()),app.catalog.data.ondas.size()],Vector2(width-270,46),24,GOLD)
		_text("%d inimigos restantes" % app.session.enemies.size(),Vector2(width-270,82),19,MUTED)
	# Barra de Vida do Chefe no topo central quando houver chefe vivo
	var boss: Dictionary = {}
	for e: Dictionary in app.session.enemies:
		if bool(e.get("is_boss", false)) and float(e.get("hp", 0.0)) > 0.0:
			boss = e
			break
	if not boss.is_empty():
		var b_center: float = width * 0.5
		var b_w: float = 500.0
		var b_x: float = b_center - b_w * 0.5
		var b_nome: String = String(boss.get("boss_name", "Chefe")).to_upper()
		var b_hp: float = float(boss.get("hp", 0.0))
		var b_max: float = maxf(1.0, float(boss.get("max_hp", 1.0)))
		_center(b_nome, 34, 20, GOLD, width)
		draw_rect(Rect2(b_x - 3, 45, b_w + 6, 24), Color("0d0e14"))
		draw_rect(Rect2(b_x, 48, b_w, 18), Color("2d2233"))
		draw_rect(Rect2(b_x, 48, b_w * clampf(b_hp / b_max, 0.0, 1.0), 18), PINK)
		draw_rect(Rect2(b_x - 2, 46, b_w + 4, 22), GOLD, false, 1.5)
		_center("%d / %d" % [ceili(b_hp), roundi(b_max)], 91, 17, BONE, width)
	var recharge: float = float(player.recharge)/maxf(1,roundf(app.catalog.data.esquiva.recarga_s*60))
	if player.charges < player.charge_max:
		draw_rect(Rect2(146,107,114*recharge,3),GOLD)
	for effect in app.session.effects:
		if effect.kind == "dash_denied":
			_text("Esquiva recarregando",Vector2(315,99),17,PINK)
			break

func _controls(width: float) -> void:
	draw_rect(Rect2(0,1013,width,67),Color(0.035,0.04,0.065,0.93))
	var text := "WASD  Mover     Mouse  Mirar     Clique / J  Atacar     Direito / K  Investida     Espaço  Esquiva     Esc  Pausa"
	if app.last_sample.get("source","mouse") != "mouse":
		text = "Analógicos  Mover / Mirar     X  Atacar     Y  Investida     A  Esquiva     Start  Pausa"
	_center(text,1054,20,MUTED,width)

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
	var line := ""
	var y := rect.position.y+size
	for word in text.split(" "):
		var next := word if line.is_empty() else line+" "+word
		if font.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > rect.size.x and not line.is_empty():
			_text(line,Vector2(rect.position.x,y),size,color)
			y += size*1.4
			line = word
		else:
			line = next
	_text(line,Vector2(rect.position.x,y),size,color)
