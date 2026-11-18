class_name RotulosDeAcao
extends RefCounted
## `rotulo_acao(acao, dispositivo)` (GDD input-e-controle, Interactions, decidido 2026-11-13; ADR-0006 §6).
##
## Devolve `{texto, glifo}` do bind primário atual. Teclado: `texto` é o rótulo da tecla lógica do layout
## ativo (função injetada `rotulo_da_tecla(codigo_fisico) -> String`), `glifo` = `tecla_<codigo>`.
## Gamepad: `glifo` = id do botão (`pad_a`, `pad_lt`…) e `texto` o nome curto. Ação ou dispositivo inválido:
## `{texto: "", glifo: ""}` e um aviso pelo Callable `avisar(mensagem)`, sem falha.

const _NOMES_PAD: Dictionary = {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_START: "Start",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_LEFT_STICK: "LS", JOY_BUTTON_RIGHT_STICK: "RS",
	JOY_BUTTON_DPAD_UP: "DUp", JOY_BUTTON_DPAD_DOWN: "DDown", JOY_BUTTON_DPAD_LEFT: "DLeft",
	JOY_BUTTON_DPAD_RIGHT: "DRight",
}
const _NOMES_GATILHO: Dictionary = {JOY_AXIS_TRIGGER_LEFT: "LT", JOY_AXIS_TRIGGER_RIGHT: "RT"}

var _rotulo_da_tecla: Callable
var _avisar: Callable


## `rotulo_da_tecla(codigo_fisico: int) -> String`: vazio usa o layout ativo do `DisplayServer`
## (API não coberta pela engine-reference: verificar AZERTY em hardware). `avisar(mensagem: String)`:
## vazio usa `push_warning`.
func _init(rotulo_da_tecla: Callable = Callable(), avisar: Callable = Callable()) -> void:
	_rotulo_da_tecla = rotulo_da_tecla
	_avisar = avisar


## Rótulo do bind primário de `acao` em `dispositivo` no `mapa`. Ações vetoriais usam a direção "cima".
func rotulo(mapa: MapaDeBinds, acao: StringName, dispositivo: StringName) -> Dictionary:
	var vazio := {"texto": "", "glifo": ""}
	if not Acoes.eh_acao(acao) or not (dispositivo == Acoes.DISPOSITIVO_TECLADO
			or dispositivo == Acoes.DISPOSITIVO_GAMEPAD):
		_aviso("rotulo_acao inválido: %s / %s" % [acao, dispositivo])
		return vazio
	var chave := acao
	if Acoes.DIRECIONAIS.has(acao):
		chave = Acoes.chave_direcional(acao, Acoes.DIRECAO_CIMA)
	var lista := mapa.de(dispositivo, chave)
	if lista.is_empty():
		_aviso("rotulo_acao sem bind: %s / %s" % [acao, dispositivo])
		return vazio
	return rotulo_do_bind(lista[0])


## `{texto, glifo}` de um bind simples `{tipo, codigo}`.
func rotulo_do_bind(bind: Dictionary) -> Dictionary:
	var tipo := StringName(bind.get("tipo", &""))
	var codigo := int(bind.get("codigo", 0))
	match tipo:
		DescritorDeEntrada.TECLA_FISICA:
			return {"texto": _texto_da_tecla(codigo), "glifo": "tecla_%d" % codigo}
		DescritorDeEntrada.MOUSE:
			return {"texto": "Mouse %d" % codigo, "glifo": "mouse_%d" % codigo}
		DescritorDeEntrada.BOTAO_GAMEPAD:
			var nome: String = _NOMES_PAD.get(codigo, "Pad %d" % codigo)
			return {"texto": nome, "glifo": "pad_%s" % nome.to_lower()}
		DescritorDeEntrada.GATILHO:
			var gatilho: String = _NOMES_GATILHO.get(codigo, "Eixo %d" % codigo)
			return {"texto": gatilho, "glifo": "pad_%s" % gatilho.to_lower()}
	return {"texto": "", "glifo": ""}


func _texto_da_tecla(codigo_fisico: int) -> String:
	if _rotulo_da_tecla.is_valid():
		return String(_rotulo_da_tecla.call(codigo_fisico))
	var logica := DisplayServer.keyboard_get_label_from_physical(codigo_fisico as Key)
	if logica == KEY_NONE:
		logica = codigo_fisico as Key
	return OS.get_keycode_string(logica)


func _aviso(mensagem: String) -> void:
	if _avisar.is_valid():
		_avisar.call(mensagem)
	else:
		push_warning(mensagem)
