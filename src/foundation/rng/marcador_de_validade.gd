## Marcador compartilhado de validade dos fluxos de uma run (ADR-0005, "Ciclo de
## vida e referências retidas").
##
## Guarda só o estado ativo e a identidade da sessão da run. Não referencia a
## fonte nem os fluxos (fonte → fluxos → marcador, numa direção só). Uma vez
## invalidado, nunca volta a valer: a run seguinte recebe um marcador novo.
class_name MarcadorDeValidade
extends RefCounted

var _ativo: bool = true
var _sessao: int = 0


## Cria um marcador ativo para a sessão de run `sessao`.
func _init(sessao: int) -> void:
	_sessao = sessao


## Verdadeiro enquanto a run dona deste marcador estiver ativa.
func esta_valido() -> bool:
	return _ativo


## Identidade da sessão de run.
func sessao() -> int:
	return _sessao


## Invalida o marcador de vez (encerrar a run).
func invalidar() -> void:
	_ativo = false
