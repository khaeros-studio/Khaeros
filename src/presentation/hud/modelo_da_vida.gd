class_name ModeloDaVida
extends RefCounted
## Submodelo reativo da Barra de Vida do jogador (`F1`, `F2`, `F3`, `R1`, `R2`, `R3`, `R8`, `R9`).
## - Segmentos de 10 em osso (`#F2EDE4`) e largura escalonada até `480 px` em 100%.
## - Racha de dano recente aguarda o fim do `hitstop_ativo()` (ou o sinal `preco_revelado` na Bênção)
##   antes de escorrer durante `racha_duracao_s`.
## - Moldura e vinheta de vida baixa com histerese inteira (`25%` entra, `30%` sai),
##   limitadas a `8%` de borda e `40%` de opacidade.
## - Losangos de recusa de morte (teto 3), barra de escudo e marca de `O Fundo do Poço`.

const UNIDADES_POR_SEGMENTO: int = 10
const LARGURA_BASE_100_PX: float = 260.0
const LARGURA_POR_ACRESCIMO_PX: float = 2.0
const LARGURA_TETO_100_PX: float = 480.0
const TETO_LOSANGOS_RECUSA: int = 3
const BORDA_VIDA_BAIXA_MAX_FRACAO: float = 0.08
const OPACIDADE_VIDA_BAIXA_MAX: float = 0.40

var _tuning: HudTuning = HudTuning.new()
var _vida_atual: int = 100
var _vida_max: int = 100
var _escudo_atual: int = 0
var _recusas_restantes: int = 0
var _recusas_max: int = 0
var _limiar_fundo_do_poco: int = 0

var _racha_topo_vida: float = 100.0
var _racha_atraso_restante_s: float = 0.0
var _aguardando_preco_revelado: bool = false
var _vida_baixa_ativa: bool = false
var _pulso_recusa_restante_s: float = 0.0


func _init(tuning: HudTuning = null) -> void:
	if tuning != null:
		_tuning = tuning


func configurar(tuning: HudTuning) -> void:
	if tuning != null:
		_tuning = tuning


func sincronizar(
	vida_vec: Vector2i,
	escudo_val: int,
	recusas_vec: Vector2i,
	limiar_poco: int,
	em_bencao: bool = false
) -> void:
	var novo_max: int = maxi(1, vida_vec.y)
	var novo_atual: int = clampi(vida_vec.x, 0, novo_max)

	if novo_atual < _vida_atual:
		# Dano ou preço de sangue: mantém topo da racha onde estava e arma atraso
		_racha_topo_vida = maxf(_racha_topo_vida, float(_vida_atual))
		_racha_atraso_restante_s = _tuning.racha_atraso_s
		if em_bencao:
			_aguardando_preco_revelado = true
	elif novo_atual > _vida_atual:
		# Cura ou aumento de vida: racha acompanha imediatamente se passar do topo
		if float(novo_atual) > _racha_topo_vida:
			_racha_topo_vida = float(novo_atual)

	if recusas_vec.x < _recusas_restantes:
		_pulso_recusa_restante_s = 0.45

	_vida_atual = novo_atual
	_vida_max = novo_max
	_racha_topo_vida = clampf(_racha_topo_vida, float(_vida_atual), float(_vida_max))
	_escudo_atual = maxi(0, escudo_val)
	_recusas_restantes = clampi(recusas_vec.x, 0, TETO_LOSANGOS_RECUSA)
	_recusas_max = clampi(recusas_vec.y, 0, TETO_LOSANGOS_RECUSA)
	_limiar_fundo_do_poco = clampi(limiar_poco, 0, _vida_max)
	_atualizar_histerese_vida_baixa()


func notificar_preco_revelado() -> void:
	_aguardando_preco_revelado = false


func avancar(dt_ui: float, hitstop_ativo: bool) -> void:
	if dt_ui <= 0.0:
		return
	if _pulso_recusa_restante_s > 0.0:
		_pulso_recusa_restante_s = maxf(0.0, _pulso_recusa_restante_s - dt_ui)

	# Racha de dano recente aguarda hitstop_ativo == false e preco_revelado na Bênção
	if hitstop_ativo or _aguardando_preco_revelado:
		return

	if _racha_topo_vida > float(_vida_atual):
		if _racha_atraso_restante_s > 0.0:
			_racha_atraso_restante_s = maxf(0.0, _racha_atraso_restante_s - dt_ui)
		else:
			var taxa: float = float(_vida_max) / maxf(0.05, _tuning.racha_duracao_s)
			_racha_topo_vida = move_toward(_racha_topo_vida, float(_vida_atual), taxa * dt_ui)


## F1 — Quantidade de segmentos de 10 na barra de vida (`ceil(vida_max / 10.0)`).
func quantidade_segmentos() -> int:
	return maxi(1, int(ceili(float(_vida_max) / float(UNIDADES_POR_SEGMENTO))))


## F2 — Largura da barra em pixels a 100% de escala, limitada a `480 px`.
func largura_barra_100_px() -> float:
	var extra: float = float(maxi(0, _vida_max - 100)) * LARGURA_POR_ACRESCIMO_PX
	return clampf(LARGURA_BASE_100_PX + extra, LARGURA_BASE_100_PX, LARGURA_TETO_100_PX)


func fracao_vida() -> float:
	return clampf(float(_vida_atual) / float(maxi(1, _vida_max)), 0.0, 1.0)


func fracao_racha() -> float:
	return clampf(_racha_topo_vida / float(maxi(1, _vida_max)), fracao_vida(), 1.0)


func fracao_escudo() -> float:
	if _escudo_atual <= 0:
		return 0.0
	return clampf(float(_escudo_atual) / float(maxi(1, _vida_max)), 0.0, 1.0)


func fracao_marca_fundo_do_poco() -> float:
	if _limiar_fundo_do_poco <= 0:
		return 0.0
	return clampf(float(_limiar_fundo_do_poco) / float(maxi(1, _vida_max)), 0.0, 1.0)


func vida_atual() -> int:
	return _vida_atual


func vida_max() -> int:
	return _vida_max


func escudo_atual() -> int:
	return _escudo_atual


func recusas_restantes() -> int:
	return _recusas_restantes


func recusas_max() -> int:
	return _recusas_max


func vida_baixa_ativa() -> bool:
	return _vida_baixa_ativa


func opacidade_moldura_vida_baixa(aviso_vida_baixa_opcoes: bool = true) -> float:
	if not _vida_baixa_ativa or not aviso_vida_baixa_opcoes:
		return 0.0
	return minf(OPACIDADE_VIDA_BAIXA_MAX, _tuning.opacidade_vida_baixa)


func fracao_borda_vida_baixa() -> float:
	return BORDA_VIDA_BAIXA_MAX_FRACAO if _vida_baixa_ativa else 0.0


func texto_vida_formatado() -> String:
	return FormatoNumerico.formatar_razao(_vida_atual, _vida_max)


func _atualizar_histerese_vida_baixa() -> void:
	if _vida_atual <= 0:
		_vida_baixa_ativa = false
		return
	# Histerese inteira exata: entra quando vida * 100 <= limiar_entrar * vida_max (25%)
	# sai quando vida * 100 >= limiar_sair * vida_max (30%)
	var pct_entrar: int = int(roundi(_tuning.limiar_vida_baixa_entrar * 100.0))
	var pct_sair: int = int(roundi(_tuning.limiar_vida_baixa_sair * 100.0))
	if not _vida_baixa_ativa:
		if _vida_atual * 100 <= pct_entrar * _vida_max:
			_vida_baixa_ativa = true
	else:
		if _vida_atual * 100 >= pct_sair * _vida_max:
			_vida_baixa_ativa = false
