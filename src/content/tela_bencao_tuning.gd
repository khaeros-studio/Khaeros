class_name TelaBencaoTuning
extends DefinicaoBase
## Constantes da Tela de bênção.
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Tela de bênção e carta (TB1–TB10). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var trava_confirmar_ms: int = 500
@export var trava_troca_ms: int = 300
@export var entrada_s: float = 0.45
@export var anim_troca_s: float = 0.30
@export var anim_confirmar_s: float = 0.60
@export var foco_escala: float = 1.06
@export var foco_sobe_px: int = 12
@export var valor_nao_focada: float = 0.70
@export var intervalo_cartas_px: int = 48
@export var tremor_botao_ms: int = 80

# Aliases e propriedades usadas pelas Telas de Bênção, Carta e Consentimento (sem @export para não alterar o esquema serializado)
var foco_subida_px: float:
	get:
		return float(foco_sobe_px)
	set(valor):
		foco_sobe_px = int(round(valor))

var trava_abertura_s: float:
	get:
		return float(trava_confirmar_ms) / 1000.0
	set(valor):
		trava_confirmar_ms = int(round(valor * 1000.0))

var trava_troca_s: float:
	get:
		return float(trava_troca_ms) / 1000.0
	set(valor):
		trava_troca_ms = int(round(valor * 1000.0))

var entrada_duracao_s: float:
	get:
		return entrada_s
	set(valor):
		entrada_s = valor

var entrada_atraso_carta_s: float = 0.06
var troca_saida_s: float = 0.15
var troca_entrada_s: float = 0.15
var confirmacao_duracao_s: float = 0.10
var saida_duracao_s: float = 0.10


func tipo_do_catalogo() -> StringName:
	return &"tuning"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super._declarar_regras(e)
	for nome: StringName in [
		&"foco_subida_px",
		&"trava_abertura_s",
		&"trava_troca_s",
		&"entrada_duracao_s",
		&"entrada_atraso_carta_s",
		&"troca_saida_s",
		&"troca_entrada_s",
		&"confirmacao_duracao_s",
		&"saida_duracao_s",
	]:
		var r: EsquemaDeDefinicao.RegraDeCampo = e.regra(nome)
		if r != null:
			r.opcional()
