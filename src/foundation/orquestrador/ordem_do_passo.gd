## Ordem fixa do passo vivo (ADR-0001 e emenda Pactos 2026-11-16; Combate R1).
##
## É a **lista única** que o orquestrador executa: 1 Input · (2 hitstop?) · 3 Combate-início
## · 4 Movimento · 5 Combate-golpe · 6 Selo · 6.1 Maldições · 7 Inimigos · 8 Projéteis
## · 9 varredura de mortes · 10 Câmaras. O item 2 é uma bifurcação, não um módulo.
## A ordem dos itens 3, 5, 7, 8 e 9 é do Combate; a ordem interna de cada item é do dono.
##
## Exemplo (composição no [code]Main[/code]):
## [codeblock]
## var modulos: Dictionary[StringName, Passo] = {}
## for chave: StringName in OrdemDoPasso.modulos():
##     modulos[chave] = construir_passo(chave)
## orquestrador.configurar_passo(fonte_de_amostra, controle_de_hitstop, modulos)
## [/codeblock]
class_name OrdemDoPasso
extends RefCounted

## Item 1: amostra do Input (não é [Passo]; vem de [FonteDeAmostra]).
const INPUT: StringName = &"input"
## Item 3: início do passo do Combate.
const COMBATE_INICIO: StringName = &"combate_inicio"
## Item 4: Movimento (único escritor de posição; também recebe [code]passo_congelado()[/code]).
const MOVIMENTO: StringName = &"movimento"
## Item 5: golpe do jogador (Combate).
const COMBATE_GOLPE: StringName = &"combate_golpe"
## Item 6: Selo.
const SELO: StringName = &"selo"
## Item 6.1: Maldições (ADR-0017). Existe e não faz nada em runs sem Pactos.
const MALDICOES: StringName = &"maldicoes"
## Item 7: Inimigos (Telégrafos, IA, Status e impacto; ADR-0010 §2, ADR-0018).
const INIMIGOS: StringName = &"inimigos"
## Item 8: Projéteis (Combate).
const PROJETEIS: StringName = &"projeteis"
## Item 9: varredura de mortes (Combate).
const MORTES: StringName = &"mortes"
## Item 10: Câmaras ("câmara limpa" só em passo vivo, logo com hitstop inativo).
const CAMARAS: StringName = &"camaras"


## Ordem completa do passo vivo, item 1 incluído. Array novo a cada chamada.
static func itens() -> Array[StringName]:
	var r: Array[StringName] = [INPUT]
	r.append_array(modulos())
	return r


## Chaves dos módulos [Passo] do passo vivo (itens 3 a 10, com 6.1), na ordem de execução.
static func modulos() -> Array[StringName]:
	var r: Array[StringName] = [
		COMBATE_INICIO, MOVIMENTO, COMBATE_GOLPE, SELO, MALDICOES,
		INIMIGOS, PROJETEIS, MORTES, CAMARAS,
	]
	return r
