@abstract
class_name TabelaDeTextos
extends RefCounted
## Fonte dos textos PT-BR para V6 e V10 (GDD de Conteúdo R7, Provisório). No jogo, a
## implementação consulta a tradução importada (funciona no release); nos testes,
## uma tabela em memória.
##
## Exemplo:
## [codeblock]
## if not textos.tem(&"WEAPON_LAMINA_NAME"): ...
## [/codeblock]


## A chave existe na tabela.
@abstract func tem(chave: String) -> bool


## Texto da chave (vazio se não existe).
@abstract func texto(chave: String) -> String


## Alias de [method texto] usado por consumidores como [TextoDaCarta].
func obter(chave: String) -> String:
	return texto(chave)
