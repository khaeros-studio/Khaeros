## Implementação real de [ArmazemDeArquivos] sobre [code]FileAccess[/code]/[code]DirAccess[/code]
## (ADR-0013 §1, §4). É a [b]única[/b] classe do jogo que toca o disco.
##
## Caminhos lógicos [code]user://…[/code] são resolvidos contra a [b]raiz injetada[/b]:
## [code]user://[/code] em produção, [code]user://_testes/<caso>/[/code] nos testes [I].
## Não é thread-safe: só a thread principal.
##
## [b]Gravação atômica[/b] ([method gravar_atomico]): (1) grava [code]caminho.tmp[/code]
## inteiro e verifica o [code]bool[/code] de [code]store_string[/code] (4.4+); (2) relê o
## [code].tmp[/code] e compara com o texto (para [code].cfg[/code], também reinterpreta
## com [code]ConfigFile.parse[/code]); (3) substitui o destino com uma chamada
## [code]DirAccess.rename_absolute[/code]. Escolha pela medição de E-P2 (2026-11-16,
## Windows 11, 4.7.2): [code]rename[/code] sobre destino existente devolve [constant OK]
## e substitui; com o destino aberto por outro handle devolve [constant FAILED] e o
## destino antigo fica intacto. Por isso não há a sequência com [code].old[/code];
## a recuperação ainda trata [code].old[/code] (inofensiva) via [RecuperacaoDeGravacao].
## Falha em qualquer passo apaga o [code].tmp[/code] e devolve o erro, sem nova tentativa.
##
## Exemplo:
## [codeblock]
## var a := ArmazemUserGodot.new()            # raiz user://
## var err := a.gravar_atomico("user://perfil.cfg", texto)
## var l := a.ler_texto("user://perfil.cfg")   # recupera sobras antes de ler
## [/codeblock]
class_name ArmazemUserGodot
extends ArmazemDeArquivos

## Sem queda simulada.
const QUEDA_NENHUMA: int = 0
## Queda simulada no meio da escrita do [code].tmp[/code] (fica truncado).
const QUEDA_TMP_PARCIAL: int = 1
## Queda simulada com [code].tmp[/code] completo, antes da substituição.
const QUEDA_ANTES_DE_SUBSTITUIR: int = 2

const _PREFIXO_LOGICO: String = "user://"

var _raiz: String

## [b]Só para testes [I][/b] (AC-SP-24): a próxima [method gravar_atomico] para no
## ponto indicado, deixa os arquivos como uma queda deixaria e devolve [constant ERR_BUSY].
## Volta sozinho a [constant QUEDA_NENHUMA] depois de uma gravação.
var simular_queda: int = QUEDA_NENHUMA


## [param raiz] deve terminar em [code]/[/code]; ex.: [code]"user://_testes/caso/"[/code].
func _init(raiz: String = _PREFIXO_LOGICO) -> void:
	_raiz = raiz if raiz.ends_with("/") else raiz + "/"


## Caminho físico (ainda [code]user://[/code], sem globalizar) de um caminho lógico.
func resolver(caminho: String) -> String:
	if caminho.begins_with(_PREFIXO_LOGICO):
		return _raiz + caminho.substr(_PREFIXO_LOGICO.length())
	return caminho


func ler_texto(caminho: String) -> LeituraDeArquivo:
	var fisico: String = resolver(caminho)
	_recuperar_sobras(fisico)
	if not FileAccess.file_exists(fisico):
		return LeituraDeArquivo.ausente()
	var f := FileAccess.open(fisico, FileAccess.READ)
	if f == null:
		return LeituraDeArquivo.falhou(FileAccess.get_open_error())
	var conteudo: PackedByteArray = f.get_buffer(f.get_length())
	var erro: Error = f.get_error()
	f.close()
	if erro != OK and erro != ERR_FILE_EOF:
		return LeituraDeArquivo.falhou(erro)
	return LeituraDeArquivo.lida(conteudo)


func gravar_atomico(caminho: String, texto: String) -> Error:
	var fisico: String = resolver(caminho)
	var tmp: String = fisico + ".tmp"
	var queda: int = simular_queda
	simular_queda = QUEDA_NENHUMA
	var err: Error = DirAccess.make_dir_recursive_absolute(fisico.get_base_dir())
	if err != OK:
		return err
	# (1) temporário inteiro
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	var conteudo: String = texto
	if queda == QUEDA_TMP_PARCIAL:
		conteudo = texto.substr(0, int(texto.length() * 0.5))
	var escreveu: bool = f.store_string(conteudo)
	f.close()
	if queda == QUEDA_TMP_PARCIAL:
		return ERR_BUSY
	if not escreveu:
		DirAccess.remove_absolute(tmp)
		return ERR_FILE_CANT_WRITE
	# (2) releitura e comparação
	if not FileAccess.file_exists(tmp) or FileAccess.get_file_as_string(tmp) != texto:
		DirAccess.remove_absolute(tmp)
		return ERR_FILE_CORRUPT
	if fisico.ends_with(".cfg") and ConfigFile.new().parse(texto) != OK:
		DirAccess.remove_absolute(tmp)
		return ERR_PARSE_ERROR
	if queda == QUEDA_ANTES_DE_SUBSTITUIR:
		return ERR_BUSY
	# (3) substituição (E-P2: uma chamada substitui destino existente)
	err = DirAccess.rename_absolute(tmp, fisico)
	if err != OK:
		DirAccess.remove_absolute(tmp)
		return err
	return OK


func copiar_bytes(origem: String, destino: String) -> Error:
	var o: String = resolver(origem)
	var d: String = resolver(destino)
	if not FileAccess.file_exists(o):
		return ERR_FILE_NOT_FOUND
	if FileAccess.file_exists(d):
		return ERR_ALREADY_EXISTS
	var fo := FileAccess.open(o, FileAccess.READ)
	if fo == null:
		return FileAccess.get_open_error()
	var conteudo: PackedByteArray = fo.get_buffer(fo.get_length())
	fo.close()
	var fd := FileAccess.open(d, FileAccess.WRITE)
	if fd == null:
		return FileAccess.get_open_error()
	var ok: bool = fd.store_buffer(conteudo)
	fd.close()
	if not ok:
		DirAccess.remove_absolute(d)
		return ERR_FILE_CANT_WRITE
	return OK


func existe(caminho: String) -> bool:
	var fisico: String = resolver(caminho)
	return FileAccess.file_exists(fisico) or DirAccess.dir_exists_absolute(fisico)


func listar_arquivos(pasta: String) -> PackedStringArray:
	var fisico: String = resolver(pasta)
	if not DirAccess.dir_exists_absolute(fisico):
		return PackedStringArray()
	return DirAccess.get_files_at(fisico)


func apagar(caminho: String) -> Error:
	var fisico: String = resolver(caminho)
	if not FileAccess.file_exists(fisico):
		return ERR_FILE_NOT_FOUND
	return DirAccess.remove_absolute(fisico)


func garantir_pasta(pasta: String) -> Error:
	return DirAccess.make_dir_recursive_absolute(resolver(pasta))


func criar_escritor_de_linhas(caminho: String) -> EscritorDeLinhas:
	var f := FileAccess.open(resolver(caminho), FileAccess.WRITE)
	if f == null:
		return null
	return EscritorGodot.new(f)


## Escritor real. [method descarregar] = [code]flush()[/code] + [code]get_error()[/code]
## (onde a falha aparece ainda é E-P1, NOT SOURCEABLE).
class EscritorGodot extends EscritorDeLinhas:
	var _f: FileAccess

	func _init(f: FileAccess) -> void:
		_f = f

	func escrever_linha(texto: String) -> bool:
		if _f == null:
			return false
		return _f.store_line(texto)

	func descarregar() -> bool:
		if _f == null:
			return false
		_f.flush()
		return _f.get_error() == OK

	func fechar() -> void:
		if _f != null:
			_f.close()
			_f = null


# Executa o plano puro de RecuperacaoDeGravacao. Falhas aqui são ignoradas: a
# leitura que segue decide (destino ausente = ausente; .tmp nunca é promovido).
func _recuperar_sobras(fisico: String) -> void:
	var old: String = fisico + ".old"
	var tmp: String = fisico + ".tmp"
	var acoes := RecuperacaoDeGravacao.planejar(
		FileAccess.file_exists(fisico), FileAccess.file_exists(old), FileAccess.file_exists(tmp))
	for acao in acoes:
		match acao:
			RecuperacaoDeGravacao.RESTAURAR_OLD:
				DirAccess.rename_absolute(old, fisico)
			RecuperacaoDeGravacao.APAGAR_OLD:
				DirAccess.remove_absolute(old)
			RecuperacaoDeGravacao.APAGAR_TMP:
				DirAccess.remove_absolute(tmp)
