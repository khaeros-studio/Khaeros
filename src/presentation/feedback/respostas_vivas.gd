class_name RespostasVivas
extends RefCounted
## Gerencia respostas visuais ativas nos relógios `t_vivo` e `t_apres`,
## transições de estado (`JOGO`, `PAUSA`, `BENCAO`, `TRANSICAO`), limitador de flash
## de acerto da Maldição (`1` a cada `20` passos vivos = `<= 3/s`) e marca única do Virote.

const INTERVALO_MIN_FLASH_MALDICAO_PASSOS: int = 20

var _vfx_ativos: Array[PedidosDeFeedback.PedidoVfx] = []
var _letreiros_ativos: Array[StringName] = []
var _passo_vivo_atual: int = 0
var _ultimo_passo_flash_maldicao: Dictionary = {} # int (maldicao_id) -> int (passo_vivo)
var _alvo_marca_virote_id: int = -1
var _estado_anterior: int = EstadoDeJogo.Valor.JOGO


func vfx_ativos() -> Array[PedidosDeFeedback.PedidoVfx]:
	return _vfx_ativos


func letreiros_ativos() -> Array[StringName]:
	return _letreiros_ativos


func alvo_marca_virote_id() -> int:
	return _alvo_marca_virote_id


func adicionar_vfx(pedido: PedidosDeFeedback.PedidoVfx) -> void:
	if pedido != null:
		_vfx_ativos.append(pedido)


func adicionar_letreiro(chave_letreiro: StringName) -> void:
	if chave_letreiro != &"":
		_letreiros_ativos.append(chave_letreiro)


func registrar_marca_virote(alvo_id: int) -> void:
	_alvo_marca_virote_id = alvo_id


func limpar_marca_virote_se_alvo(alvo_id: int) -> void:
	if _alvo_marca_virote_id == alvo_id or alvo_id < 0:
		_alvo_marca_virote_id = -1


## Limita o flash de `maldicao_atingida` a no máximo 1 a cada 20 passos vivos (`<= 3/s`).
func pode_emitir_flash_maldicao(maldicao_id: int) -> bool:
	if not _ultimo_passo_flash_maldicao.has(maldicao_id):
		_ultimo_passo_flash_maldicao[maldicao_id] = _passo_vivo_atual
		return true
	var ultimo: int = int(_ultimo_passo_flash_maldicao[maldicao_id])
	if _passo_vivo_atual - ultimo >= INTERVALO_MIN_FLASH_MALDICAO_PASSOS:
		_ultimo_passo_flash_maldicao[maldicao_id] = _passo_vivo_atual
		return true
	return false


func avancar_relogios(
	dt_vivo: float,
	dt_apres: float,
	hitstop_ativo: bool,
	estado_jogo: int,
	pool_numeros: PoolDeNumeros = null
) -> void:
	_aplicar_mudanca_de_estado(estado_jogo, pool_numeros)
	if estado_jogo == EstadoDeJogo.Valor.PAUSA or estado_jogo == EstadoDeJogo.Valor.TRANSICAO:
		return

	if not hitstop_ativo and dt_vivo > 0.0:
		_passo_vivo_atual += 1

	if pool_numeros != null and estado_jogo != EstadoDeJogo.Valor.BENCAO:
		pool_numeros.avancar_apres(dt_apres, false)

	var i: int = _vfx_ativos.size() - 1
	while i >= 0:
		var v: PedidosDeFeedback.PedidoVfx = _vfx_ativos[i]
		var dt_efetivo: float = dt_apres if v.relogio == &"apres" else (0.0 if hitstop_ativo else dt_vivo)
		v.duracao_s -= dt_efetivo
		if v.duracao_s <= 0.0:
			_vfx_ativos.remove_at(i)
		i -= 1


func _aplicar_mudanca_de_estado(novo_estado: int, pool_numeros: PoolDeNumeros) -> void:
	if novo_estado == _estado_anterior:
		return
	if novo_estado == EstadoDeJogo.Valor.BENCAO:
		# Na Bênção, números flutuantes e letreiros somem e não são restaurados ao voltar
		if pool_numeros != null:
			pool_numeros.limpar_tudo()
		_letreiros_ativos.clear()
	elif novo_estado == EstadoDeJogo.Valor.TRANSICAO:
		# Na Transição de câmara, descarta fila, VFX ativos, números e marca do Virote
		if pool_numeros != null:
			pool_numeros.limpar_tudo()
		_vfx_ativos.clear()
		_letreiros_ativos.clear()
		_alvo_marca_virote_id = -1
		_ultimo_passo_flash_maldicao.clear()
	_estado_anterior = novo_estado
