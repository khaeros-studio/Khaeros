class_name GatilhoAtivo
extends RefCounted
## Gatilho registrado por uma fonte (GDD modificadores-e-atributos R5/R11; ADR-0009 §5).
##
## Modificadores só registra: o executor dono (Combate, Status, Selo) lê pelo
## [method Portador.gatilhos]. Imutável depois de criado; [member params] nunca escala (R8).
##
## Exemplo:
## [codeblock]
## var g := GatilhoAtivo.new(&"recusas_morte", 1.0, {&"vida_ao_voltar": 0.4})
## [/codeblock]

## Tipo de efeito de gatilho (R5).
var tipo: StringName
## Valor já escalado (F5).
var valor: float
## Params do [EffectDef] (cópia; não escrever).
var params: Dictionary[StringName, float]


func _init(p_tipo: StringName, p_valor: float, p_params: Dictionary[StringName, float] = {}) -> void:
	tipo = p_tipo
	valor = p_valor
	params = p_params.duplicate()
	params.make_read_only()
