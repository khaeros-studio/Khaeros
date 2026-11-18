class_name RegistrosDeChaves
extends RefCounted
## Registros de chaves fechadas entregues pelos sistemas donos (GDD de Conteúdo R8,
## R8-P): tipos de efeito, comportamentos, formas de ataque e de telégrafo, status,
## tipos de sala e de recompensa, raridades de espécie, atributos do portador da
## Maldição. Uma chave pode ser ativa ou reservada; a V4 aceita as duas. O
## validador nunca tem lista própria: registro não entregue é erro V4.
##
## Exemplo:
## [codeblock]
## var r := RegistrosDeChaves.new()
## r.registrar(&"comportamentos", [&"corpo_a_corpo"], [&"chefe"])
## assert(r.resolve(&"comportamentos", &"chefe") and r.eh_reservada(&"comportamentos", &"chefe"))
## [/codeblock]

var _ativas: Dictionary[StringName, Array] = {}
var _reservadas: Dictionary[StringName, Array] = {}


## Registra (ou substitui) o registro [param nome].
func registrar(nome: StringName, ativas: Array[StringName], reservadas: Array[StringName] = []) -> void:
	_ativas[nome] = ativas.duplicate()
	_reservadas[nome] = reservadas.duplicate()


## [code]true[/code] se o dono entregou o registro.
func tem_registro(nome: StringName) -> bool:
	return _ativas.has(nome)


## Chave ativa ou reservada no registro.
func resolve(nome: StringName, chave: StringName) -> bool:
	return eh_ativa(nome, chave) or eh_reservada(nome, chave)


## Chave ativa (com código).
func eh_ativa(nome: StringName, chave: StringName) -> bool:
	return _ativas.has(nome) and _ativas[nome].has(chave)


## Chave reservada (registrada antes do código; pedir em jogo é erro do dono).
func eh_reservada(nome: StringName, chave: StringName) -> bool:
	return _reservadas.has(nome) and _reservadas[nome].has(chave)
