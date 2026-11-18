class_name AtaqueConvertido
extends RefCounted
## [AttackDef] convertido para passos e px por passo na carga (GDD combate-nucleo R15,
## AC-01; ADR-0010 §1, §9: [code]cos_meio[/code] calculado aqui, nunca a cada passo).
##
## Exemplo:
## [codeblock]
## var a := AtaqueConvertido.de(corte)   # a.recarga == 16; a.cos_meio ≈ 0,350044
## [/codeblock]

const FORMA_ARCO := &"arco"
const FORMA_CIRCULO := &"circulo"
const FORMA_PROJETIL := &"projetil"
const FORMA_AVANCO := &"avanco"
const FORMA_CHAMADO := &"chamado"

## Definição de origem (cópia profunda, só leitura).
var def: AttackDef
var forma: StringName
var dano: float
var empurrao: float
## R: recarga em passos.
var recarga: int
## Guarda em passos (0 = sem guarda).
var guarda: int
## Multiplicadores do combo (vazio = sem combo).
var combo: PackedFloat64Array
## Arco: cosseno do meio-ângulo.
var cos_meio: float = 1.0
## Avanço: N (passos do deslocamento).
var passos_avanco: int
## Projétil: L (vida em passos).
var vida_projetil: int
## Projétil: s (px por passo).
var passo_projetil_px: float


## Converte [param a].
static func de(a: AttackDef) -> AtaqueConvertido:
	var c := AtaqueConvertido.new()
	c.def = a
	c.forma = a.forma
	c.dano = a.dano
	c.empurrao = a.empurrao
	c.recarga = Unidades.duracao_para_passos(a.recarga_s)
	c.guarda = Unidades.duracao_para_passos(a.guarda_s)
	c.combo = a.multiplicadores_combo.duplicate()
	if a.params.has(&"meio_angulo_graus"):
		c.cos_meio = Unidades.cosseno_do_meio_angulo(a.params[&"meio_angulo_graus"])
	c.passos_avanco = Unidades.duracao_para_passos(a.params.get(&"duracao_s", 0.0))
	c.vida_projetil = Unidades.duracao_para_passos(a.params.get(&"vida_s", 0.0))
	c.passo_projetil_px = a.params.get(&"velocidade_pxs", 0.0) / float(Unidades.TICK_RATE)
	return c


## Param de geometria (0 se ausente).
func param(nome: StringName) -> float:
	return def.params.get(nome, 0.0)
