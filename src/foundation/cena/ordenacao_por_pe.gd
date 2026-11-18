class_name OrdenacaoPorPe
extends RefCounted
## Ordenação explícita da camada de objetos e personagens (GDD Cena R5, ADR-0007 §5).
##
## Chave total e estável: `(pé.y, ordinal_de_criacao)`; quem tem pé mais baixo na
## tela (y maior) fica na frente, e no empate quem nasceu depois fica na frente.
## O pé é o ponto de apoio interpolado (centro da sombra de contato); a elevação
## aparente (voo de projétil, salto visual) nunca entra na chave.
##
## A instância guarda a última ordem calculada, para o compositor só mexer na
## ordem de irmãos quando ela muda. Sem alocação por quadro além do primeiro
## crescimento dos arrays internos. Não é thread-safe.
##
## Exemplo:
## [codeblock]
## var ord := OrdenacaoPorPe.new()
## ord.definir(0, Vector2(100, 500), registro.ordinal_de(id_a))
## ord.definir(1, Vector2(140, 520), registro.ordinal_de(id_b))
## if ord.ordenar(2):            # true quando a ordem mudou
##     for i in 2: mover_ancora(ord.indice_na_posicao(i), i)
## [/codeblock]


## Item de ordenação: valores já resolvidos entregues à Cena.
class Item:
	extends RefCounted
	## Pé interpolado (px de mundo).
	var pe: Vector2
	## Ordinal do `RegistroDeCriacaoVisual`.
	var ordinal: int
	## Deslocamento visual do sprite em relação ao pé. Ignorado pela ordenação.
	var deslocamento_visual: Vector2


var _itens: Array[Item] = []
var _ordem: Array[int] = []
var _ordem_anterior: Array[int] = []
var _n: int = 0
var _chaves: Array = []


## Chave comparável: `a` fica atrás de `b` (desenhado antes) quando devolve true.
static func atras_de(pe_a: Vector2, ordinal_a: int, pe_b: Vector2, ordinal_b: int) -> bool:
	if pe_a.y != pe_b.y:
		return pe_a.y < pe_b.y
	return ordinal_a < ordinal_b


## Pé de um objeto grande (Anomalia Maior etc.): centro da base do retângulo de
## apoio em px de mundo.
static func pe_de_objeto_grande(base: Rect2) -> Vector2:
	return Vector2(base.get_center().x, base.end.y)


## Pé de um projétil: a posição da sombra no chão; o deslocamento visual é ignorado.
static func pe_de_projetil(posicao_chao: Vector2, _deslocamento_visual: Vector2) -> Vector2:
	return posicao_chao


## Define o item no índice `indice` (0..n−1) para o próximo [method ordenar].
func definir(indice: int, pe: Vector2, ordinal: int, deslocamento_visual: Vector2 = Vector2.ZERO) -> void:
	while _itens.size() <= indice:
		_itens.append(Item.new())
	var it := _itens[indice]
	it.pe = pe
	it.ordinal = ordinal
	it.deslocamento_visual = deslocamento_visual


## Ordena os `n` primeiros itens; devolve true se a ordem difere da última.
func ordenar(n: int) -> bool:
	_n = n
	_ordem_anterior.assign(_ordem)
	# Ordenação nativa (sem comparador GDScript): Vector3 compara x, depois y,
	# depois z. Chave (pé.y, ordinal, índice). Ordinais são exatos em float32 até
	# 2^24 criações por run.
	_chaves.resize(n)
	for i in n:
		var it := _itens[i]
		_chaves[i] = Vector3(it.pe.y, float(it.ordinal), float(i))
	_chaves.sort()
	_ordem.resize(n)
	for i in n:
		_ordem[i] = int((_chaves[i] as Vector3).z)
	return _ordem != _ordem_anterior


## Índice do item desenhado na posição `posicao` (0 = mais atrás).
func indice_na_posicao(posicao: int) -> int:
	return _ordem[posicao]


## Cópia da ordem atual (índices de item, de trás para a frente).
func ordem() -> Array[int]:
	return _ordem.duplicate()


func _comparar(a: int, b: int) -> bool:
	var ia := _itens[a]
	var ib := _itens[b]
	return atras_de(ia.pe, ia.ordinal, ib.pe, ib.ordinal)
