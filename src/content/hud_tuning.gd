class_name HudTuning
extends DefinicaoBase
## Constantes do HUD (17 campos, emenda Pactos).
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: HUD (17 campos; HU1–HU17). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var vida_por_segmento: int = 10
@export var segmento_px: int = 32
@export var barra_max_frac: float = 0.25
@export var vida_baixa_pct: float = 0.25
@export var vida_baixa_histerese: float = 0.05
@export var vinheta_max_borda: float = 0.08
@export var vinheta_opacidade_max: float = 0.40
@export var janela_ganho_s: float = 1.50
@export var fio_visivel_s: float = 2.00
@export var largura_fio: int = 48
@export var fio_elite_escala: float = 1.50
@export var esquiva_tremor_ms: int = 80
@export var fade_estado_s: float = 0.25
@export var margem_segura_px: int = 48
@export var pacto_tremor_px: int = 4
@export var pacto_tremor_s: float = 0.15
@export var pacto_intervalo_px: int = 12

# Aliases e propriedades usadas pelo sistema de HUD (sem @export para não alterar o esquema serializado)
var racha_atraso_s: float = 0.10
var racha_duracao_s: float = 0.40

var opacidade_vida_baixa: float:
	get:
		return vinheta_opacidade_max
	set(valor):
		vinheta_opacidade_max = valor

var limiar_vida_baixa_entrar: float:
	get:
		return vida_baixa_pct
	set(valor):
		vida_baixa_pct = valor

var limiar_vida_baixa_sair: float:
	get:
		return vida_baixa_pct + vida_baixa_histerese
	set(valor):
		vida_baixa_histerese = maxf(0.0, valor - vida_baixa_pct)

var janela_agregacao_fragmentos_s: float:
	get:
		return janela_ganho_s
	set(valor):
		janela_ganho_s = valor


func tipo_do_catalogo() -> StringName:
	return &"tuning"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super._declarar_regras(e)
	for nome: StringName in [
		&"racha_atraso_s",
		&"racha_duracao_s",
		&"opacidade_vida_baixa",
		&"limiar_vida_baixa_entrar",
		&"limiar_vida_baixa_sair",
		&"janela_agregacao_fragmentos_s",
	]:
		var r: EsquemaDeDefinicao.RegraDeCampo = e.regra(nome)
		if r != null:
			r.opcional()
