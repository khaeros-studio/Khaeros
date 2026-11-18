class_name EncontroDePacto
extends RefCounted
## Máquina de estados de um encontro de pacto na run
## (GDD vinculo-e-pactos.md §States and Transitions, V4–V15; ADR-0015 §5).
##
## Estados:
## [code]SEM_ENCONTRO -> PLANEJADO -> ACUADA -> AGUARDANDO / FUGIU -> RESOLVIDO / ABANDONADO / NAO_ALCANCADO[/code].

enum Estado {
	SEM_ENCONTRO,
	PLANEJADO,
	ACUADA,
	AGUARDANDO,
	FUGIU,
	RESOLVIDO,
	NAO_ALCANCADO,
	ABANDONADO,
}

var estado: Estado = Estado.SEM_ENCONTRO
var indice_camara: int = -1
var especie_id: StringName = &""
var acuada: MaldicaoAcuada = null
var resultado_final: StringName = &""


func _init() -> void:
	acuada = MaldicaoAcuada.new()


## Planeja o encontro para [param p_indice] com [param p_especie] (ou [code]SEM_ENCONTRO[/code] se não ocorre).
func planejar(ocorre: bool, p_indice: int, p_especie: StringName) -> void:
	if not ocorre or p_indice < 0 or p_especie == &"":
		estado = Estado.SEM_ENCONTRO
		indice_camara = -1
		especie_id = &""
		return
	estado = Estado.PLANEJADO
	indice_camara = p_indice
	especie_id = p_especie


## Verdadeiro se este encontro nasceu em campo nesta run (usado em V20 passo 2 para zerar `runs_pactos_sem_encontro`).
func nasceu_nesta_run() -> bool:
	return estado in [Estado.ACUADA, Estado.AGUARDANDO, Estado.FUGIU, Estado.RESOLVIDO, Estado.ABANDONADO]
