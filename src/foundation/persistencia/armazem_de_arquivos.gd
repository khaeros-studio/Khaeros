## Única fronteira do jogo com o disco (ADR-0013 §1).
##
## Toda leitura e gravação passa por aqui; só [ArmazemUserGodot] toca
## [code]FileAccess[/code]/[code]DirAccess[/code]. Os caminhos são lógicos
## ([code]user://…[/code], vindos de [CaminhosDePersistencia]); a implementação real
## os resolve contra a sua raiz injetada. [b]Não é thread-safe[/b]: só a thread principal.
## Nada aqui é Autoload: o [code]Main[/code] compõe e injeta.
##
## Exemplo (dublê em teste):
## [codeblock]
## var a := ArmazemEmMemoria.new()
## a.programar_falha(&"gravar_atomico", 1)        # a 1ª gravação falha
## var err := a.gravar_atomico("user://perfil.cfg", "[meta]\n")   # != OK
## [/codeblock]
@abstract
class_name ArmazemDeArquivos
extends RefCounted


## Lê o arquivo inteiro. Ausente: [code]existe == false[/code], [code]ok == true[/code].
@abstract func ler_texto(caminho: String) -> LeituraDeArquivo


## Grava [param texto] de forma atômica (temporário, releitura, substituição; §4).
## Falha em qualquer passo devolve [code]Error[/code] != [constant OK] e mantém o
## arquivo anterior vigente. Sem laço de nova tentativa.
@abstract func gravar_atomico(caminho: String, texto: String) -> Error


## Copia [param origem] byte a byte para [param destino] (backups [code].bak[/code]).
## Nunca sobrescreve: destino existente devolve [constant ERR_ALREADY_EXISTS].
@abstract func copiar_bytes(origem: String, destino: String) -> Error


## [code]true[/code] se existe arquivo ou pasta em [param caminho].
@abstract func existe(caminho: String) -> bool


## Nomes (sem pasta) dos arquivos diretamente em [param pasta]; ordem indefinida.
@abstract func listar_arquivos(pasta: String) -> PackedStringArray


## Apaga o arquivo. Ausente devolve [constant ERR_FILE_NOT_FOUND].
@abstract func apagar(caminho: String) -> Error


## Cria a pasta (e as intermediárias) se não existir.
@abstract func garantir_pasta(pasta: String) -> Error


## Abre um arquivo novo para escrita sequencial; [code]null[/code] se não abrir.
@abstract func criar_escritor_de_linhas(caminho: String) -> EscritorDeLinhas
