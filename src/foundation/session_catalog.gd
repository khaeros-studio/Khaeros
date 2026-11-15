extends RefCounted
## Schema for the JSON subset used by the playable integration, not the full MVP catalog.

var data: Dictionary = {}
var errors: Array[String] = []
var fingerprint: String = ""

## Loads atomically; errors leave data and fingerprint empty.
func load_file(path: String) -> bool:
	data.clear()
	errors.clear()
	fingerprint = ""
	if not FileAccess.file_exists(path):
		errors.append("Arquivo não encontrado: " + path)
		return false
	var raw := FileAccess.get_file_as_string(path)
	var parser := JSON.new()
	if parser.parse(raw) != OK or not parser.data is Dictionary:
		errors.append("Configuração JSON inválida.")
		return false
	var candidate: Dictionary = parser.data
	_validate(candidate)
	if not errors.is_empty(): return false
	data = candidate
	fingerprint = raw.sha256_text()
	return true

func _validate(v: Dictionary) -> void:
	_finite(v,"configuração")
	_number(v,"schema_version","configuração",1,1,true)
	_number(v,"profundidade","configuração",0,1000,true)
	_number(v,"wave_transition_s","configuração",0,60,false,true)
	_number(v,"blessing_lock_s","configuração",0,60)
	for section in ["arena","jogador","esquiva","corte","investida","combate","ia","inimigos","elite","camera","input"]:
		if not v.get(section) is Dictionary: errors.append(section+": objeto obrigatório.")
	for section in ["ondas","bencaos"]:
		if not v.get(section) is Array: errors.append(section+": lista obrigatória.")
	if not errors.is_empty(): return
	_number(v.arena,"largura","arena",1920,2880)
	_number(v.arena,"altura","arena",1080,1620)
	if not v.arena.get("pilares") is Array:
		errors.append("arena.pilares: lista obrigatória.")
	else:
		for i in v.arena.pilares.size():
			var item: Variant = v.arena.pilares[i]
			var path := "arena.pilares[%d]" % i
			if not item is Dictionary:
				errors.append(path+": objeto obrigatório.")
				continue
			_number(item,"x",path,0,2880)
			_number(item,"y",path,0,1620)
			_number(item,"r",path,0,500,false,true)
	_number(v.jogador,"vida_max","jogador",0,1000000,false,true)
	_number(v.jogador,"velocidade","jogador",0,10000)
	_number(v.jogador,"raio","jogador",10,50)
	_number(v.jogador,"fator_recuperacao","jogador",0,1)
	if not v.jogador.get("spawn") is Array or v.jogador.get("spawn",[]).size()!=2:
		errors.append("jogador.spawn: dois números obrigatórios.")
	else:
		_number({"x":v.jogador.spawn[0]},"x","jogador.spawn",0,2880)
		_number({"y":v.jogador.spawn[1]},"y","jogador.spawn",0,1620)
	_number(v.esquiva,"duracao_s","esquiva",0.05,0.5)
	_number(v.esquiva,"velocidade_pxs","esquiva",300,3000)
	_number(v.esquiva,"invuln_extra_s","esquiva",0,0.25)
	_number(v.esquiva,"recarga_s","esquiva",0.1,3)
	_number(v.esquiva,"cargas_base","esquiva",1,3,true)
	_fields(v.corte,["dano","alcance_px","recarga_s"],"corte",true)
	_number(v.corte,"empurrao","corte",0,10000)
	_number(v.corte,"meio_angulo_graus","corte",0,180,false,true)
	if not v.corte.get("combo") is Array or v.corte.get("combo",[]).is_empty():
		errors.append("corte.combo: lista não vazia obrigatória.")
	else:
		for i in v.corte.combo.size(): _number({"mult":v.corte.combo[i]},"mult","corte.combo[%d]" % i,0,100,false,true)
	_fields(v.investida,["dano","distancia_px","duracao_s","raio_px","recarga_s"],"investida",true)
	_fields(v.investida,["empurrao","invuln_extra_s"],"investida",false)
	_fields(v.combate,["hitstop_leve_s","hitstop_pesado_s","hitstop_abate_s","hitstop_atingido_s","janela_combo_s","recuperacao_max_s","empurrao_pesado","limiar_finalizador","quebrou_recuperacao_s","flash_acerto_s","invuln_atingido_s"],"combate",true)
	_fields(v.combate,["empurrao_zero","folga_encostado_px","nascimento_projetil_px"],"combate",false)
	_number(v.combate,"fator_recuperacao_golpe","combate",0,1)
	_number(v.combate,"queda_empurrao","combate",0,1)
	_fields(v.ia,["surgimento_s","ranged_perto_px","ranged_longe_px","ranged_ataque_px"],"ia",true)
	for field in ["espera_inicial_base","espera_inicial_extra","espera_base","espera_extra"]: _number(v.ia,field,"ia",0,100000,true)
	_fields(v.elite,["vida_x","dano_x","raio_x"],"elite",true)
	_fields(v.elite,["empurrao_x","vida_por_profundidade"],"elite",false)
	_fields(v.camera,["half_life","mouse_radius","impulse_half_life"],"camera",true)
	_fields(v.camera,["lookahead","shake_max","impulse_kick","impulse_shake","impulse_zoom"],"camera",false)
	_number(v.camera,"zoom_max","camera",1,1.15)
	_number(v.camera,"max_impulses","camera",1,16,true)
	_number(v.camera,"impulse_cutoff","camera",0,1,false,true)
	_number(v.input,"buffer_steps","input",1,30,true)
	_number(v.input,"deadzone","input",0,0.99)
	_number(v.input,"outer_deadzone","input",0,0.99)
	_number(v.input,"auto_aim_radius","input",0,10000,false,true)
	_number(v.input,"mouse_threshold","input",0,100,false,true)
	_number(v.input,"trigger_press","input",0,1,false,true)
	_number(v.input,"trigger_release","input",0,1)
	_enemies(v.inimigos)
	_blessings(v.bencaos)
	_waves(v.ondas,v.inimigos)
	if v.has("presentation"):
		if not v.presentation is Dictionary: errors.append("presentation: objeto obrigatório.")
		else: _number(v.presentation,"delta_max","presentation",0,1,false,true)
	if not errors.is_empty(): return
	# Cross-field checks only read values after all types and shapes are proven.
	if v.input.deadzone+v.input.outer_deadzone>=1: errors.append("input: soma das zonas mortas deve ser menor que 1.")
	if v.input.trigger_release>=v.input.trigger_press: errors.append("input: limiar de soltura deve ser menor que o de aperto.")
	if v.ia.ranged_perto_px>v.ia.ranged_longe_px or v.ia.ranged_longe_px>v.ia.ranged_ataque_px: errors.append("ia: distâncias fora de ordem.")
	_body(Vector2(v.jogador.spawn[0],v.jogador.spawn[1]),v.jogador.raio,v.arena,"jogador.spawn")
	for i in v.arena.pilares.size():
		var obstacle: Dictionary = v.arena.pilares[i]
		if obstacle.x-obstacle.r<0 or obstacle.y-obstacle.r<0 or obstacle.x+obstacle.r>v.arena.largura or obstacle.y+obstacle.r>v.arena.altura: errors.append("arena.pilares[%d]: fora da câmara." % i)
	for wave_index in v.ondas.size():
		for spawn in v.ondas[wave_index]:
			var radius: float = v.inimigos[spawn.id].raio*(v.elite.raio_x if spawn.get("elite",false) else 1.0)
			_body(Vector2(spawn.x,spawn.y),radius,v.arena,"ondas[%d].%s" % [wave_index,spawn.id])

func _enemies(section: Dictionary) -> void:
	for key in section:
		if key not in ["eco_perdido","anomalia_menor"]: errors.append("inimigos.%s: tipo ainda não suportado." % key)
	for key in ["eco_perdido","anomalia_menor"]:
		if not section.get(key) is Dictionary:
			errors.append("inimigos.%s: definição obrigatória." % key)
			continue
		var enemy: Dictionary = section[key]
		var path: String = "inimigos."+key
		_text(enemy,"nome",path)
		var expected := "melee" if key=="eco_perdido" else "ranged"
		if enemy.get("comportamento")!=expected: errors.append(path+".comportamento: esperado "+expected+".")
		_fields(enemy,["vida","raio","dano","preparo_s","recarga_s"],path,true)
		_number(enemy,"velocidade",path,0,10000)
		_number(enemy,"execucao_passos",path,1,10000,true)
		if expected=="melee":
			_fields(enemy,["inicio_preparo_px","tele_raio_px"],path,true)
			_number(enemy,"tele_meio_angulo_graus",path,0,180,false,true)
		else:
			_fields(enemy,["proj_velocidade_pxs","proj_raio_px","tele_largura_px","tele_comprimento_max_px"],path,true)
			_number(enemy,"proj_vida_passos",path,1,100000,true)

func _blessings(values: Array) -> void:
	if values.size()!=3:
		errors.append("bencaos: exatamente três ofertas são necessárias.")
		return
	var ids := ["ataque_mais","carga_mais","corte_esquiva"]
	for i in values.size():
		var item: Variant = values[i]
		var path := "bencaos[%d]" % i
		if not item is Dictionary:
			errors.append(path+": objeto obrigatório.")
			continue
		if item.get("id")!=ids[i]: errors.append(path+".id: esperado "+ids[i]+".")
		_text(item,"nome",path)
		_text(item,"texto",path)
		_number(item,"valor",path,0,1000,i==1,true)
		if i==2: _fields(item,["alcance_extra_px","empurrao"],path,false)

func _waves(values: Array, enemies: Dictionary) -> void:
	if values.size()!=3: errors.append("ondas: esta travessia requer três ondas.")
	for wave_index in values.size():
		var wave: Variant = values[wave_index]
		var path := "ondas[%d]" % wave_index
		if not wave is Array or wave.is_empty():
			errors.append(path+": lista não vazia obrigatória.")
			continue
		for i in wave.size():
			var spawn: Variant = wave[i]
			var spawn_path := path+"[%d]" % i
			if not spawn is Dictionary:
				errors.append(spawn_path+": objeto obrigatório.")
				continue
			if not spawn.get("id") is String or not enemies.has(spawn.get("id","")): errors.append(spawn_path+".id: inimigo desconhecido.")
			_number(spawn,"x",spawn_path,0,2880)
			_number(spawn,"y",spawn_path,0,1620)
			if spawn.has("elite") and not spawn.elite is bool: errors.append(spawn_path+".elite: booleano obrigatório.")

func _body(pos: Vector2, radius: float, arena: Dictionary, path: String) -> void:
	if pos.x-radius<0 or pos.y-radius<0 or pos.x+radius>arena.largura or pos.y+radius>arena.altura: errors.append(path+": corpo fora do retângulo jogável.")
	for obstacle in arena.pilares:
		if pos.distance_squared_to(Vector2(obstacle.x,obstacle.y))<pow(radius+obstacle.r,2): errors.append(path+": corpo começa dentro de um obstáculo.")

func _fields(section: Dictionary, fields: Array, path: String, positive: bool) -> void:
	for field in fields: _number(section,field,path,0,1000000,false,positive)

func _number(section: Dictionary, field: String, path: String, minimum: float, maximum: float, integer: bool=false, strict_minimum: bool=false) -> void:
	var value: Variant = section.get(field)
	if not value is float and not value is int:
		errors.append(path+"."+field+": número obrigatório.")
		return
	var number := float(value)
	if not is_finite(number) or number<minimum or number>maximum or (strict_minimum and number==minimum) or (integer and number!=floorf(number)): errors.append(path+"."+field+": número fora da faixa ou formato permitido.")

func _text(section: Dictionary, field: String, path: String) -> void:
	if not section.get(field) is String or str(section.get(field,"")).strip_edges().is_empty(): errors.append(path+"."+field+": texto obrigatório.")

func _finite(value: Variant, location: String) -> void:
	if value is float and not is_finite(value): errors.append(location+": número não finito.")
	elif value is Dictionary:
		for key in value: _finite(value[key],location+"."+str(key))
	elif value is Array:
		for i in value.size(): _finite(value[i],location+"[%d]" % i)
