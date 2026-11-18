## [PerfilDaSessao] que não lê nem grava nada (ADR-0013 §7; save-e-perfil R13, TR-save-016).
##
## Injetado pela composição em testes e em debug no lugar do [RepositorioDePerfil];
## o [Save] não tem [code]if[/code] para ele. Modo sempre [constant ModoDoPerfil.Valor.NORMAL]:
## os gatilhos "gravam" com sucesso sem tocar o disco. Se recebe a porta do dono, chama
## [code]ler({})[/code] na carga e no reset, como um perfil ausente. O build de playtest
## [b]não[/b] usa este dublê: lê e grava o perfil normalmente. Não é thread-safe.
##
## Exemplo:
## [codeblock]
## var save := Save.new()
## save.configurar(PerfilNulo.new(vinculo), avisos.receber)
## save.carregar(true)          # vinculo.ler({}), nenhum arquivo tocado
## [/codeblock]
class_name PerfilNulo
extends PerfilDaSessao

var _porta: PortaDeSecao


## [param porta]: dono da seção que recebe [code]ler({})[/code]; [code]null[/code] = nenhum.
func _init(porta: PortaDeSecao = null) -> void:
	_porta = porta


func carregar() -> ModoDoPerfil.Valor:
	if _porta != null:
		_porta.ler({})
	return ModoDoPerfil.Valor.NORMAL


func modo() -> ModoDoPerfil.Valor:
	return ModoDoPerfil.Valor.NORMAL


func salvar() -> Error:
	return OK


## Sempre vazio: não há perfil a exportar.
func exportar_texto() -> String:
	return ""


## Sempre [constant ERR_UNAVAILABLE]: o perfil nulo não aceita conteúdo.
func importar_texto(_texto: String) -> Error:
	return ERR_UNAVAILABLE


func resetar() -> Error:
	if _porta != null:
		_porta.ler({})
	return OK
