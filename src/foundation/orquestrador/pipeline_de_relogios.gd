## O que o orquestrador precisa do Pipeline visual a cada [code]quadro()[/code] (ADR-0001;
## Pipeline R7, R8).
##
## Recebe os dois relógios ([code]t_vivo[/code], [code]t_apres[/code]) todo quadro e informa o
## progresso do wipe da Transição (0 a 1). A metade (≥ 0,5) dispara a troca de câmara;
## o fim (≥ 1) faz o orquestrador pedir [code]JOGO[/code].
##
## Exemplo:
## [codeblock]
## class_name PipelineReal extends PipelineDeRelogios
## func receber_relogios(t_vivo: float, t_apres: float) -> void:
##     RenderingServer.global_shader_parameter_set(&"t_vivo", t_vivo)
##     RenderingServer.global_shader_parameter_set(&"t_apres", t_apres)
## func progresso_wipe() -> float:
##     return _progresso
## [/codeblock]
## Não é seguro entre threads.
@abstract
class_name PipelineDeRelogios
extends RefCounted


## Entrega dos relógios do quadro (segundos).
@abstract func receber_relogios(t_vivo: float, t_apres: float) -> void


## Progresso do wipe da Transição corrente, 0..1 (0 fora da Transição).
@abstract func progresso_wipe() -> float
