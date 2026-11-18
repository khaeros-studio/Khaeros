## Contrato do perfil que o [Save] usa (ADR-0013 §7; save-e-perfil R4, R11–R13).
##
## Duas implementações: [RepositorioDePerfil] (lê e grava [code]user://perfil.cfg[/code]
## pelo armazém) e [PerfilNulo] (não lê, não grava). A composição escolhe qual injetar,
## sem [code]if[/code] dentro do [Save] (TR-save-016). Não é thread-safe.
##
## Exemplo:
## [codeblock]
## var perfil: PerfilDaSessao = PerfilNulo.new(vinculo) if debug_sem_perfil \
##         else RepositorioDePerfil.new(armazem, CaminhosDePersistencia.de(0), avisar, ids, vinculo)
## save.configurar(perfil, avisar)
## [/codeblock]
@abstract
class_name PerfilDaSessao
extends RefCounted


## Carrega uma vez e entrega o resultado à porta do dono ([code]ler()[/code]). Nunca falha.
@abstract func carregar() -> ModoDoPerfil.Valor


## Modo atual da sessão.
@abstract func modo() -> ModoDoPerfil.Valor


## Grava o estado atual se o texto mudou. [constant OK] sem tocar o disco se igual.
@abstract func salvar() -> Error


## Texto do perfil como seria gravado agora (porta de exportar, R12).
@abstract func exportar_texto() -> String


## Aplica [param texto] com a mesma validação da carga; erro ≠ [constant OK] não altera o estado.
@abstract func importar_texto(texto: String) -> Error


## Reset do perfil (R11): cópia [code].reset.bak[/code], [code]ler({})[/code], descarta
## órfãs e seções preservadas. Não grava (o [Save] marca pendente). Erro = cancelado.
@abstract func resetar() -> Error
