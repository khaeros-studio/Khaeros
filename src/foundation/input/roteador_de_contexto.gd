class_name RoteadorDeContexto
extends RefCounted
## Roteador de contexto de input com retorno explícito (GDD input-e-controle R10, R11; ADR-0006 §3; ADR-0001).
##
## Estado global de jogo e contexto de input são coisas diferentes: o roteador mantém uma pilha de contextos
## (base + sobreposições, ex.: Bênção → Pausa → Menu de opções) e uma sobreposição "Sem foco" separada.
## Ele NÃO muda o estado do jogo: pausar e retomar passam por `pedir_estado(pedido) -> bool` (injetado pelo
## orquestrador, ADR-0001) e a pilha só muda se o pedido for aceito. Nada de `SceneTree.paused`.
##
## Cada mudança do contexto efetivo chama `ao_trocar(contexto)` (em produção, `ProvedorDeEntrada.trocar_contexto`),
## que aplica a barreira na hora: capacidade inválida, buffer vazio e entradas seguradas bloqueadas até a soltura.
## O orquestrador consulta `contexto()` antes de amostrar e, se `processar_amostra` devolver `true`, não
## distribui a amostra antiga aos consumidores seguintes (ADR-0006 §3).

## Pedido de estado: abrir a Pausa (ADR-0001 `pedir_estado(PAUSA)`).
const PEDIDO_PAUSA := &"pausa"
## Pedido de estado: fechar a Pausa e voltar ao estado de baixo (Jogo ou Bênção).
const PEDIDO_RETOMAR := &"retomar"

var _pedir_estado: Callable
var _ao_trocar: Callable
var _pilha: Array[StringName] = []
var _sem_foco: bool = false
var _pausa_memorizada: bool = false
var _efetivo: StringName = &""


## `pedir_estado(pedido: StringName) -> bool`: pedido ao orquestrador; `true` = aceito.
## `ao_trocar(contexto: StringName) -> void`: chamado a cada mudança do contexto efetivo (pode ser vazio).
func _init(pedir_estado: Callable, ao_trocar: Callable = Callable()) -> void:
	_pedir_estado = pedir_estado
	_ao_trocar = ao_trocar


## Contexto efetivo do passo (`sem_foco` se a janela está sem foco; senão o topo da pilha; vazio antes da base).
func contexto() -> StringName:
	if _sem_foco:
		return Acoes.CONTEXTO_SEM_FOCO
	if _pilha.is_empty():
		return &""
	return _pilha[_pilha.size() - 1]


## Contexto de base (fundo da pilha), ex.: Jogo sob uma Pausa.
func base() -> StringName:
	return _pilha[0] if not _pilha.is_empty() else &""


## Pilha atual (cópia), da base ao topo.
func pilha() -> Array[StringName]:
	return _pilha.duplicate()


## Verdadeiro se há uma Pausa memorizada durante a Transição (R11).
func pausa_memorizada() -> bool:
	return _pausa_memorizada


## Define a base e descarta as sobreposições (Jogo, Bênção, Transição/passe de morte, Menu, tela final).
## Ao voltar a Jogo com Pausa memorizada, a Pausa entra no mesmo passo, antes de Movimento/Combate (R11).
func definir_base(contexto_base: StringName) -> void:
	_pilha.clear()
	_pilha.append(contexto_base)
	if contexto_base == Acoes.CONTEXTO_JOGO and _pausa_memorizada:
		_pausa_memorizada = false
		if _pedir(PEDIDO_PAUSA):
			_pilha.append(Acoes.CONTEXTO_PAUSA)
	_notificar()


## Abre uma sobreposição com retorno explícito (Menu de opções sobre a Pausa, Texto, Remapeando).
func abrir(sobreposicao: StringName) -> void:
	_pilha.append(sobreposicao)
	_notificar()


## Fecha a sobreposição do topo e volta ao contexto de baixo. A base nunca é fechada por aqui.
func fechar() -> bool:
	if _pilha.size() <= 1:
		return false
	_pilha.pop_back()
	_notificar()
	return true


## Trata as ações de contexto da amostra do passo (`pausar`, `ui_voltar`). Devolve `true` se o contexto mudou:
## o orquestrador não deve distribuir esta amostra aos consumidores de regra (ADR-0006 §3).
## - Jogo/Bênção + `pausar` → pede Pausa; aceita, empilha a Pausa (a Bênção fica intacta embaixo).
## - Pausa + `pausar` → pede retomar; aceita, volta ao contexto de baixo.
## - Menu sobreposto + `ui_voltar` → fecha e volta (opções da Pausa → Pausa). Menu de base: nível da UI.
func processar_amostra(amostra: AmostraDeEntrada) -> bool:
	var atual := contexto()
	if amostra.foi_apertado(Acoes.PAUSAR):
		if atual == Acoes.CONTEXTO_JOGO or atual == Acoes.CONTEXTO_BENCAO:
			return pausar()
		if atual == Acoes.CONTEXTO_PAUSA:
			return retomar()
	if amostra.foi_apertado(Acoes.UI_VOLTAR) and atual == Acoes.CONTEXTO_MENU:
		return fechar()
	return false


## Pede a Pausa a partir de Jogo ou Bênção; `true` se o contexto mudou.
func pausar() -> bool:
	var atual := contexto()
	if atual != Acoes.CONTEXTO_JOGO and atual != Acoes.CONTEXTO_BENCAO:
		return false
	if not _pedir(PEDIDO_PAUSA):
		return false
	_pilha.append(Acoes.CONTEXTO_PAUSA)
	_notificar()
	return true


## Fecha a Pausa do topo (pedido de retomar); `true` se o contexto mudou.
func retomar() -> bool:
	if contexto() != Acoes.CONTEXTO_PAUSA or _pilha.size() <= 1:
		return false
	if not _pedir(PEDIDO_RETOMAR):
		return false
	_pilha.pop_back()
	_notificar()
	return true


## Perda de foco da janela (R11): em Jogo pede Pausa; na Transição memoriza a Pausa para o primeiro passo de
## Jogo; em Menu/Bênção só limpa as entradas. Em todos os casos entra "Sem foco" (nenhuma entrada ativa).
func perder_foco() -> void:
	if _sem_foco:
		return
	var atual := contexto()
	if atual == Acoes.CONTEXTO_JOGO:
		pausar()
	elif atual == Acoes.CONTEXTO_TRANSICAO:
		_pausa_memorizada = true
	_sem_foco = true
	_notificar()


## Recuperar o foco não fecha a Pausa; as entradas conhecidas como seguradas seguem bloqueadas até a soltura.
func recuperar_foco() -> void:
	if not _sem_foco:
		return
	_sem_foco = false
	_notificar()


## Desconexão do gamepad ativo (R10/AC-24): em Jogo pede Pausa. Em Bênção, Menu e Transição não pausa (a
## Transição está pendente de alinhamento de design no ADR-0006 §3: não inferir pausa automática).
func pausar_por_desconexao() -> bool:
	if contexto() != Acoes.CONTEXTO_JOGO:
		return false
	return pausar()


func _pedir(pedido: StringName) -> bool:
	if not _pedir_estado.is_valid():
		return false
	return bool(_pedir_estado.call(pedido))


func _notificar() -> void:
	var novo := contexto()
	if novo == _efetivo:
		return
	_efetivo = novo
	if _ao_trocar.is_valid():
		_ao_trocar.call(novo)
