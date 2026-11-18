class_name PortaDoVinculoNaRun
extends RefCounted
## Fachada de escopo de run do Vínculo e pactos (ADR-0015 §5).
## A Run e as Portas só conhecem esta interface; [VinculoNulo] implementa o comportamento "sem Pactos".


## Pede a dupla para a Doutrina [param doutrina]. Responde com [code]dupla_confirmada(campo, reserva)[/code]
## na hora (0 ou 1 pactuada) ou abre a tela de Escolha do Pacto (≥ 2 pactuadas).
func pedir_dupla(_doutrina: StringName) -> bool:
	return false


## Planeja o encontro de pacto da run no fluxo [param fluxo_pactos] (sempre 4 reais em Pactos; nada fora).
func planejar_encontro(_doutrina: StringName, _fluxo_pactos: FluxoRng) -> void:
	pass


## Consulta se há encontro planejado na câmara [param indice] (devolve o id da espécie ou [code]&""[/code]).
func encontro_na_camara(_indice: int) -> StringName:
	return &""


## Chamado pelas Câmaras ao montar a câmara [param indice] com as [param pedras] já postas.
func ao_montar_camara(_indice: int, _pedras: Array[ObstaculoCircular] = []) -> Vector2:
	return Vector2.ZERO


## Verdadeiro se a acuada está em [code]Aguardando[/code] esperando a escolha na tela de consentimento (Portas R2-P 2b).
func encontro_aguardando() -> bool:
	return false


## Consolida os pontos da run no perfil ao encerrar a run ou ao sair do jogo (V20, V20b).
func consolidar_run(_motivo: StringName, _venceu: bool) -> void:
	pass
