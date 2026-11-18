class_name CamadasDoMundo
extends Node2D
## Módulo de camadas da Cena (GDD Cena R4/R5, ADR-0007 §4–§5): a raiz `Mundo`.
##
## É o **único** código que atribui `z_index`, ordem de irmãos e parallax. Monta
## as nove camadas de mundo (z absolutos −30…10, `z_as_relative = false`,
## `y_sort_enabled = false`) e os dois canvases presos à tela, Pós (layer 50) e
## UI (layer 100), sem seguir o viewport. Todo item desenhado entra por
## [method registrar] em exatamente uma camada; o código de jogo escolhe a
## camada pelo nome do enum e nunca mexe em z nem em parallax.
##
## A camada de objetos e personagens guarda âncoras (uma por entidade) ordenadas
## por `(pé.y, ordinal)` via [OrdenacaoPorPe]; a ordem de irmãos só muda quando a
## ordem calculada muda. Thread: só a principal.
##
## Exemplo:
## [codeblock]
## var camadas := CamadasDoMundo.new()
## add_child(camadas)               # monta as camadas em _init
## camadas.registrar(sprite_chao, CamadasDoMundo.Camada.CHAO)
## var ancora := camadas.registrar_ancora(id_entidade)   # ordinal já registrado
## ancora.add_child(sprite_do_inimigo)
## camadas.definir_pe(ancora, pe_interpolado)
## camadas.atualizar_ordem()
## camadas.aplicar_parallax(camera_final, jogavel.get_center())
## [/codeblock]

## As 11 camadas canônicas (R4), na ordem de desenho.
enum Camada {
	FUNDO,
	NEVOA_DISTANTE,
	PAREDE,
	CHAO,
	SOMBRAS,
	TELEGRAFO_PREENCHIMENTO,
	OBJETOS_E_PERSONAGENS,
	TELEGRAFO_CONTORNO,
	PRIMEIRO_PLANO,
	POS,
	UI,
}

## Nomes dos nós de camada (mesma ordem do enum).
const NOMES: PackedStringArray = [
	"Fundo", "NevoaDistante", "Parede", "Chao", "Sombras",
	"TelegrafoPreenchimento", "ObjetosEPersonagens", "TelegrafoContorno",
	"PrimeiroPlano", "Pos", "UI",
]

## z absoluto das nove camadas de mundo e `CanvasLayer.layer` de Pós e UI (R4).
## Estrutura de render, não valor de gameplay.
const Z_DA_CAMADA: PackedInt32Array = [-30, -25, -20, -10, -6, -5, 0, 5, 10, 50, 100]

## Quantidade de camadas de mundo (as demais são canvases presos à tela).
const CAMADAS_DE_MUNDO: int = 9

## Nome do item de cor de fundo da região (primeiro filho do Fundo).
const NOME_COR_DE_FUNDO: StringName = &"CorDeFundoDaRegiao"

## Margem do retângulo de cor de fundo além do jogável (cobre sangria, deriva e
## a faixa útil de qualquer proporção). Estrutural, não gameplay.
const MARGEM_COR_DE_FUNDO: float = 4096.0

var _raizes: Array[CanvasItem] = []
var _canvases: Array[CanvasLayer] = []
var _parallax: PackedFloat32Array = []
var _posicao_original: Array[Vector2] = []
var _registro: RegistroDeCriacaoVisual
var _ordenacao: OrdenacaoPorPe = OrdenacaoPorPe.new()
var _ancoras: Array[Node2D] = []
var _identidades: Array = []
var _pes: Array[Vector2] = []
var _cor_de_fundo: Polygon2D


## `registro` é o registro central de criação injetado; sem ele, um registro
## próprio é criado (útil em ensaios).
func _init(registro: RegistroDeCriacaoVisual = null) -> void:
	name = &"Mundo"
	_registro = registro if registro != null else RegistroDeCriacaoVisual.new()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_parallax.resize(Camada.size())
	_parallax.fill(1.0)
	for i in CAMADAS_DE_MUNDO:
		var raiz := Node2D.new()
		raiz.name = NOMES[i]
		raiz.z_index = Z_DA_CAMADA[i]
		raiz.z_as_relative = false
		raiz.y_sort_enabled = false
		raiz.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(raiz)
		_raizes.append(raiz)
		_posicao_original.append(Vector2.ZERO)
	for i in range(CAMADAS_DE_MUNDO, Camada.size()):
		var canvas := CanvasLayer.new()
		canvas.name = NOMES[i]
		canvas.layer = Z_DA_CAMADA[i]
		canvas.follow_viewport_enabled = false
		add_child(canvas)
		_canvases.append(canvas)
	_cor_de_fundo = Polygon2D.new()
	_cor_de_fundo.name = NOME_COR_DE_FUNDO
	_cor_de_fundo.visible = false
	_raizes[Camada.FUNDO].add_child(_cor_de_fundo)


## Nó raiz da camada: `Node2D` para as nove de mundo, `CanvasLayer` para Pós e UI.
func raiz(camada: Camada) -> Node:
	if camada < CAMADAS_DE_MUNDO:
		return _raizes[camada]
	return _canvases[camada - CAMADAS_DE_MUNDO]


## Parallax p da camada (1,0 em todas, exceto o que o tuning definir).
func parallax_de(camada: Camada) -> float:
	return _parallax[camada]


## Define o parallax de uma camada de mundo (valor do `CameraTuning`). Pós e UI
## são presas à tela e recusam (devolve false).
func definir_parallax(camada: Camada, p: float) -> bool:
	if camada >= CAMADAS_DE_MUNDO or not is_finite(p) or p <= 0.0:
		return false
	_parallax[camada] = p
	_aplicar_offset(camada, Vector2.ZERO)
	return true


## Registra `item` em exatamente uma camada. Recusa (false) um item que já tem
## pai: mudar de camada é [method trocar_camada].
func registrar(item: CanvasItem, camada: Camada) -> bool:
	if item == null or item.get_parent() != null:
		return false
	raiz(camada).add_child(item)
	return true


## Move um item já registrado para outra camada (uma só, sempre).
func trocar_camada(item: CanvasItem, camada: Camada) -> bool:
	if camada_de(item) < 0:
		return false
	item.reparent(raiz(camada), false)
	return true


## Camada do item (pelo ancestral raiz), ou −1 se ele não está registrado.
func camada_de(item: Node) -> int:
	var n: Node = item
	while n != null and n != self:
		var p := n.get_parent()
		if p == self:
			var i := _raizes.find(n)
			if i >= 0:
				return i
			var c := _canvases.find(n)
			return CAMADAS_DE_MUNDO + c if c >= 0 else -1
		n = p
	return -1


## Cria a âncora de pé de `identidade` em Objetos e personagens. O ordinal vem do
## registro central (já atribuído na criação lógica); se ainda não houver, a
## criação é registrada agora como último recurso.
func registrar_ancora(identidade: Variant) -> Node2D:
	if _registro.ordinal_de(identidade) == RegistroDeCriacaoVisual.SEM_ORDINAL:
		_registro.registrar_criacao(identidade)
	var ancora := Node2D.new()
	ancora.name = "Ancora_%s" % str(identidade)
	ancora.y_sort_enabled = false
	_raizes[Camada.OBJETOS_E_PERSONAGENS].add_child(ancora)
	_ancoras.append(ancora)
	_identidades.append(identidade)
	_pes.append(Vector2.ZERO)
	return ancora


## Remove a âncora (despawn). O registro central decide quando liberar o ordinal.
func remover_ancora(ancora: Node2D) -> void:
	var i := _ancoras.find(ancora)
	if i < 0:
		return
	_ancoras.remove_at(i)
	_identidades.remove_at(i)
	_pes.remove_at(i)
	ancora.queue_free()


## Pé interpolado da âncora para a próxima ordenação (mesma interpolação do sprite).
func definir_pe(ancora: Node2D, pe: Vector2) -> void:
	var i := _ancoras.find(ancora)
	if i >= 0:
		_pes[i] = pe


## Reordena as âncoras por `(pé.y, ordinal)`; só move irmãos se a ordem mudou.
## Devolve true quando houve reordenação.
func atualizar_ordem() -> bool:
	var n := _ancoras.size()
	for i in n:
		_ordenacao.definir(i, _pes[i], _registro.ordinal_de(_identidades[i]))
	if not _ordenacao.ordenar(n):
		return false
	var raiz_obj := _raizes[Camada.OBJETOS_E_PERSONAGENS]
	for pos in n:
		raiz_obj.move_child(_ancoras[_ordenacao.indice_na_posicao(pos)], pos)
	return true


## Âncoras na ordem de irmãos atual (de trás para a frente).
func ancoras_em_ordem() -> Array[Node2D]:
	var r: Array[Node2D] = []
	for c in _raizes[Camada.OBJETOS_E_PERSONAGENS].get_children():
		if c is Node2D and _ancoras.has(c):
			r.append(c)
	return r


## F7: atribui (sem somar) o deslocamento de cada camada com p ≠ 1.
func aplicar_parallax(camera_final: Vector2, centro_camara: Vector2) -> void:
	for i in CAMADAS_DE_MUNDO:
		_aplicar_offset(i, ParallaxManual.deslocamento(_parallax[i], camera_final, centro_camara))


## Deslocamento atual da camada em relação ao mundo.
func deslocamento_de(camada: Camada) -> Vector2:
	if camada >= CAMADAS_DE_MUNDO:
		return Vector2.ZERO
	return (_raizes[camada] as Node2D).position - _posicao_original[camada]


## Cor de fundo da região abaixo de toda arte, cobrindo o jogável e muito além
## (AC-18): a falta de sangria mostra esta cor, nunca o vazio.
func definir_cor_de_fundo(cor: Color, jogavel: Rect2) -> void:
	var r := jogavel.grow(MARGEM_COR_DE_FUNDO)
	_cor_de_fundo.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	_cor_de_fundo.color = cor
	_cor_de_fundo.visible = true


func _aplicar_offset(camada: int, d: Vector2) -> void:
	(_raizes[camada] as Node2D).position = _posicao_original[camada] + d
