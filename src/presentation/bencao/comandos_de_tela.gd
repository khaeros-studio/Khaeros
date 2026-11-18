class_name ComandosDeTela
extends RefCounted
## Amostra tipada de comandos de entrada para telas da camada de Apresentação (`ADR-0012 §4`).
## Nenhuma tela lê `Input` ou `InputEvent` diretamente.

var navegar: Vector2i = Vector2i.ZERO
var aceitar: bool = false
var voltar: bool = false
var carta_direta: int = -1 # 0, 1 ou 2 para atalhos 1/2/3 (-1 = nenhum)
var trocar: bool = false # tecla R / botão de Trocar Ofertas
var pausar: bool = false
var mouse_moveu: bool = false
var cursor_pos: Vector2 = Vector2.ZERO
var clicou: bool = false
var clique_pos: Vector2 = Vector2.ZERO
var aperto_apos_abertura: bool = true # barreira contra botão segurado desde antes da abertura


func limpar() -> void:
	navegar = Vector2i.ZERO
	aceitar = false
	voltar = false
	carta_direta = -1
	trocar = false
	pausar = false
	mouse_moveu = false
	cursor_pos = Vector2.ZERO
	clicou = false
	clique_pos = Vector2.ZERO
	aperto_apos_abertura = true
