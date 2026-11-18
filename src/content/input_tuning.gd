class_name InputTuning
extends DefinicaoBase
## Constantes do Input (GDD input-e-controle R12; Conteúdo R1). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code]. Criado pela story input-006 porque o
## épico conteudo ainda não tinha o tipo; o esquema e a validação (V2: zm + ze < 1) continuam do conteudo.
##
## Exemplo:
## [codeblock]
## var t := InputTuning.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

## Prazo do buffer em passos (F3; 1–30).
@export var buffer_passos: int = 0
## Zona morta interna zm (F2; 0–0,5).
@export var zona_morta_interna: float = 0.0
## Zona morta externa ze (F2; 0–0,2).
@export var zona_morta_externa: float = 0.0
## Raio da mira automática em px de mundo, inclusivo (F4).
@export var raio_mira_px: float = 0.0
## Limiar de movimento do mouse em px de tela por passo (F5; 1–20).
@export var limiar_mouse_px: float = 0.0
## Gatilho analógico aperta em >= este valor (R12).
@export var gatilho_aperta: float = 0.0
## Gatilho analógico solta abaixo deste valor (R12, histerese).
@export var gatilho_solta: float = 0.0


func tipo_do_catalogo() -> StringName:
	return &"tuning"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super._declarar_regras(e)
	e.regra(&"buffer_passos").faixa(1.0, 30.0)
	e.regra(&"zona_morta_interna").faixa(0.0, 0.5)
	e.regra(&"zona_morta_externa").faixa(0.0, 0.2)
	e.regra(&"raio_mira_px").min_incl(0.0)
	e.regra(&"limiar_mouse_px").faixa(1.0, 20.0)
	e.regra(&"gatilho_aperta").faixa(0.0, 1.0).min_excl(0.0)
	e.regra(&"gatilho_solta").faixa(0.0, 1.0).min_excl(0.0)
	e.entre(&"gatilho_solta", &"<", &"gatilho_aperta")
	e.soma_menor_que(&"zona_morta_interna", &"zona_morta_externa", 1.0)
