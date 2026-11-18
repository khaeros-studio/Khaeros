# PROTOTYPE - NOT FOR PRODUCTION (engine-verificacao)
extends Resource
## Definição de teste do EX-0004-NV (pai com filho externo).
@export var id: String = ""
@export var valor: int = 0
@export var pesos: PackedFloat64Array = PackedFloat64Array()
@export var filho: Resource = null
