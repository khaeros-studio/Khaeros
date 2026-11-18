## Estado de jogo do orquestrador (ADR-0001, decisão 3). Arquivo próprio para os
## outros módulos não escreverem [code]OrquestradorDoPasso.EstadoDeJogo[/code].
##
## Não usa [code]SceneTree.paused[/code]: o orquestrador simplesmente não chama o
## passo vivo fora de [constant Valor.JOGO]. A tela de consentimento do pacto usa
## [constant Valor.BENCAO] (emenda Pactos), sem estado novo no enum.
##
## Exemplo:
## [codeblock]
## if orquestrador.estado() == EstadoDeJogo.Valor.JOGO:
##     print(EstadoDeJogo.nome(orquestrador.estado()))  # "JOGO"
## [/codeblock]
class_name EstadoDeJogo
extends RefCounted

## Estados de jogo. [constant INICIANDO] é o estado "Pronto" da inicialização.
enum Valor { INICIANDO, MENU, JOGO, PAUSA, BENCAO, TRANSICAO, MORTE }


## Nome legível do estado [param v] (diagnóstico e testes).
static func nome(v: Valor) -> String:
	return Valor.find_key(v) as String
