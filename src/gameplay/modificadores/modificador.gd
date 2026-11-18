class_name Modificador
extends RefCounted
## Um modificador de atributo (GDD modificadores-e-atributos R3/R4; ADR-0009 §3).
##
## Imutável depois de criado (convenção: nenhum sistema escreve nos campos; reaplicar
## cria fonte nova). O [member valor] já chega escalado pela raridade (F5); o
## [member param] nunca escala. Condição só em [code]dano_todo[/code]:
## [method motivo_invalido] diz por que um modificador é recusado, e o [Portador]
## ignora o recusado e o relata (AC-28; a rejeição no catálogo é do validador, story 006).
##
## Exemplo:
## [codeblock]
## var fundo := Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.PERCENTUAL, 0.4,
##         Modificador.Condicao.VIDA_ABAIXO, 0.5)
## [/codeblock]

## Operação da F1/F2.
enum Operacao { PLANO, PERCENTUAL, MULTIPLICADOR }
## Condição avaliada no uso (R4).
enum Condicao { NENHUMA, VIDA_ABAIXO, ENESIMO_ACERTO, APOS_ESQUIVA }
## Slot do consumidor de dano (R12). NENHUM = inimigo/Maldição (sem grupo de slot).
enum Slot { NENHUM, ATAQUE, ESPECIAL, SELO }

## Bits da máscara [member slots] (vazia = todos os slots).
const MASCARA_ATAQUE: int = 1
const MASCARA_ESPECIAL: int = 2
const MASCARA_SELO: int = 4

## Atributo da lista R2.
var atributo: StringName
## Operação.
var operacao: Operacao
## Valor já escalado (F5).
var valor: float
## Condição (R4); só em [code]dano_todo[/code].
var condicao: Condicao
## Param da condição: [code]limiar_vida[/code], [code]a_cada[/code] ou [code]janela_s[/code].
var param: float
## Máscara de slots ([constant MASCARA_ATAQUE] | ...); 0 = todos.
var slots: int


func _init(p_atributo: StringName, p_operacao: Operacao, p_valor: float,
		p_condicao: Condicao = Condicao.NENHUMA, p_param: float = 0.0, p_slots: int = 0) -> void:
	atributo = p_atributo
	operacao = p_operacao
	valor = p_valor
	condicao = p_condicao
	param = p_param
	slots = p_slots


## Texto vazio se o modificador é aceito; senão, o motivo (atributo fora da R2,
## condição fora de [code]dano_todo[/code], operação sem sentido no acumulador, multiplicador negativo).
func motivo_invalido() -> String:
	if not Atributos.existe(atributo):
		return "atributo fora da R2: %s" % atributo
	if condicao != Condicao.NENHUMA and atributo != Atributos.DANO_TODO:
		return "condição só em dano_todo (R3): %s" % atributo
	if Atributos.eh_dano(atributo):
		var aceita_mult := atributo == Atributos.DANO_TODO
		if operacao == Operacao.PLANO or (operacao == Operacao.MULTIPLICADOR and not aceita_mult):
			return "operação inválida no acumulador de dano: %s" % atributo
	if operacao == Operacao.MULTIPLICADOR and valor < 0.0:
		return "multiplicador negativo (F1): %s" % atributo
	return ""


## Verdadeiro se o modificador vale para [param slot] (máscara vazia = todos).
func vale_no_slot(slot: Slot) -> bool:
	if slots == 0:
		return true
	if slot == Slot.NENHUM:
		return false
	return (slots & (1 << (slot - 1))) != 0
