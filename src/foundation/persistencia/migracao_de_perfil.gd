## Cadeia pura de migração do formato de [code]perfil.cfg[/code] (save-e-perfil R6).
##
## Cada passo é um [Callable] [code](documento: Dictionary) -> Dictionary[/code] que leva
## da versão [code]v[/code] para [code]v + 1[/code]. O documento é
## [code]{ "<secao>": { "<chave>": valor } }[/code] com todas as seções do arquivo.
## Os passos recebem cópia profunda. A versão suportada do MVP é 1 (sem passos).
##
## Exemplo:
## [codeblock]
## var m := MigracaoDePerfil.new(2)
## m.registrar(1, func(doc: Dictionary) -> Dictionary: doc["vinculo"]["novo"] = 0; return doc)
## var migrado := m.migrar(1, doc)
## [/codeblock]
class_name MigracaoDePerfil
extends RefCounted

## Versão de formato do MVP (save-e-perfil R2: [code]schema_version = 1[/code]).
const VERSAO_DO_MVP: int = 1

## Maior [code]schema_version[/code] que este build lê e a que ele grava.
var versao_suportada: int

# v_de (int) → Callable
var _passos: Dictionary = {}


## [param versao] é a versão que este build grava (padrão: [constant VERSAO_DO_MVP]).
func _init(versao: int = VERSAO_DO_MVP) -> void:
	versao_suportada = versao


## Registra o passo que migra de [param v_de] para [code]v_de + 1[/code].
func registrar(v_de: int, passo: Callable) -> void:
	_passos[v_de] = passo


## [code]true[/code] se existe passo para cada versão de [param v_de] até a suportada.
func pode_migrar(v_de: int) -> bool:
	for v in range(v_de, versao_suportada):
		if not _passos.has(v):
			return false
	return true


## Aplica a cadeia de [param v_de] até [member versao_suportada]. Chame só se
## [method pode_migrar]; uma versão sem passo é pulada.
func migrar(v_de: int, documento: Dictionary) -> Dictionary:
	var atual: Dictionary = documento.duplicate(true)
	for v in range(v_de, versao_suportada):
		if _passos.has(v):
			var passo: Callable = _passos[v]
			atual = passo.call(atual.duplicate(true))
	return atual
