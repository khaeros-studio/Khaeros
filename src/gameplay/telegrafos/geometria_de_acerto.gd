class_name GeometriaDeAcerto
extends RefCounted
## Geometria pura de acerto compartilhada entre Telégrafos, Combate e IA (ADR-0010 §9, ADR-0014 Decisão 4).
## Comparações exatas de distância ao quadrado, sem consultar física da engine.


## Círculo contra círculo (inclusivo: |d|² ≤ (raio + r_alvo)²).
static func circulo_toca(centro: Vector2, raio: float, alvo: Vector2, r_alvo: float) -> bool:
	var r_tot := maxf(0.0, raio + r_alvo)
	return (alvo - centro).length_squared() <= r_tot * r_tot + 1e-5


## Anel contra ponto/círculo (inclusivo: r_int ≤ |d| ≤ r_ext + r_alvo).
static func anel_toca(centro: Vector2, r_int: float, r_ext: float, alvo: Vector2, r_alvo: float = 0.0) -> bool:
	var d2 := (alvo - centro).length_squared()
	var r_max := maxf(0.0, r_ext + r_alvo)
	var r_min := maxf(0.0, r_int - r_alvo)
	return d2 <= r_max * r_max + 1e-5 and d2 >= r_min * r_min - 1e-5


## Setor circular contra círculo (F2: |d| ≤ alcance + r_alvo e dir · u ≥ cos_meio; d == 0 conta dentro).
static func setor_toca(origem: Vector2, dir: Vector2, cos_meio: float, alcance: float,
		alvo: Vector2, r_alvo: float = 0.0) -> bool:
	var delta := alvo - origem
	var d2 := delta.length_squared()
	var r_tot := maxf(0.0, alcance + r_alvo)
	if d2 > r_tot * r_tot + 1e-5:
		return false
	if d2 == 0.0:
		return true
	var d := sqrt(d2)
	var u := delta / d
	var dir_norm := Vector2.RIGHT if dir.length_squared() == 0.0 else dir.normalized()
	return dir_norm.dot(u) >= cos_meio - 1e-6


## Arco de golpe (F4 do Combate: setor OU d < r_alvo + raio_encostado estrito).
static func arco_do_golpe(origem: Vector2, mira: Vector2, cos_meio: float, alcance: float,
		raio_encostado: float, alvo: Vector2, r_alvo: float) -> bool:
	var d2 := (alvo - origem).length_squared()
	var r_enc := maxf(0.0, r_alvo + raio_encostado)
	if d2 < r_enc * r_enc:
		return true
	return setor_toca(origem, mira, cos_meio, alcance, alvo, r_alvo)


## Retângulo orientado contra círculo (com r_alvo = 0, testa se o ponto está dentro de [-meio_comp..meio_comp] × [-meia_larg..meia_larg]).
static func retangulo_orientado_toca(centro: Vector2, dir: Vector2, meio_comp: float, meia_larg: float,
		alvo: Vector2, r_alvo: float = 0.0) -> bool:
	var eixo_x := Vector2.RIGHT if dir.length_squared() == 0.0 else dir.normalized()
	var eixo_y := Vector2(-eixo_x.y, eixo_x.x)
	var rel := alvo - centro
	var lx := absf(rel.dot(eixo_x))
	var ly := absf(rel.dot(eixo_y))
	if r_alvo <= 0.0:
		return lx <= meio_comp + 1e-5 and ly <= meia_larg + 1e-5
	var dx := maxf(0.0, lx - meio_comp)
	var dy := maxf(0.0, ly - meia_larg)
	return dx * dx + dy * dy <= r_alvo * r_alvo + 1e-5


## Contato círculo-círculo estrito (|d|² < r_soma²; F4 avanço AC-TG-12).
static func circulos_encostam(a: Vector2, b: Vector2, r_soma: float) -> bool:
	if r_soma <= 0.0:
		return false
	return (a - b).length_squared() < r_soma * r_soma


## Gira vetor por graus (positivo = horário, y para baixo).
static func girar_graus(v: Vector2, graus: float) -> Vector2:
	return v.rotated(deg_to_rad(graus))


## Alcance da linha central até a borda do retângulo jogável ou superfície do 1º obstáculo circular (AC-TG-09).
static func alcance_do_raio(origem: Vector2, dir: Vector2, l_max: float, retangulo: Rect2,
		obstaculos: Array = []) -> float:
	if l_max <= 0.0:
		return 0.0
	var u := Vector2.RIGHT if dir.length_squared() == 0.0 else dir.normalized()
	var melhor := l_max
	if retangulo.size.x > 0.0 and retangulo.size.y > 0.0:
		var t_parede := _intersecao_raio_retangulo(origem, u, retangulo)
		if t_parede >= 0.0 and t_parede < melhor:
			melhor = t_parede
	for obs: Variant in obstaculos:
		var centro_obs := Vector2.ZERO
		var raio_obs := 0.0
		if obs is ObstaculoCircular:
			centro_obs = (obs as ObstaculoCircular).centro
			raio_obs = (obs as ObstaculoCircular).raio
		elif obs is Vector3:
			var v3 := obs as Vector3
			centro_obs = Vector2(v3.x, v3.y)
			raio_obs = v3.z
		elif obs is Dictionary:
			var d := obs as Dictionary
			centro_obs = d.get("centro", Vector2.ZERO)
			raio_obs = float(d.get("raio", 0.0))
		if raio_obs <= 0.0:
			continue
		var t_obs := _intersecao_raio_circulo(origem, u, centro_obs, raio_obs)
		if t_obs >= 0.0 and t_obs < melhor:
			melhor = t_obs
	return maxf(0.0, melhor)


static func _intersecao_raio_retangulo(origem: Vector2, u: Vector2, r: Rect2) -> float:
	var t_min := INF
	if absf(u.x) > 1e-8:
		var tx1 := (r.position.x - origem.x) / u.x
		var tx2 := (r.end.x - origem.x) / u.x
		for tx: float in [tx1, tx2]:
			if tx >= 0.0:
				var y := origem.y + u.y * tx
				if y >= r.position.y - 1e-4 and y <= r.end.y + 1e-4:
					t_min = minf(t_min, tx)
	if absf(u.y) > 1e-8:
		var ty1 := (r.position.y - origem.y) / u.y
		var ty2 := (r.end.y - origem.y) / u.y
		for ty: float in [ty1, ty2]:
			if ty >= 0.0:
				var x := origem.x + u.x * ty
				if x >= r.position.x - 1e-4 and x <= r.end.x + 1e-4:
					t_min = minf(t_min, ty)
	return -1.0 if is_inf(t_min) else t_min


static func _intersecao_raio_circulo(origem: Vector2, u: Vector2, centro: Vector2, raio: float) -> float:
	var m := origem - centro
	var b := m.dot(u)
	var c := m.dot(m) - raio * raio
	if c <= 0.0:
		return 0.0
	if b > 0.0:
		return -1.0
	var disc := b * b - c
	if disc < 0.0:
		return -1.0
	var t := -b - sqrt(disc)
	return t if t >= 0.0 else -1.0
