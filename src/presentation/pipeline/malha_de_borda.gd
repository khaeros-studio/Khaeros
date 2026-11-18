class_name MalhaDeBorda
extends RefCounted
## Gerador puro de malhas de borda (`ArrayMesh`) para o contorno dos telégrafos em `z = 5`
## e para o contorno tracejado secundário (R5, R5a, F4, F10; ADR-0011 §5, E4).
## Reduz em ~90% a área sombreada em relação a um quad cheio no círculo C120.

static func criar_quad_preenchimento(forma: int, dims: Vector4, margem: float = 2.0) -> ArrayMesh:
	var rect := caixa_envolvente(forma, dims, margem)
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.end.x
	var y1 := rect.end.y
	var verts := PackedVector2Array([
		Vector2(x0, y0), Vector2(x1, y0),
		Vector2(x1, y1), Vector2(x0, y1),
	])
	var uvs := PackedVector2Array([
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	return _montar_mesh(verts, uvs, indices)


static func caixa_envolvente(forma: int, dims: Vector4, margem: float = 2.0) -> Rect2:
	match forma:
		VisualMathSdf.Forma.CIRCULO:
			var r := dims.x + margem
			return Rect2(Vector2(-r, -r), Vector2(2.0 * r, 2.0 * r))
		VisualMathSdf.Forma.ANEL:
			var r := dims.z + margem
			return Rect2(Vector2(-r, -r), Vector2(2.0 * r, 2.0 * r))
		VisualMathSdf.Forma.RETANGULO:
			var l := dims.x
			var w := dims.y
			return Rect2(Vector2(-margem, -0.5 * w - margem), Vector2(l + 2.0 * margem, w + 2.0 * margem))
		VisualMathSdf.Forma.SETOR:
			var r := dims.x + margem
			return Rect2(Vector2(-r, -r), Vector2(2.0 * r, 2.0 * r))
	return Rect2(Vector2(-122, -122), Vector2(244, 244))


static func criar_malha_borda(
	forma: int,
	dims: Vector4,
	w: float = 4.0,
	margem: float = 2.0,
	raio_secundario: float = 0.0,
	segs: int = 64
) -> ArrayMesh:
	var dados := gerar_geometria_borda(forma, dims, w, margem, raio_secundario, segs)
	return _montar_mesh(dados["vertices"], dados["uvs"], dados["indices"])


static func gerar_geometria_borda(
	forma: int,
	dims: Vector4,
	w: float = 4.0,
	margem: float = 2.0,
	raio_secundario: float = 0.0,
	segs: int = 64
) -> Dictionary:
	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	match forma:
		VisualMathSdf.Forma.CIRCULO:
			_adicionar_anel(verts, uvs, indices, maxf(0.0, dims.x - w - margem), dims.x + margem, segs)
		VisualMathSdf.Forma.ANEL:
			# Borda interna (em r_int) e borda externa (em r_ext)
			_adicionar_anel(verts, uvs, indices, maxf(0.0, dims.y - margem), dims.y + w + margem, segs)
			_adicionar_anel(verts, uvs, indices, maxf(0.0, dims.z - w - margem), dims.z + margem, segs)
		VisualMathSdf.Forma.RETANGULO:
			_adicionar_borda_retangulo(verts, uvs, indices, dims.x, dims.y, w, margem)
		VisualMathSdf.Forma.SETOR:
			_adicionar_borda_setor(verts, uvs, indices, dims.x, dims.w, w, margem, segs)

	if raio_secundario > 0.0:
		_adicionar_anel(verts, uvs, indices, maxf(0.0, raio_secundario - w - margem), raio_secundario + margem, segs)

	return {
		"vertices": verts,
		"uvs": uvs,
		"indices": indices,
	}


static func area_malha(verts: PackedVector2Array, indices: PackedInt32Array) -> float:
	var area := 0.0
	var n_tri := indices.size() / 3
	for i in n_tri:
		var a := verts[indices[i * 3]]
		var b := verts[indices[i * 3 + 1]]
		var c := verts[indices[i * 3 + 2]]
		area += 0.5 * absf((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y))
	return area


static func contem_ponto(verts: PackedVector2Array, indices: PackedInt32Array, p: Vector2) -> bool:
	var n_tri := indices.size() / 3
	for i in n_tri:
		var a := verts[indices[i * 3]]
		var b := verts[indices[i * 3 + 1]]
		var c := verts[indices[i * 3 + 2]]
		if Geometry2D.point_is_inside_triangle(p, a, b, c):
			return true
	return false


static func _adicionar_anel(
	verts: PackedVector2Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	r_in: float,
	r_out: float,
	segs: int
) -> void:
	var base_idx := verts.size()
	for i in range(segs + 1):
		var ang := TAU * float(i) / float(segs)
		var dir := Vector2(cos(ang), sin(ang))
		verts.append(dir * r_in)
		verts.append(dir * r_out)
		var u := float(i) / float(segs)
		uvs.append(Vector2(u, 0.0))
		uvs.append(Vector2(u, 1.0))
		if i < segs:
			var b := base_idx + i * 2
			indices.append_array([b, b + 1, b + 2, b + 1, b + 3, b + 2])


static func _adicionar_borda_retangulo(
	verts: PackedVector2Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	l: float,
	larg: float,
	w: float,
	margem: float
) -> void:
	var base_idx := verts.size()
	var x_out_min := -margem
	var x_out_max := l + margem
	var y_out_min := -0.5 * larg - margem
	var y_out_max := 0.5 * larg + margem

	var x_in_min := w + margem
	var x_in_max := maxf(x_in_min, l - w - margem)
	var y_in_min := -0.5 * larg + w + margem
	var y_in_max := maxf(y_in_min, 0.5 * larg - w - margem)

	var out_pts := [
		Vector2(x_out_min, y_out_min),
		Vector2(x_out_max, y_out_min),
		Vector2(x_out_max, y_out_max),
		Vector2(x_out_min, y_out_max),
		Vector2(x_out_min, y_out_min),
	]
	var in_pts := [
		Vector2(x_in_min, y_in_min),
		Vector2(x_in_max, y_in_min),
		Vector2(x_in_max, y_in_max),
		Vector2(x_in_min, y_in_max),
		Vector2(x_in_min, y_in_min),
	]
	for i in 5:
		verts.append(in_pts[i])
		verts.append(out_pts[i])
		uvs.append(Vector2(float(i) / 4.0, 0.0))
		uvs.append(Vector2(float(i) / 4.0, 1.0))
		if i < 4:
			var b := base_idx + i * 2
			indices.append_array([b, b + 1, b + 2, b + 1, b + 3, b + 2])


static func _adicionar_borda_setor(
	verts: PackedVector2Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	r: float,
	alpha: float,
	w: float,
	margem: float,
	segs: int
) -> void:
	var sa := maxf(sin(alpha), 0.15)
	# 1. Faixa do arco circular externo
	var base_arco := verts.size()
	var r_in := maxf(0.0, r - w - margem)
	var r_out := r + margem
	var α_ext := minf(PI, alpha + (w + margem) / maxf(r_in, 1.0))
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var ang := lerpf(-α_ext, α_ext, t)
		var dir := Vector2(cos(ang), sin(ang))
		verts.append(dir * r_in)
		verts.append(dir * r_out)
		uvs.append(Vector2(t, 0.0))
		uvs.append(Vector2(t, 1.0))
		if i < segs:
			var b := base_arco + i * 2
			indices.append_array([b, b + 1, b + 2, b + 1, b + 3, b + 2])

	# 2. Duas faixas retangulares ao longo dos raios laterais (+alpha e -alpha), cobrindo o ápice
	var recuo_apice := (w + margem) / sa + margem
	for sgn in [-1.0, 1.0]:
		var ang_lado := sgn * alpha
		var dir := Vector2(cos(ang_lado), sin(ang_lado))
		var n_out := Vector2(sin(ang_lado) * sgn, -cos(ang_lado) * sgn) # normal apontando para fora do setor
		var p0 := -dir * recuo_apice
		var p1 := dir * (r + margem)
		var v0 := p0 - n_out * (w + margem)
		var v1 := p0 + n_out * margem
		var v2 := p1 + n_out * margem
		var v3 := p1 - n_out * (w + margem)
		var b_lado := verts.size()
		verts.append_array([v0, v1, v2, v3])
		uvs.append_array([Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)])
		indices.append_array([b_lado, b_lado + 1, b_lado + 2, b_lado, b_lado + 2, b_lado + 3])


static func _montar_mesh(verts: PackedVector2Array, uvs: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh
