## Save da sessão (save-e-perfil R4, R5, R7, R10–R13; ADR-0013 §7; ADR-0015).
##
## Lógica pura, sem [code]SceneTree[/code] nem Autoload, composta pelo [code]Main[/code]
## por [method configurar]. Decide [b]quando[/b] o perfil é lido e gravado; o formato é do
## [PerfilDaSessao] injetado ([RepositorioDePerfil] ou [PerfilNulo]). Só thread principal.
##
## Estados: [constant Estado.NAO_CARREGADO] → [method carregar] uma vez por sessão
## (depois do catálogo Pronto/Falhou, antes da escolha de arma) → [constant Estado.NORMAL]
## ou [constant Estado.SEM_GRAVACAO]. "Pendente" é sub-estado de Normal ([method pendente]).
##
## Gatilhos (R5): eventos [code]pacto_registrado[/code], [code]run_encerrada[/code] e
## [code]dupla_confirmada[/code] lidos em [method consumir] (ADR-0002), [method marcar_pendente],
## [method resetar] e [method importar_texto] só [b]marcam pendente[/b]. A gravação acontece em
## [method gravar_se_pendente], que o [code]Main[/code] chama no fim do passo, depois da
## entrega dos eventos, e que recusa [constant EstadoDeJogo.Valor.JOGO]. Vários gatilhos
## viram uma gravação. A saída ([method pedir_saida]) grava na hora: o [code]Main[/code]
## a chama fora do passo, quando não haverá passo seguinte.
##
## Avisos: [param avisar] (mesmo [Callable] do repositório) recebe
## [constant AVISO_FALHA_GRAVAR] e [constant AVISO_SAIR_SEM_SALVAR], cada um no máximo uma vez.
##
## Exemplo (composição e fim de passo no [code]Main[/code]):
## [codeblock]
## var save := Save.new()
## save.configurar(RepositorioDePerfil.new(armazem, caminhos, avisos.receber, ids, vinculo),
##         avisos.receber)
## save.carregar(catalogo.estado() == Catalogo.PRONTO)
## # fim de cada passo, depois de entregar os eventos:
## save.consumir(eventos_do_passo)
## save.gravar_se_pendente(orquestrador.estado())
## # NOTIFICATION_WM_CLOSE_REQUEST:
## if save.pedir_saida(vinculo.consolidar_abandono) != OK:
##     pass  # tela PERFIL_SAIR_SEM_SALVAR → save.tentar_saida_de_novo() por clique
## [/codeblock]
class_name Save
extends ConsumidorDeEventos

## Estado do Save na sessão (save-e-perfil "States and Transitions").
enum Estado { NAO_CARREGADO, NORMAL, SEM_GRAVACAO }

## Aviso de falha de gravação (R7; chave do ADR-0013, Decisão do usuário 1).
const AVISO_FALHA_GRAVAR: StringName = &"PERSIST_FALHA_GRAVAR"
## Aviso de falha ao gravar na saída (R10).
const AVISO_SAIR_SEM_SALVAR: StringName = &"PERFIL_SAIR_SEM_SALVAR"

## Evento do Vínculo (vinculo-e-pactos V32).
const EV_PACTO_REGISTRADO: StringName = &"pacto_registrado"
## Evento da Run (vitória, derrota ou abandono; AC-RN-10).
const EV_RUN_ENCERRADA: StringName = &"run_encerrada"
## Evento da confirmação da dupla (ADR-0015, ADR-0013 §7).
const EV_DUPLA_CONFIRMADA: StringName = &"dupla_confirmada"

## Confirmações exigidas pelo reset (R11: duas telas).
const CONFIRMACOES_DO_RESET: int = 2

# Estados de fim de passo em que se grava (R5.1). JOGO e INICIANDO ficam de fora.
const _ESTADOS_SEGUROS: Array[EstadoDeJogo.Valor] = [
	EstadoDeJogo.Valor.MENU, EstadoDeJogo.Valor.PAUSA, EstadoDeJogo.Valor.BENCAO,
	EstadoDeJogo.Valor.TRANSICAO, EstadoDeJogo.Valor.MORTE,
]
const _GATILHOS: Array[StringName] = [EV_PACTO_REGISTRADO, EV_RUN_ENCERRADA, EV_DUPLA_CONFIRMADA]

var _perfil: PerfilDaSessao
var _avisar: Callable
var _estado: Estado = Estado.NAO_CARREGADO
var _pendente: bool = false
var _avisos_emitidos: Dictionary = {}


## Injeta o perfil e o canal de avisos. Chamado uma vez pelo [code]Main[/code] antes de
## [method carregar].
func configurar(perfil: PerfilDaSessao, avisar: Callable) -> void:
	_perfil = perfil
	_avisar = avisar


## Carga da sessão (R4, TR-save-004/005). Só a primeira chamada tem efeito; as seguintes
## devolvem o modo atual sem ler nada. [param catalogo_pronto] [code]false[/code] (catálogo em
## Falhou) → Sem gravação sem ler nem avisar (AC-SP-21).
func carregar(catalogo_pronto: bool) -> ModoDoPerfil.Valor:
	if _estado != Estado.NAO_CARREGADO:
		return modo()
	if not catalogo_pronto:
		_estado = Estado.SEM_GRAVACAO
		return modo()
	var m: ModoDoPerfil.Valor = _perfil.carregar()
	_estado = Estado.NORMAL if m == ModoDoPerfil.Valor.NORMAL else Estado.SEM_GRAVACAO
	return modo()


## Estado atual.
func estado() -> Estado:
	return _estado


## Modo visto de fora: [constant ModoDoPerfil.Valor.NORMAL] só em [constant Estado.NORMAL].
func modo() -> ModoDoPerfil.Valor:
	return ModoDoPerfil.Valor.NORMAL if _estado == Estado.NORMAL else ModoDoPerfil.Valor.SEM_GRAVACAO


## [code]true[/code] se algum gatilho espera o próximo ponto seguro.
func pendente() -> bool:
	return _pendente


## Gatilho direto (ex.: Sair pelo menu antes de [method pedir_saida]). Nunca grava.
func marcar_pendente() -> void:
	_pendente = true


## Lê a lista entregue do passo e marca pendente nos gatilhos de R5 (TR-save-006).
## Só lê o [method EventoDoPasso.tipo]; nunca emite nem guarda o evento.
func consumir(eventos: Array[EventoDoPasso]) -> void:
	for e: EventoDoPasso in eventos:
		if _GATILHOS.has(e.tipo()):
			_pendente = true


## Ponto seguro (R5.1, R5.3, R7). Chamado pelo [code]Main[/code] no fim do passo, depois da
## entrega dos eventos. Devolve:
## [constant OK] sem pendente ou gravado (ou texto igual);
## [constant ERR_BUSY] em [constant EstadoDeJogo.Valor.JOGO]/INICIANDO ou antes da carga
## (o pendente fica para depois);
## [constant ERR_UNAVAILABLE] em Sem gravação (o pendente é descartado, nada é tocado);
## senão o erro da gravação: o pendente é descartado (sem laço de nova tentativa; o próximo
## gatilho tenta de novo), o estado em memória continua valendo e
## [constant AVISO_FALHA_GRAVAR] sai uma vez por sessão.
func gravar_se_pendente(estado_de_jogo: EstadoDeJogo.Valor) -> Error:
	if not _pendente:
		return OK
	if _estado == Estado.NAO_CARREGADO or not _ESTADOS_SEGUROS.has(estado_de_jogo):
		return ERR_BUSY
	_pendente = false
	if _estado == Estado.SEM_GRAVACAO:
		return ERR_UNAVAILABLE
	var err: Error = _perfil.salvar()
	if err != OK:
		_emitir_aviso(AVISO_FALHA_GRAVAR)
	return err


## Saída do jogo (R10, TR-save-013): menu Sair ou fechar a janela (o [code]Main[/code]
## intercepta o pedido e chama aqui, fora do passo). Chama [param consolidar_abandono]
## (o Vínculo fecha a run como abandono) se válido e grava na hora. [constant OK] → pode
## sair (também em Sem gravação ou antes da carga, quando não há o que gravar). Erro →
## [constant AVISO_SAIR_SEM_SALVAR] (uma vez) e a tela oferece [method tentar_saida_de_novo]
## ou sair sem salvar.
func pedir_saida(consolidar_abandono: Callable = Callable()) -> Error:
	if consolidar_abandono.is_valid():
		consolidar_abandono.call()
	if _estado != Estado.NORMAL:
		_pendente = false
		return OK
	var err: Error = _gravar_saida()
	if err != OK:
		_emitir_aviso(AVISO_SAIR_SEM_SALVAR)
	return err


## "Tentar de novo" da tela de saída: exatamente uma tentativa por chamada, sem aviso novo.
func tentar_saida_de_novo() -> Error:
	if _estado != Estado.NORMAL:
		return OK
	return _gravar_saida()


## Reset disponível só com o perfil carregado em Normal (R11). O "só no menu principal" é
## garantido por quem mostra o item (Opções, ADR-0012).
func reset_disponivel() -> bool:
	return _estado == Estado.NORMAL


## Reset do perfil (R11, TR-save-014). [param confirmacoes] = telas confirmadas pelo
## jogador; abaixo de [constant CONFIRMACOES_DO_RESET] → [constant ERR_UNAUTHORIZED] sem
## efeito. Indisponível → [constant ERR_UNAVAILABLE]. Erro do perfil (cópia
## [code].reset.bak[/code] falhou) → reset cancelado, nada muda. [constant OK] → perfil
## pendente; grava no próximo [method gravar_se_pendente].
func resetar(confirmacoes: int) -> Error:
	if not reset_disponivel():
		return ERR_UNAVAILABLE
	if confirmacoes < CONFIRMACOES_DO_RESET:
		return ERR_UNAUTHORIZED
	var err: Error = _perfil.resetar()
	if err == OK:
		_pendente = true
	return err


## Porta de exportar (R12): texto do perfil atual (sem Fragmentos nem RNG).
func exportar_texto() -> String:
	return _perfil.exportar_texto()


## Porta de importar (R12): mesma validação da carga; [constant OK] marca pendente;
## erro não altera o estado. Antes da carga → [constant ERR_BUSY].
func importar_texto(texto: String) -> Error:
	if _estado == Estado.NAO_CARREGADO:
		return ERR_BUSY
	var err: Error = _perfil.importar_texto(texto)
	if err == OK:
		_pendente = true
	return err


func _gravar_saida() -> Error:
	var err: Error = _perfil.salvar()
	if err == OK:
		_pendente = false
	return err


func _emitir_aviso(chave: StringName) -> void:
	if _avisos_emitidos.has(chave):
		return
	_avisos_emitidos[chave] = true
	if _avisar.is_valid():
		_avisar.call(chave)
