class_name RegistroDeCriacaoVisual
extends RefCounted
## Registro central de criação visual (ADR-0007 §5): atribui o ordinal monotônico
## que desempata a ordenação por pé `(pé.y, ordinal)`.
##
## O ordinal é atribuído **sincronamente na criação lógica** (objeto estático na
## montagem da câmara, entidade, projétil), nunca na hora do `add_child` do nó.
## Reassociar a mesma identidade preserva o ordinal; um novo spawn recebe ordinal
## novo, mesmo que reutilize um nó ou um slot. Injetado na composição: não é
## Autoload. Não é thread-safe (usado só na thread principal).
##
## Exemplo:
## [codeblock]
## var registro := RegistroDeCriacaoVisual.new()
## var ord := registro.registrar_criacao(id_entidade)   # no spawn lógico
## var mesmo := registro.ordinal_de(id_entidade)        # ao reassociar o nó
## registro.liberar(id_entidade)                        # no despawn
## [/codeblock]

## Ordinal devolvido para identidade desconhecida.
const SEM_ORDINAL: int = -1

var _proximo: int = 0
var _por_identidade: Dictionary = {}


## Registra a criação lógica de `identidade` e devolve um ordinal novo, maior que
## todos os anteriores. Chamar de novo para a mesma identidade é um novo spawn.
func registrar_criacao(identidade: Variant) -> int:
	var ordinal := _proximo
	_proximo += 1
	_por_identidade[identidade] = ordinal
	return ordinal


## Ordinal vigente de `identidade` (o mesmo a cada reassociação), ou
## [constant SEM_ORDINAL] se ela não está registrada.
func ordinal_de(identidade: Variant) -> int:
	return int(_por_identidade.get(identidade, SEM_ORDINAL))


## Esquece `identidade` (despawn). O contador não volta: ordinais nunca se repetem.
func liberar(identidade: Variant) -> void:
	_por_identidade.erase(identidade)


## Quantidade de identidades vivas no registro.
func quantidade() -> int:
	return _por_identidade.size()
