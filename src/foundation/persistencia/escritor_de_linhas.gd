## Escritor sequencial de linhas, mantido aberto durante a sessão (ADR-0013 §5).
##
## Criado só por [method ArmazemDeArquivos.criar_escritor_de_linhas]. Não é
## thread-safe: use só na thread principal. Toda falha volta como [code]false[/code];
## quem chama decide o estado (ex.: Telemetria vai a "Parada por falha").
##
## Exemplo:
## [codeblock]
## var w := armazem.criar_escritor_de_linhas("user://telemetria/sessao-20261116-120000.jsonl")
## if w != null and w.escrever_linha("{}") and w.descarregar():
##     pass
## w.fechar()
## [/codeblock]
@abstract
class_name EscritorDeLinhas
extends RefCounted


## Escreve [param texto] seguido de quebra de linha. [code]false[/code] em falha
## (no real: o [code]bool[/code] de [code]FileAccess.store_line[/code], 4.4+).
@abstract func escrever_linha(texto: String) -> bool


## Descarrega o buffer. [code]false[/code] em falha (semântica real: E-P1, NOT SOURCEABLE).
@abstract func descarregar() -> bool


## Fecha o escritor. Chamadas posteriores de escrita devolvem [code]false[/code].
@abstract func fechar() -> void
