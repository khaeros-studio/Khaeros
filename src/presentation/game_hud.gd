extends Node2D
## Screen-fixed Portuguese UI with one focus shared by mouse and keyboard/gamepad.

const BONE := Color("e2dccb")
const MUTED := Color("9693a2")
const GOLD := Color("d7b778")
const PINK := Color("ed618f")
const PANEL := Color("11151f")
var app: Node
var font: Font = ThemeDB.fallback_font

## Logical viewport rectangles shared by drawing, hover and confirmation.
func action_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	if app == null or not app.ready_to_play:
		return result
	var center: float = app.camera.width / 2
	match app.session.state:
		"menu":
			result = [Rect2(center-240,580,480,74),Rect2(center-240,677,480,64)]
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
	var width: float = app.camera.width
	var state: String = app.session.state
	if state != "menu":
		_status(width)
	if state == "jogo":
		_controls(width)
	elif state == "transicao":
		var progress: float = app.session.get("transition_progress")
		var opacity := 1.0-absf(progress*2-1)
		draw_rect(Rect2(0,0,width,1080),Color(PANEL,opacity))
	elif state in ["menu","pausa","bencao","morte","vitoria"]:
		draw_rect(Rect2(0,0,width,1080),Color(0.025,0.03,0.05,0.91 if state=="menu" else 0.85))
		var center := width/2
		match state:
			"menu":
				_center("K H A E R O S",300,80,BONE,width)
				_rule(center,342,300)
				_center("A BEIRA COBRA",404,22,GOLD,width)
				_center("Lâmina do Juramento",490,30,BONE,width)
				_center("Atravesse três ondas. Escolha o que levar para a próxima.",535,23,MUTED,width)
				_button(action_rects()[0],"Entrar na Beira",0)
				_button(action_rects()[1],"Redução de movimento: "+("ligada" if app.reduced_motion else "desligada"),1,true)
				_center("VERSÃO JOGÁVEL EM DESENVOLVIMENTO • ARTE PROVISÓRIA",900,18,MUTED,width)
				_controls(width)
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
				_center("O LIMIAR FOI ATRAVESSADO",320,49,BONE,width)
				_rule(center,370,250)
				_center("Você venceu as três ondas desta travessia.",440,25,GOLD,width)
				_summary(width)
				_button(action_rects()[0],"Jogar novamente",0)
				_button(action_rects()[1],"Voltar ao início",1,true)
		if state != "bencao" and state != "menu":
			_center("Setas / direcional para escolher  •  Enter / A para confirmar",950,20,MUTED,width)

func _status(width: float) -> void:
	var player: Dictionary = app.session.player
	if player.is_empty():
		return
	draw_rect(Rect2(0,0,width,145),Color(0.035,0.04,0.065,0.94))
	_text("LÂMINA DO JURAMENTO",Vector2(60,43),20,BONE)
	_text("VIDA",Vector2(60,83),17,MUTED)
	draw_rect(Rect2(125,65,310,19),Color("34313f"))
	draw_rect(Rect2(125,65,310*clampf(float(player.hp)/float(player.max_hp),0,1),19),PINK)
	_text("%d / %d" % [player.hp,player.max_hp],Vector2(451,83),20,BONE)
	_text("ESQUIVA",Vector2(60,123),17,MUTED)
	for i in range(mini(int(player.charge_max),10)):
		var pos := Vector2(165+i*30,115)
		var shape := PackedVector2Array([pos+Vector2(-10,-8),pos+Vector2(0,4),pos+Vector2(10,-8),pos+Vector2(10,0),pos+Vector2(0,12),pos+Vector2(-10,0)])
		draw_colored_polygon(shape,BONE if i<int(player.charges) else Color("3e404d"))
	_text("ONDA %d / %d" % [mini(app.session.wave_index+1,app.catalog.data.ondas.size()),app.catalog.data.ondas.size()],Vector2(width-270,53),25,GOLD)
	_text("%d inimigos restantes" % app.session.enemies.size(),Vector2(width-270,91),20,MUTED)
	var recharge: float = float(player.recharge)/maxf(1,roundf(app.catalog.data.esquiva.recarga_s*60))
	if player.charges < player.charge_max:
		draw_rect(Rect2(154,132,120*recharge,3),GOLD)
	for effect in app.session.effects:
		if effect.kind == "dash_denied":
			_text("Esquiva recarregando",Vector2(330,123),18,PINK)
			break

func _controls(width: float) -> void:
	draw_rect(Rect2(0,1013,width,67),Color(0.035,0.04,0.065,0.93))
	var text := "WASD  Mover     Mouse  Mirar     Clique / J  Atacar     Direito / K  Investida     Espaço  Esquiva     Esc  Pausa"
	if app.last_sample.get("source","mouse") != "mouse":
		text = "Analógicos  Mover / Mirar     X  Atacar     Y  Investida     A  Esquiva     Start  Pausa"
	_center(text,1054,20,MUTED,width)

func _card(rect: Rect2,index: int) -> void:
	var chosen: bool = app.selected == index
	draw_rect(rect,Color("242532") if chosen else PANEL)
	draw_rect(rect,GOLD if chosen else Color("45404b"),false,3 if chosen else 1)
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
	var item: Dictionary = app.catalog.data.bencaos[index]
	_center_in(item.nome,rect.position.y+198,27,BONE,rect)
	_wrapped(item.texto,Rect2(rect.position+Vector2(34,230),Vector2(rect.size.x-68,100)),23,MUTED)
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
