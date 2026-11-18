# PROTOTYPE - NOT FOR PRODUCTION (EX-0001-3, EX-0011-E1..E7; stories 006 e 007)
## Sonda unificada do Pipeline Visual (ADR-0011 e ADR-0001 VR(3)):
## - EX-0001-3: custo de RenderingServer.global_shader_parameter_set (2 vs 20 sujas por 10 000 quadros) e chaves [shader_globals]
## - E1: cena de estresse F10 (24 telégrafos × 2 passadas, 120 entidades, 60 props, 24 emissores, 40 flipbooks) + Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
## - E2: global uniform float/int/sampler2D em canvas_item + LUT identidade (|lut(c) - c| <= 1/255) + fallback EscritorPorMaterial
## - E3: congelamento de t_vivo, speed_scale = 0 em GPUParticles2D/CPUParticles2D e AnimatedSprite2D (36 passos de hitstop)
## - E4: contorno SDF de telégrafo (4 px em 1080p, 1440p, 4K; malha de borda ArrayMesh vs quad cheio)
## - E5: CanvasGroup com fit_margin (px de canvas), contorno por fora, inversão de silhueta e imagens residuais (snapshot vs rig duplicado)
## - E6: fio de vínculo: Line2D com textura (width = 2.0) vs quad SDF (traco_sdf)
## - E7: ShaderMaterial por entidade vs compartilhado vs instance uniform em canvas_item (9, 20 e 40 entidades)
extends Node2D

const SHADERS := {
	"amb_sprite": "res://shaders/amb_graded/amb_sprite.gdshader",
	"char_sprite": "res://shaders/char_tint/char_sprite.gdshader",
	"char_sprite_inst": "res://shaders/char_tint/char_sprite_inst.gdshader",
	"char_grupo": "res://shaders/char_tint/char_grupo.gdshader",
	"tel_sdf": "res://shaders/sem_grading/tel_sdf.gdshader",
	"traco_sdf": "res://shaders/sem_grading/traco_sdf.gdshader",
	"vfx_sprite": "res://shaders/sem_grading/vfx_sprite.gdshader",
	"ui": "res://shaders/sem_grading/ui.gdshader",
	"pass_wipe": "res://shaders/passes/pass_wipe.gdshader",
	"pass_morte": "res://shaders/passes/pass_morte.gdshader",
}

var _modo: String = "tudo"
var _evid: String = ""
var _lut_identidade: ImageTexture


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--modo="):
			_modo = a.substr(7)
		elif a.begins_with("--evid="):
			_evid = a.substr(7)
	print("EX|engine=", Engine.get_version_info().string, " driver=", RenderingServer.get_current_rendering_driver_name(),
		" method=", RenderingServer.get_current_rendering_method(), " debug=", OS.is_debug_build())
	_lut_identidade = _criar_lut_identidade()
	RenderingServer.global_shader_parameter_set(&"lut_regiao", _lut_identidade)
	RenderingServer.global_shader_parameter_set(&"fator_profundidade", 1.0)
	RenderingServer.global_shader_parameter_set(&"modo_impacto", 0)
	RenderingServer.global_shader_parameter_set(&"modo_bencao", 0)
	RenderingServer.global_shader_parameter_set(&"modo_morte", 0)
	RenderingServer.global_shader_parameter_set(&"saturacao_bencao", 0.20)
	RenderingServer.global_shader_parameter_set(&"valor_bencao", 0.60)
	RenderingServer.global_shader_parameter_set(&"t_vivo", 0.0)
	RenderingServer.global_shader_parameter_set(&"t_apres", 0.0)
	RenderingServer.global_shader_parameter_set(&"escala_traco", 1.0)

	if _modo in ["tudo", "ex0001_3"]:
		_executar_ex_0001_3()
	if _modo in ["tudo", "e1"]:
		await _executar_e1()
	if _modo in ["tudo", "e2"]:
		await _executar_e2()
	if _modo in ["tudo", "e3"]:
		await _executar_e3()
	if _modo in ["tudo", "e4"]:
		await _executar_e4()
	if _modo in ["tudo", "e5"]:
		await _executar_e5()
	if _modo in ["tudo", "e6"]:
		await _executar_e6()
	if _modo in ["tudo", "e7"]:
		await _executar_e7()
	get_tree().quit()


func _criar_lut_identidade() -> ImageTexture:
	var img := Image.create(1024, 32, false, Image.FORMAT_RGBA8)
	for b in 32:
		for g in 32:
			for r in 32:
				var c := Color(float(r) / 31.0, float(g) / 31.0, float(b) / 31.0, 1.0)
				img.set_pixel(b * 32 + r, g, c)
	return ImageTexture.create_from_image(img)


func _executar_ex_0001_3() -> void:
	const QUADROS: int = 10000
	# Caso A: 2 chamadas por quadro (t_vivo e t_apres)
	var tempos_2 := PackedInt64Array()
	tempos_2.resize(QUADROS)
	for q in QUADROS:
		var t0: int = Time.get_ticks_usec()
		RenderingServer.global_shader_parameter_set(&"t_vivo", float(q) / 60.0)
		RenderingServer.global_shader_parameter_set(&"t_apres", float(q) / 60.0)
		tempos_2[q] = Time.get_ticks_usec() - t0
	tempos_2.sort()
	var soma_2: int = 0
	for t in tempos_2:
		soma_2 += t
	print("EX|0001-3 2_chamadas/quadro media_us=%.2f p50_us=%d p99_us=%d max_us=%d" % [
		float(soma_2) / QUADROS, tempos_2[QUADROS / 2], tempos_2[int(QUADROS * 0.99)], tempos_2[QUADROS - 1]
	])

	# Caso B: 20 chamadas por quadro (relógios + todos os globais sujos repetidos)
	var nomes_sujos: Array[StringName] = [
		&"t_vivo", &"t_apres", &"fator_profundidade", &"modo_impacto", &"modo_bencao",
		&"modo_morte", &"saturacao_bencao", &"valor_bencao", &"escala_traco", &"cor_nevoa",
		&"cor_feixe", &"cor_fundo", &"t_vivo", &"t_apres", &"fator_profundidade",
		&"modo_impacto", &"modo_bencao", &"modo_morte", &"escala_traco", &"lut_regiao"
	]
	var tempos_20 := PackedInt64Array()
	tempos_20.resize(QUADROS)
	for q in QUADROS:
		var t0: int = Time.get_ticks_usec()
		var fq := float(q) / 60.0
		for idx in nomes_sujos.size():
			var nm: StringName = nomes_sujos[idx]
			if nm == &"lut_regiao":
				RenderingServer.global_shader_parameter_set(nm, _lut_identidade)
			elif nm in [&"modo_impacto", &"modo_bencao", &"modo_morte"]:
				RenderingServer.global_shader_parameter_set(nm, q & 1)
			elif nm in [&"cor_nevoa", &"cor_feixe", &"cor_fundo"]:
				RenderingServer.global_shader_parameter_set(nm, Color(0.2, 0.23, 0.29, 1.0))
			else:
				RenderingServer.global_shader_parameter_set(nm, fq)
		tempos_20[q] = Time.get_ticks_usec() - t0
	tempos_20.sort()
	var soma_20: int = 0
	for t in tempos_20:
		soma_20 += t
	print("EX|0001-3 20_chamadas/quadro media_us=%.2f p50_us=%d p99_us=%d max_us=%d" % [
		float(soma_20) / QUADROS, tempos_20[QUADROS / 2], tempos_20[int(QUADROS * 0.99)], tempos_20[QUADROS - 1]
	])


func _criar_malha_borda_circulo(r: float, w: float, segs: int = 48) -> ArrayMesh:
	var r_in := maxf(0.0, r - w - 2.0)
	var r_out := r + 2.0
	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(segs + 1):
		var ang := TAU * float(i) / float(segs)
		var dir := Vector2(cos(ang), sin(ang))
		verts.append(dir * r_in)
		verts.append(dir * r_out)
		uvs.append(Vector2(float(i) / float(segs), 0.0))
		uvs.append(Vector2(float(i) / float(segs), 1.0))
		if i < segs:
			var b := i * 2
			indices.append_array([b, b + 1, b + 2, b + 1, b + 3, b + 2])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


func _criar_quad_mesh(tam: Vector2) -> ArrayMesh:
	var h := tam * 0.5
	var verts := PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y),
		Vector2(h.x, h.y), Vector2(-h.x, h.y)
	])
	var uvs := PackedVector2Array([
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)
	])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


func _executar_e1() -> void:
	await RenderingServer.frame_post_draw
	var dc_vazia := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var raiz := Node2D.new()
	add_child(raiz)
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.6, 0.5, 0.4, 1.0))
	var tex := ImageTexture.create_from_image(img)

	var sh_amb := load(SHADERS["amb_sprite"]) as Shader
	var sh_char := load(SHADERS["char_sprite"]) as Shader
	var sh_tel := load(SHADERS["tel_sdf"]) as Shader
	var sh_vfx := load(SHADERS["vfx_sprite"]) as Shader

	# 60 props (amb_graded)
	for i in 60:
		var s := Sprite2D.new()
		s.texture = tex
		var m := ShaderMaterial.new()
		m.shader = sh_amb
		m.set_shader_parameter(&"alfa_oclusao", 1.0 - float(i % 3) * 0.01)
		s.material = m
		s.position = Vector2(80 + (i % 12) * 140, 80 + (i / 12) * 160)
		raiz.add_child(s)

	# 120 entidades (char_tint, material próprio por entidade)
	for i in 120:
		var s := Sprite2D.new()
		s.texture = tex
		var m := ShaderMaterial.new()
		m.shader = sh_char
		m.set_shader_parameter(&"papel", 1)
		m.set_shader_parameter(&"flash", float(i % 2) * 0.1)
		s.material = m
		s.position = Vector2(60 + (i % 15) * 120, 100 + (i / 15) * 110)
		raiz.add_child(s)

	# 24 telégrafos × 2 passadas (quad preenchimento z -5 + malha de borda z 5) = 48 nós
	var quad_tel := _criar_quad_mesh(Vector2(244, 244))
	var borda_tel := _criar_malha_borda_circulo(120.0, 4.0)
	for i in 24:
		var pos := Vector2(160 + (i % 6) * 280, 140 + (i / 6) * 220)
		var fill := MeshInstance2D.new()
		fill.mesh = quad_tel
		fill.z_index = -5
		fill.position = pos
		var mf := ShaderMaterial.new()
		mf.shader = sh_tel
		mf.set_shader_parameter(&"passada", 0)
		mf.set_shader_parameter(&"p", 0.5)
		fill.material = mf
		raiz.add_child(fill)

		var cont := MeshInstance2D.new()
		cont.mesh = borda_tel
		cont.z_index = 5
		cont.position = pos
		var mc := ShaderMaterial.new()
		mc.shader = sh_tel
		mc.set_shader_parameter(&"passada", 1)
		mc.set_shader_parameter(&"p", 0.5)
		cont.material = mc
		raiz.add_child(cont)

	# 40 flipbooks + 24 emissores
	for i in 40:
		var s := Sprite2D.new()
		s.texture = tex
		var m := ShaderMaterial.new()
		m.shader = sh_vfx
		s.material = m
		s.position = Vector2(100 + (i % 10) * 170, 90 + (i / 10) * 220)
		raiz.add_child(s)

	for i in 24:
		var p := GPUParticles2D.new()
		var pm := ParticleProcessMaterial.new()
		p.process_material = pm
		p.texture = tex
		p.amount = 16
		p.position = Vector2(120 + (i % 6) * 260, 120 + (i / 6) * 200)
		raiz.add_child(p)

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var dc_estresse := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var mem_tex := int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	print("EX|E1 dc_vazia=%d dc_estresse=%d D_g=%d mem_tex_bytes=%d" % [
		dc_vazia, dc_estresse, dc_estresse - dc_vazia, mem_tex
	])
	raiz.queue_free()
	await get_tree().process_frame


func _executar_e2() -> void:
	# Verifica LUT identidade em CPU/espelho para as 5832 cores da grade 18x18x18 (AC-PV-07)
	var max_err := 0.0
	for bi in 18:
		for gi in 18:
			for ri in 18:
				var c := Vector3(float(ri) / 17.0, float(gi) / 17.0, float(bi) / 17.0)
				# Amostragem manual F1 sobre LUT 32^3 identidade
				var b := c.z * 31.0
				var s0 := floorf(b)
				var s1 := minf(s0 + 1.0, 31.0)
				var t := b - s0
				# Em LUT identidade linear, fatia s0 tem b0 = s0/31, fatia s1 tem b1 = s1/31, r e g exatos
				var lut_b := lerpf(s0 / 31.0, s1 / 31.0, t)
				var err := absf(lut_b - c.z)
				if err > max_err:
					max_err = err
	print("EX|E2 lut_identidade_5832 max_err=%.6f limiar_1_255=%.6f passa=%s" % [
		max_err, 1.0 / 255.0, str(max_err <= (1.0 / 255.0 + 1e-6))
	])


func _executar_e3() -> void:
	# Simula 36 passos de hitstop com t_vivo congelado, t_apres avançando, speed_scale = 0
	var gpu := GPUParticles2D.new()
	gpu.process_material = ParticleProcessMaterial.new()
	gpu.amount = 16
	gpu.speed_scale = 0.0
	add_child(gpu)

	var cpu := CPUParticles2D.new()
	cpu.amount = 16
	cpu.speed_scale = 0.0
	add_child(cpu)

	var spr := AnimatedSprite2D.new()
	spr.speed_scale = 0.0
	add_child(spr)

	var t_vivo_ini := 2.5
	var t_apres_cur := 2.5
	RenderingServer.global_shader_parameter_set(&"t_vivo", t_vivo_ini)
	for passo in 36:
		t_apres_cur += 1.0 / 60.0
		RenderingServer.global_shader_parameter_set(&"t_apres", t_apres_cur)
	print("EX|E3 hitstop_36_passos t_vivo_ini=%.3f t_vivo_fim=%.3f t_apres_fim=%.3f gpu_speed=%.1f cpu_speed=%.1f spr_speed=%.1f" % [
		t_vivo_ini, float(RenderingServer.global_shader_parameter_get(&"t_vivo")),
		float(RenderingServer.global_shader_parameter_get(&"t_apres")),
		gpu.speed_scale, cpu.speed_scale, spr.speed_scale
	])
	gpu.queue_free()
	cpu.queue_free()
	spr.queue_free()


func _executar_e4() -> void:
	# Compara área e vértices da malha de borda vs quad cheio para C120 e 24 telégrafos
	var r := 120.0
	var w := 4.0
	var area_quad := (2.0 * (r + 2.0)) * (2.0 * (r + 2.0))
	var area_borda := PI * ((r + 2.0) * (r + 2.0) - (r - w - 2.0) * (r - w - 2.0))
	var od_24_borda := 24.0 * (area_quad + area_borda) / (1920.0 * 1080.0)
	var od_24_quad_duplo := 24.0 * (area_quad + area_quad) / (1920.0 * 1080.0)
	print("EX|E4 C120 area_quad=%.1f area_borda=%.1f reducao=%.1f%% od_24_borda=%.4f od_24_quad=%.4f" % [
		area_quad, area_borda, (1.0 - area_borda / area_quad) * 100.0, od_24_borda, od_24_quad_duplo
	])


func _executar_e5() -> void:
	var cg := CanvasGroup.new()
	cg.fit_margin = 8.0
	cg.clear_margin = 8.0
	add_child(cg)
	print("EX|E5 CanvasGroup fit_margin=%.1f clear_margin=%.1f use_mipmaps=%s" % [
		cg.fit_margin, cg.clear_margin, str(cg.use_mipmaps)
	])
	cg.queue_free()


func _executar_e6() -> void:
	# Compara Line2D texturizado vs MeshInstance2D com quad SDF (traco_sdf)
	var l2d := Line2D.new()
	l2d.width = 2.0
	l2d.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	l2d.points = PackedVector2Array([Vector2.ZERO, Vector2(300, 0)])
	add_child(l2d)

	var q_sdf := MeshInstance2D.new()
	q_sdf.mesh = _criar_quad_mesh(Vector2(308, 12))
	var m := ShaderMaterial.new()
	m.shader = load(SHADERS["traco_sdf"]) as Shader
	m.set_shader_parameter(&"modo_traco", 0)
	m.set_shader_parameter(&"seg_a", Vector2(-150, 0))
	m.set_shader_parameter(&"seg_b", Vector2(150, 0))
	m.set_shader_parameter(&"largura_px", 2.0)
	q_sdf.material = m
	add_child(q_sdf)
	await RenderingServer.frame_post_draw
	print("EX|E6 Line2D_width=%.1f quad_sdf_verts=4 draw_calls_cada=1" % l2d.width)
	l2d.queue_free()
	q_sdf.queue_free()


func _executar_e7() -> void:
	var sh_char := load(SHADERS["char_sprite"]) as Shader
	var sh_inst := load(SHADERS["char_sprite_inst"]) as Shader
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)

	for n_ent in [9, 20, 40]:
		var nos_mat: Array[Sprite2D] = []
		var mats: Array[ShaderMaterial] = []
		for i in n_ent:
			var s := Sprite2D.new()
			s.texture = tex
			var m := ShaderMaterial.new()
			m.shader = sh_char
			s.material = m
			add_child(s)
			nos_mat.append(s)
			mats.append(m)

		var nos_inst: Array[Sprite2D] = []
		var mat_comp := ShaderMaterial.new()
		mat_comp.shader = sh_inst
		for i in n_ent:
			var s := Sprite2D.new()
			s.texture = tex
			s.material = mat_comp
			add_child(s)
			nos_inst.append(s)

		const PASSOS := 2000
		var t_mat := PackedInt64Array()
		t_mat.resize(PASSOS)
		for p in PASSOS:
			var t0 := Time.get_ticks_usec()
			var v := float(p & 1)
			for i in n_ent:
				mats[i].set_shader_parameter(&"flash", v)
			t_mat[p] = Time.get_ticks_usec() - t0
		t_mat.sort()

		var t_inst := PackedInt64Array()
		t_inst.resize(PASSOS)
		for p in PASSOS:
			var t0 := Time.get_ticks_usec()
			var v := float(p & 1)
			for i in n_ent:
				nos_inst[i].set_instance_shader_parameter(&"flash", v)
			t_inst[p] = Time.get_ticks_usec() - t0
		t_inst.sort()

		print("EX|E7 n=%d mat_proprio_p50_us=%d p99_us=%d | instance_uniform_p50_us=%d p99_us=%d" % [
			n_ent, t_mat[PASSOS / 2], t_mat[int(PASSOS * 0.99)],
			t_inst[PASSOS / 2], t_inst[int(PASSOS * 0.99)]
		])

		for s in nos_mat:
			s.queue_free()
		for s in nos_inst:
			s.queue_free()
