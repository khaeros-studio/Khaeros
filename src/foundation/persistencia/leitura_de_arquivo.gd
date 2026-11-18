## Resultado de [method ArmazemDeArquivos.ler_texto] (ADR-0013 §1).
##
## Valor de dados: não toca disco. Ausência de arquivo não é erro:
## [code]existe == false[/code] e [code]ok == true[/code]. Arquivo existente que não
## pôde ser lido dá [code]existe == true[/code], [code]ok == false[/code] e [member erro].
##
## Exemplo:
## [codeblock]
## var l := armazem.ler_texto("user://perfil.cfg")
## if l.existe and l.ok:
##     print(l.texto)
## [/codeblock]
class_name LeituraDeArquivo
extends RefCounted

## [code]true[/code] se a leitura terminou sem erro (inclusive "arquivo ausente").
var ok: bool = true
## [code]true[/code] se o arquivo existia no momento da leitura.
var existe: bool = false
## Conteúdo interpretado como UTF-8 (vazio se ausente ou ilegível).
var texto: String = ""
## Conteúdo bruto, byte a byte.
var bytes: PackedByteArray = PackedByteArray()
## Código de erro quando [member ok] é [code]false[/code]; [constant OK] caso contrário.
var erro: Error = OK


## Leitura de arquivo ausente: [code]ok[/code], sem conteúdo.
static func ausente() -> LeituraDeArquivo:
	var l := LeituraDeArquivo.new()
	l.ok = true
	l.existe = false
	return l


## Leitura bem-sucedida de [param conteudo].
static func lida(conteudo: PackedByteArray) -> LeituraDeArquivo:
	var l := LeituraDeArquivo.new()
	l.ok = true
	l.existe = true
	l.bytes = conteudo
	l.texto = conteudo.get_string_from_utf8()
	return l


## Arquivo existente que não pôde ser lido.
static func falhou(codigo: Error) -> LeituraDeArquivo:
	var l := LeituraDeArquivo.new()
	l.ok = false
	l.existe = true
	l.erro = codigo
	return l
