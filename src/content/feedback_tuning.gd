class_name FeedbackTuning
extends DefinicaoBase
## Constantes do Feedback de combate.
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Feedback de combate (FB1–FB3). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var janela_soma_s: float = 0.30
@export var teto_numeros: int = 6
@export var limiar_degradacao: float = 0.90
@export var limiar_retorno: float = 0.75
@export var limiar_nivel2: float = 0.95
@export var retorno_nivel2: float = 0.85
@export var vozes_max_gancho: int = 4
@export var vozes_max_total: int = 16
@export var assenta_camara_s: float = 1.00

# Aliases e propriedades usadas pelo sistema de Feedback de Combate (sem @export para não alterar o esquema serializado)
var teto_numeros_simultaneos: int:
	get:
		return teto_numeros
	set(valor):
		teto_numeros = valor

var entrar_nivel_1: float:
	get:
		return limiar_degradacao
	set(valor):
		limiar_degradacao = valor

var sair_nivel_1: float:
	get:
		return limiar_retorno
	set(valor):
		limiar_retorno = valor

var entrar_nivel_2: float:
	get:
		return limiar_nivel2
	set(valor):
		limiar_nivel2 = valor

var sair_nivel_2: float:
	get:
		return retorno_nivel2
	set(valor):
		retorno_nivel2 = valor

var teto_estrelas_passo: int = 6
var flash_jogador_passos: int = 5
var flash_inimigo_passos: int = 4
var impact_recusa_passos: int = 2
var impact_chefe_passos: int = 3


func tipo_do_catalogo() -> StringName:
	return &"tuning"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super._declarar_regras(e)
	for nome: StringName in [
		&"teto_numeros_simultaneos",
		&"entrar_nivel_1",
		&"sair_nivel_1",
		&"entrar_nivel_2",
		&"sair_nivel_2",
		&"teto_estrelas_passo",
		&"flash_jogador_passos",
		&"flash_inimigo_passos",
		&"impact_recusa_passos",
		&"impact_chefe_passos",
	]:
		var r: EsquemaDeDefinicao.RegraDeCampo = e.regra(nome)
		if r != null:
			r.opcional()
