class_name AmostraDeEntrada
extends RefCounted
## Amostra de entrada de um passo (GDD input-e-controle R2, R1b; ADR-0006 §2). Somente leitura por convenção:
## os campos de valor são públicos; listas saem por métodos que devolvem cópia.
##
## Os 9 campos de R2: `mover`, `mirar`, `fonte_mira`, `intensidade_mira`, `ponto_mira`, segurados, apertados,
## visão do buffer e escolha de tela. Mais `id_passo` e `epoca_contexto`.

const FONTE_MOUSE := &"mouse"
const FONTE_ANALOGICO := &"analogico"
const FONTE_AUTOMATICA := &"automatica"

## Passo de física desta amostra.
var id_passo: int = 0
## Época do contexto em que foi amostrada (muda a cada troca de contexto).
var epoca_contexto: int = 0
## Contexto de entrada da amostra.
var contexto: StringName = &""
## Movimento, módulo 0..1.
var mover: Vector2 = Vector2.ZERO
## Mira, unitária.
var mirar: Vector2 = Vector2.UP
## `mouse`, `analogico` ou `automatica` (R5).
var fonte_mira: StringName = FONTE_AUTOMATICA
## Módulo do analógico direito após F2; 0 quando a fonte não é `analogico`.
var intensidade_mira: float = 0.0
## Ponto de mira em mundo; só vale se `tem_ponto_mira` (vazio caso contrário, R1b).
var ponto_mira: Vector2 = Vector2.ZERO
## Falso = `ponto_mira` vazio.
var tem_ponto_mira: bool = false
## Escolha de tela do passo (stories 005/009); vazio sem escolha.
var escolha_tela: StringName = &""
## Dispositivo ativo no passo (R3), para ícones da UI.
var dispositivo_ativo: StringName = Acoes.DISPOSITIVO_TECLADO
## Prazo do buffer no começo do passo.
var prazo_buffer: int = 0

var _segurados: Array[StringName] = []
var _apertados: Array[StringName] = []
var _buffer: Array[StringName] = []


func _init(p_segurados: Array[StringName] = [], p_apertados: Array[StringName] = [],
		p_buffer: Array[StringName] = []) -> void:
	_segurados = p_segurados.duplicate()
	_apertados = p_apertados.duplicate()
	_buffer = p_buffer.duplicate()


## Ações seguradas neste passo (cópia).
func segurados() -> Array[StringName]:
	return _segurados.duplicate()


## Ações apertadas neste passo (cópia, em ordem de chegada).
func apertados() -> Array[StringName]:
	return _apertados.duplicate()


## Visão do buffer no começo do passo (cópia); não reflete consumo posterior.
func buffer() -> Array[StringName]:
	return _buffer.duplicate()


## Verdadeiro se `acao` está segurada.
func esta_segurado(acao: StringName) -> bool:
	return _segurados.has(acao)


## Verdadeiro se `acao` foi apertada neste passo.
func foi_apertado(acao: StringName) -> bool:
	return _apertados.has(acao)
