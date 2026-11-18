class_name MonitorDeDispositivos
extends RefCounted
## Conexão e desconexão de gamepads (GDD input-e-controle R10, Edge Cases; ADR-0006 §3). Lógica pura: o
## adaptador repassa `Input.joy_connection_changed` para `ao_mudar_conexao`; os testes chamam direto.
##
## - Gamepad ATIVO desconecta: aviso `INPUT_CONTROLE_DESCONECTADO`; em Jogo, também pede a Pausa.
## - Em Bênção ou Menu: só o aviso. Na Transição: só o aviso (caso pendente no ADR-0006, sem pausa inferida).
## - Teclado ativo, ou gamepad que não é o ativo: nada.
## - Reconectar não fecha a Pausa.
## O aviso passa pelo `avisar(chave)` injetado; a regra "uma vez por sessão" (R8) é aplicada aqui.

## Chave de tradução do aviso de desconexão (R8).
const AVISO_DESCONECTADO := &"INPUT_CONTROLE_DESCONECTADO"

var _roteador: RoteadorDeContexto
var _dispositivo_ativo: Callable
var _gamepad_ativo: Callable
var _avisar: Callable
var _avisado: bool = false


## `dispositivo_ativo() -> StringName` e `gamepad_ativo() -> int` (em produção, os do `ProvedorDeEntrada`);
## `avisar(chave: StringName) -> void` para a UI.
func _init(roteador: RoteadorDeContexto, dispositivo_ativo: Callable, gamepad_ativo: Callable,
		avisar: Callable = Callable()) -> void:
	_roteador = roteador
	_dispositivo_ativo = dispositivo_ativo
	_gamepad_ativo = gamepad_ativo
	_avisar = avisar


## Mudança de conexão de um gamepad. Devolve `true` se pediu (e conseguiu) a Pausa.
func ao_mudar_conexao(dispositivo: int, conectado: bool) -> bool:
	if conectado:
		return false
	if StringName(_dispositivo_ativo.call()) != Acoes.DISPOSITIVO_GAMEPAD:
		return false
	if int(_gamepad_ativo.call()) != dispositivo:
		return false
	_emitir_aviso()
	return _roteador.pausar_por_desconexao()


func _emitir_aviso() -> void:
	if _avisado:
		return
	_avisado = true
	if _avisar.is_valid():
		_avisar.call(AVISO_DESCONECTADO)
