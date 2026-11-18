class_name EstadosDaCamera
extends RefCounted
## Máquina de estados da câmera (GDD Cena, States and Transitions; ADR-0007 §6–§7).
##
## Hitstop não é estado: a câmera segue e `t_apres` corre. Pausa, Bênção, Morte e
## Transição congelam a câmera e zeram impulsos. Pausa aberta sobre a Bênção volta
## à Bênção. Corte dura um quadro e volta ao estado de retorno (Seguindo, ou
## Transição se o estado global ainda for Transição — Clarificação do ADR-0007).
##
## Exemplo:
## [codeblock]
## var e := EstadosDaCamera.new()
## e.entrar(EstadosDaCamera.Estado.PAUSA)
## e.retomar()   # volta a Seguindo (ou Bênção)
## [/codeblock]

## Estados da câmera.
enum Estado { SEGUINDO, CORTE, PAUSA, BENCAO, MORTE, TRANSICAO, INTRO_CHEFE }

## Coluna "Sai para" do GDD. Desvios registrados na story 006: Bênção → Pausa
## (pausa por cima da Bênção), Corte → Transição (corte durante o wipe) e
## Intro de chefe → Pausa/Morte.
const SAI_PARA: Dictionary[Estado, Array] = {
	Estado.SEGUINDO: [Estado.CORTE, Estado.PAUSA, Estado.BENCAO, Estado.MORTE, Estado.TRANSICAO, Estado.INTRO_CHEFE],
	Estado.CORTE: [Estado.SEGUINDO, Estado.TRANSICAO],
	Estado.PAUSA: [Estado.SEGUINDO, Estado.BENCAO],
	Estado.BENCAO: [Estado.SEGUINDO, Estado.PAUSA],
	Estado.MORTE: [],
	Estado.TRANSICAO: [Estado.CORTE, Estado.SEGUINDO],
	Estado.INTRO_CHEFE: [Estado.SEGUINDO, Estado.PAUSA, Estado.MORTE],
}

## Estado atual.
var atual: Estado:
	get: return _atual

var _atual: Estado = Estado.SEGUINDO
var _retorno_pausa: Estado = Estado.SEGUINDO
var _retorno_corte: Estado = Estado.SEGUINDO


## Tenta a transição; devolve `false` (sem mudar nada) se a tabela não permite.
## Entrar em Pausa guarda o estado de onde veio; entrar em Corte guarda o retorno.
func entrar(novo: Estado) -> bool:
	if novo == _atual:
		return true
	if not (SAI_PARA[_atual] as Array).has(novo):
		return false
	if novo == Estado.PAUSA:
		_retorno_pausa = _atual if _atual == Estado.BENCAO else Estado.SEGUINDO
	if novo == Estado.CORTE:
		_retorno_corte = Estado.TRANSICAO if _atual == Estado.TRANSICAO else Estado.SEGUINDO
	_atual = novo
	return true


## Sai da Pausa para o estado de onde ela abriu, ou do Corte para o retorno.
func retomar() -> void:
	if _atual == Estado.PAUSA:
		_atual = _retorno_pausa
	elif _atual == Estado.CORTE:
		_atual = _retorno_corte


## `true` em Pausa, Bênção, Morte e Transição (câmera parada, sem impulsos).
func congelada() -> bool:
	return _atual in [Estado.PAUSA, Estado.BENCAO, Estado.MORTE, Estado.TRANSICAO]


## `true` quando a câmera aceita impulsos (Seguindo e Intro de chefe).
func aceita_impulsos() -> bool:
	return _atual == Estado.SEGUINDO or _atual == Estado.INTRO_CHEFE
