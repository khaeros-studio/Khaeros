## Interface só de leitura da conta de Fragmentos (ADR-0015 §6; GDD economia R8; AC-EF-26).
##
## É o tipo que HUD, Telemetria e tela final recebem: expõe só consultas puras,
## nunca [code]creditar[/code] nem [code]gastar[/code]. As mudanças chegam a eles
## pelo evento [EvSaldoMudou] no canal do passo.
##
## Exemplo:
## [codeblock]
## func ligar(conta: LeituraDaConta) -> void:
##     _rotulo_saldo = conta.saldo()
## [/codeblock]
class_name LeituraDaConta
extends RefCounted


## Saldo atual de Fragmentos (≥ 0). Consulta pura.
func saldo() -> int:
	return 0


## O que a run atual creditou (vitória incluída); zera em [code]nova_run()[/code]. Consulta pura.
func coletados_run() -> int:
	return 0
