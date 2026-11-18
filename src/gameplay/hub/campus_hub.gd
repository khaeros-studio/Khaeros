## CampusHub: gerencia navegação livre no pátio do Campus, zonas interativas e diálogos dos Mestres.
## Implementa design/gdd/campus-hub.md e design/gdd/mestres-ofertantes.md.
class_name CampusHub
extends RefCounted

const LIMITE_CAMPUS := Rect2(120.0, 140.0, 1680.0, 820.0)
const SPAWN_CAMPUS := Vector2(960.0, 760.0)
const RAIO_INTERACAO_PX := 110.0
const VELOCIDADE_BASE := 387.0

const ZONA_OFICINA := &"oficina"
const ZONA_MESTRES := &"mestres"
const ZONA_DOUTRINAS := &"doutrinas"
const ZONA_PORTAL := &"portal"

const ZONAS: Array[Dictionary] = [
	{"id": ZONA_OFICINA, "pos": Vector2(420.0, 420.0), "nome": "Oficina de Reforja"},
	{"id": ZONA_MESTRES, "pos": Vector2(960.0, 320.0), "nome": "Altar dos Mestres"},
	{"id": ZONA_DOUTRINAS, "pos": Vector2(1500.0, 420.0), "nome": "Altar de Doutrinas"},
	{"id": ZONA_PORTAL, "pos": Vector2(960.0, 190.0), "nome": "Portal do Limiar"},
]

const MESTRES: Array[Dictionary] = [
	{
		"id": &"halvar",
		"nome": "Halvar",
		"titulo": "Mestre da Lâmina / Forja",
		"doutrina": &"lamina",
		"falas": [
			"O aço não mente na Beira. Ajuste sua postura antes de cruzar o Portal.",
			"Cada corte limpo poupa fôlego para a câmara seguinte.",
			"Se a lâmina hesitar, o Limiar cobra o peso do erro.",
		],
	},
	{
		"id": &"maren",
		"nome": "Maren",
		"titulo": "Mestra do Selo / Ressonância",
		"doutrina": &"ressonancia",
		"falas": [
			"Meça a distância antes de canalizar. O Fluxo pune quem se precipita.",
			"Ritmo e alcance sustentam mais travessias do que força bruta.",
			"Observe o pulso da Beira; toda anomalia revela seu intervalo.",
		],
	},
	{
		"id": &"oreth",
		"nome": "Oreth",
		"titulo": "Mestre do Véu / Pactos",
		"doutrina": &"pactos",
		"falas": [
			"O que o ferro não alcança, o vínculo sustenta — mas tudo tem custo.",
			"Os ecos do pátio lembram cada juramento feito em silêncio.",
			"Quando descer pelo Portal, lembre-se do que deixou para trás.",
		],
	},
]

var pos: Vector2 = SPAWN_CAMPUS
var prev_pos: Vector2 = SPAWN_CAMPUS
var aim: Vector2 = Vector2.UP
var velocidade: float = VELOCIDADE_BASE

var _indice_mestre: int = 0
var _indices_fala: Array[int] = [0, 0, 0]


func resetar_posicao() -> void:
	pos = SPAWN_CAMPUS
	prev_pos = SPAWN_CAMPUS
	aim = Vector2.UP


func atualizar_movimento(mov: Vector2, dt: float) -> void:
	prev_pos = pos
	if dt <= 0.0:
		return
	var dir := mov
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	if dir.length_squared() > 0.0001:
		aim = dir.normalized()
		pos += dir * velocidade * dt
	pos.x = clampf(pos.x, LIMITE_CAMPUS.position.x, LIMITE_CAMPUS.end.x)
	pos.y = clampf(pos.y, LIMITE_CAMPUS.position.y, LIMITE_CAMPUS.end.y)


func zona_focada() -> StringName:
	var melhor_id := &""
	var menor_dist := RAIO_INTERACAO_PX + 0.001
	for z: Dictionary in ZONAS:
		var z_pos: Vector2 = z["pos"]
		var d := pos.distance_to(z_pos)
		if d <= RAIO_INTERACAO_PX and d < menor_dist:
			menor_dist = d
			melhor_id = z["id"]
	return melhor_id


func nome_zona(id_zona: StringName) -> String:
	for z: Dictionary in ZONAS:
		if z["id"] == id_zona:
			return String(z["nome"])
	return ""


func interagir() -> StringName:
	return zona_focada()


func fala_mestre_atual() -> Dictionary:
	var m: Dictionary = MESTRES[_indice_mestre]
	var falas: Array = m["falas"]
	var idx_fala: int = _indices_fala[_indice_mestre] % falas.size()
	return {
		"id": m["id"],
		"nome": m["nome"],
		"titulo": m["titulo"],
		"fala": falas[idx_fala],
	}


func avancar_mestre() -> void:
	var falas: Array = MESTRES[_indice_mestre]["falas"]
	_indices_fala[_indice_mestre] = (_indices_fala[_indice_mestre] + 1) % falas.size()
	_indice_mestre = (_indice_mestre + 1) % MESTRES.size()
