class_name RelatorPadrao
extends RelatorDeErros
## Relator do jogo (GDD de Conteúdo R10, AC-43): escreve uma linha no log injetado,
## chama [code]push_error[/code] e, se [code]parar_em_debug[/code] for verdadeiro,
## para com [code]assert[/code] (que só existe em build de debug).
##
## Exemplo:
## [codeblock]
## var linhas: PackedStringArray = []
## var relator := RelatorPadrao.new(func(l: String) -> void: linhas.append(l), false)
## [/codeblock]

var _destino_log: Callable
var _parar_em_debug: bool


## [param destino_log] recebe cada linha ([code]func(linha: String) -> void[/code]);
## vazio = [code]print[/code]. [param parar_em_debug] é [code]true[/code] no jogo.
func _init(destino_log: Callable = Callable(), parar_em_debug: bool = true) -> void:
	_destino_log = destino_log
	_parar_em_debug = parar_em_debug


func relatar(entrada: RelatorDeErros.Entrada) -> void:
	var linha := entrada.texto()
	if _destino_log.is_valid():
		_destino_log.call(linha)
	else:
		print(linha)
	push_error(linha)
	if _parar_em_debug:
		assert(false, linha)
