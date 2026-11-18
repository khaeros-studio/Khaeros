class_name OpcoesDeNascimento
extends RefCounted
## Opções passadas a `ModuloDeIA.criar_inimigo` pelas Câmaras ou pela invocação do chefe (ADR-0018 §9).

var ordem: int = -1
var profundidade: int = 0
var elite: bool = false
var invocado_pelo_chefe: bool = false
var subjugavel: bool = false
var armadura_hits: int = -1


static func comum(p_ordem: int = -1, p_profundidade: int = 0) -> OpcoesDeNascimento:
	var o := OpcoesDeNascimento.new()
	o.ordem = p_ordem
	o.profundidade = p_profundidade
	return o


static func de_elite(p_ordem: int = -1, p_profundidade: int = 3) -> OpcoesDeNascimento:
	var o := OpcoesDeNascimento.new()
	o.ordem = p_ordem
	o.profundidade = p_profundidade
	o.elite = true
	return o


static func lacaio_do_chefe() -> OpcoesDeNascimento:
	var o := OpcoesDeNascimento.new()
	o.ordem = -1
	o.profundidade = 0
	o.elite = false
	o.invocado_pelo_chefe = true
	return o


static func de_chefe(p_subjugavel: bool = false) -> OpcoesDeNascimento:
	var o := OpcoesDeNascimento.new()
	o.ordem = -1
	o.profundidade = 0
	o.elite = false
	o.subjugavel = p_subjugavel
	return o
