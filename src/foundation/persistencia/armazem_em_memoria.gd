## Dublê de [ArmazemDeArquivos] sem I/O (ADR-0013 §1; TR-save-017).
##
## Guarda um mapa caminho → bytes, registra toda operação (inclusive
## [method existe]) e aceita falhas programadas por operação e por ordem de chamada.
## Uma falha programada devolve [code]Error[/code]/[code]false[/code]/[code]null[/code]
## e [b]não altera[/b] o mapa. Roda sem [code]SceneTree[/code]. Não é thread-safe.
##
## Operações registradas (nomes usados em [method programar_falha] e [method contar]):
## [code]&"ler_texto"[/code], [code]&"gravar_atomico"[/code], [code]&"copiar_bytes"[/code],
## [code]&"existe"[/code], [code]&"listar_arquivos"[/code], [code]&"apagar"[/code],
## [code]&"garantir_pasta"[/code], [code]&"criar_escritor_de_linhas"[/code],
## [code]&"escrever_linha"[/code], [code]&"descarregar"[/code].
##
## Exemplo:
## [codeblock]
## var a := ArmazemEmMemoria.new()
## a.colocar_texto("user://perfil.cfg", "%%lixo")
## a.programar_falha(&"copiar_bytes", 1)
## # ... repositório carrega; depois:
## assert(a.contar(&"gravar_atomico") == 0)
## [/codeblock]
class_name ArmazemEmMemoria
extends ArmazemDeArquivos

## Falha em toda chamada da operação (use como [param ordem] em [method programar_falha]).
const SEMPRE: int = 0

# caminho normalizado (String) → PackedByteArray
var _arquivos: Dictionary = {}
# pasta normalizada (String) → true
var _pastas: Dictionary = {}
# operação (StringName) → Array de ordens (int) que falham; SEMPRE = todas
var _falhas: Dictionary = {}
# operação (StringName) → nº de chamadas até agora
var _chamadas: Dictionary = {}
var _registro: PackedStringArray = PackedStringArray()


## Escritor em memória: anexa linhas ao arquivo no mapa do armazém.
class EscritorEmMemoria extends EscritorDeLinhas:
	var _armazem: ArmazemEmMemoria
	var _caminho: String
	var _aberto: bool = true

	func _init(armazem: ArmazemEmMemoria, caminho: String) -> void:
		_armazem = armazem
		_caminho = caminho

	func escrever_linha(texto: String) -> bool:
		if _armazem._falha_programada(&"escrever_linha", _caminho) or not _aberto:
			return false
		var atual: PackedByteArray = _armazem._arquivos.get(_caminho, PackedByteArray())
		atual.append_array((texto + "\n").to_utf8_buffer())
		_armazem._arquivos[_caminho] = atual
		return true

	func descarregar() -> bool:
		if _armazem._falha_programada(&"descarregar", _caminho):
			return false
		return _aberto

	func fechar() -> void:
		_aberto = false


## Programa a [param ordem]-ésima chamada (1 = a primeira) de [param operacao] para
## falhar. [constant SEMPRE] faz toda chamada falhar. Pode ser chamado várias vezes.
func programar_falha(operacao: StringName, ordem: int) -> void:
	var ordens: Array = _falhas.get(operacao, [])
	ordens.append(ordem)
	_falhas[operacao] = ordens


## Remove todas as falhas programadas (não zera contadores nem registro).
func limpar_falhas() -> void:
	_falhas.clear()


## Coloca um arquivo de texto (UTF-8) no mapa sem registrar operação (preparo de teste).
func colocar_texto(caminho: String, texto: String) -> void:
	_arquivos[_normalizar(caminho)] = texto.to_utf8_buffer()


## Coloca bytes brutos no mapa sem registrar operação (preparo de teste).
func colocar_bytes(caminho: String, conteudo: PackedByteArray) -> void:
	_arquivos[_normalizar(caminho)] = conteudo.duplicate()


## Bytes atuais de [param caminho] (vazio se ausente), sem registrar operação.
func bytes_de(caminho: String) -> PackedByteArray:
	var b: PackedByteArray = _arquivos.get(_normalizar(caminho), PackedByteArray())
	return b.duplicate()


## Texto atual de [param caminho] (vazio se ausente), sem registrar operação.
func texto_de(caminho: String) -> String:
	return bytes_de(caminho).get_string_from_utf8()


## [code]true[/code] se o mapa tem o arquivo, sem registrar operação.
func tem_arquivo(caminho: String) -> bool:
	return _arquivos.has(_normalizar(caminho))


## Quantas operações [param operacao] foram registradas; se [param caminho] não
## for vazio, só as feitas sobre ele (para cópia: origem ou destino).
func contar(operacao: StringName, caminho: String = "") -> int:
	var n: int = 0
	var alvo: String = _normalizar(caminho) if caminho != "" else ""
	for linha in _registro:
		var partes: PackedStringArray = linha.split(" ")
		if partes[0] != String(operacao):
			continue
		if alvo == "" or partes.slice(1).has(alvo):
			n += 1
	return n


## Quantas operações de qualquer tipo tocaram [param caminho].
func contar_tudo_sobre(caminho: String) -> int:
	var alvo: String = _normalizar(caminho)
	var n: int = 0
	for linha in _registro:
		if linha.split(" ").slice(1).has(alvo):
			n += 1
	return n


## Cópia do registro: uma linha [code]"<operacao> <caminho> [<destino>]"[/code] por chamada.
func registro() -> PackedStringArray:
	return _registro.duplicate()


func ler_texto(caminho: String) -> LeituraDeArquivo:
	var c: String = _normalizar(caminho)
	if _falha_programada(&"ler_texto", c):
		return LeituraDeArquivo.falhou(ERR_FILE_CANT_READ)
	if not _arquivos.has(c):
		return LeituraDeArquivo.ausente()
	var b: PackedByteArray = _arquivos[c]
	return LeituraDeArquivo.lida(b.duplicate())


func gravar_atomico(caminho: String, texto: String) -> Error:
	var c: String = _normalizar(caminho)
	if _falha_programada(&"gravar_atomico", c):
		return ERR_FILE_CANT_WRITE
	_arquivos[c] = texto.to_utf8_buffer()
	return OK


func copiar_bytes(origem: String, destino: String) -> Error:
	var o: String = _normalizar(origem)
	var d: String = _normalizar(destino)
	if _falha_programada(&"copiar_bytes", o + " " + d):
		return ERR_FILE_CANT_WRITE
	if not _arquivos.has(o):
		return ERR_FILE_NOT_FOUND
	if _arquivos.has(d):
		return ERR_ALREADY_EXISTS
	var b: PackedByteArray = _arquivos[o]
	_arquivos[d] = b.duplicate()
	return OK


func existe(caminho: String) -> bool:
	var c: String = _normalizar(caminho)
	_registrar(&"existe", c)
	return _arquivos.has(c) or _pastas.has(c)


func listar_arquivos(pasta: String) -> PackedStringArray:
	var p: String = _normalizar(pasta)
	var nomes := PackedStringArray()
	if _falha_programada(&"listar_arquivos", p):
		return nomes
	for chave in _arquivos.keys():
		var caminho: String = chave
		if caminho.get_base_dir() == p:
			nomes.append(caminho.get_file())
	return nomes


func apagar(caminho: String) -> Error:
	var c: String = _normalizar(caminho)
	if _falha_programada(&"apagar", c):
		return ERR_FILE_CANT_WRITE
	if not _arquivos.has(c):
		return ERR_FILE_NOT_FOUND
	_arquivos.erase(c)
	return OK


func garantir_pasta(pasta: String) -> Error:
	var p: String = _normalizar(pasta)
	if _falha_programada(&"garantir_pasta", p):
		return ERR_CANT_CREATE
	_pastas[p] = true
	return OK


func criar_escritor_de_linhas(caminho: String) -> EscritorDeLinhas:
	var c: String = _normalizar(caminho)
	if _falha_programada(&"criar_escritor_de_linhas", c):
		return null
	_arquivos[c] = PackedByteArray()
	return EscritorEmMemoria.new(self, c)


# Registra a chamada e diz se ela deve falhar (pela ordem desta operação).
func _falha_programada(operacao: StringName, alvo: String) -> bool:
	var n: int = int(_chamadas.get(operacao, 0)) + 1
	_chamadas[operacao] = n
	_registrar(operacao, alvo)
	if not _falhas.has(operacao):
		return false
	var ordens: Array = _falhas[operacao]
	return ordens.has(SEMPRE) or ordens.has(n)


func _registrar(operacao: StringName, alvo: String) -> void:
	_registro.append(String(operacao) + " " + alvo)


# Remove barra final para que "user://telemetria/" e "user://telemetria" coincidam.
func _normalizar(caminho: String) -> String:
	if caminho.ends_with("/") and not caminho.ends_with("://"):
		return caminho.substr(0, caminho.length() - 1)
	return caminho
