class_name LimitadorDeFlashes
extends RefCounted
## Limitador de flashes luminosos (F6 do GDD pipeline-visual.md; ADR-0011 §1, §7).
## Protege contra fotosensibilidade (WCAG 2.3.1):
## - Teto de frequência: no máximo 3 flashes na janela semiaberta (t - 1_000_000 µs, t].
## - Teto de impacto: no máximo 1 impact frame por segundo, com preempção do chefe sobre a recusa.
## - Área de disparo de telégrafos: só pede flash se Σ(area * zoom^2) >= 0.11 * 1920 * 1080 (228.096 px²).
## - Passe obrigatório (wipe/morte) nunca é negado: se a janela já tem >= 3 flashes, sai como fade e conta no N_flash.

const JANELA_US: int = 1_000_000
const LIMITE_FLASHES_S: int = 3
const LIMITE_IMPACTO_S: int = 1
const AREA_TELA_1080P: float = 1920.0 * 1080.0
const LIMIAR_AREA_FRAC: float = 0.11
const LIMIAR_AREA_UNID2: float = 228096.0 # 0.11 * 1920 * 1080

enum TipoEvento {
	IMPACTO_RECUSA,
	IMPACTO_CHEFE,
	PASSE_TELA,
	DISPAROS_TELEGRAFO,
}

class RegistroFlash extends RefCounted:
	var t_us: int
	var tipo: TipoEvento

	func _init(p_t_us: int, p_tipo: TipoEvento) -> void:
		t_us = p_t_us
		tipo = p_tipo


var _relogio_us: Callable
var _historico: Array[RegistroFlash] = []
var _area_acumulada_passo: float = 0.0
var _passo_acumulado: int = -1


func _init(relogio_monotonico_us: Callable = Callable()) -> void:
	_relogio_us = relogio_monotonico_us


func configurar_relogio(relogio_monotonico_us: Callable) -> void:
	_relogio_us = relogio_monotonico_us


func limpar() -> void:
	_historico.clear()
	_area_acumulada_passo = 0.0
	_passo_acumulado = -1


func agora_us() -> int:
	if _relogio_us.is_valid():
		return int(_relogio_us.call())
	return 0


func _podar(t_agora_us: int) -> void:
	var limite_inf: int = t_agora_us - JANELA_US
	while not _historico.is_empty() and _historico[0].t_us <= limite_inf:
		_historico.pop_front()


func n_flashes_na_janela(t_agora_us: int = -1) -> int:
	var t: int = agora_us() if t_agora_us < 0 else t_agora_us
	_podar(t)
	return _historico.size()


func n_impactos_na_janela(apenas_chefe: bool, t_agora_us: int = -1) -> int:
	var t: int = agora_us() if t_agora_us < 0 else t_agora_us
	_podar(t)
	var n: int = 0
	for r: RegistroFlash in _historico:
		if r.tipo == TipoEvento.IMPACTO_CHEFE:
			n += 1
		elif not apenas_chefe and r.tipo == TipoEvento.IMPACTO_RECUSA:
			n += 1
	return n


func pedir_impacto(eh_chefe: bool, t_agora_us: int = -1) -> bool:
	var t: int = agora_us() if t_agora_us < 0 else t_agora_us
	_podar(t)
	if _historico.size() >= LIMITE_FLASHES_S:
		return false
	var n_imp: int = n_impactos_na_janela(eh_chefe, t)
	if n_imp >= LIMITE_IMPACTO_S:
		return false
	var tipo := TipoEvento.IMPACTO_CHEFE if eh_chefe else TipoEvento.IMPACTO_RECUSA
	_historico.append(RegistroFlash.new(t, tipo))
	return true


## Passe de tela obrigatório nunca é negado (AC-PV-79).
## Devolve true se deve sair em modo FADE (janela já estava cheia com >= 3 flashes),
## ou false se pode sair como WIPE normal. Sempre registra 1 entrada no N_flash.
func registrar_passe_obrigatorio(t_agora_us: int = -1) -> bool:
	var t: int = agora_us() if t_agora_us < 0 else t_agora_us
	_podar(t)
	var janela_cheia: bool = _historico.size() >= LIMITE_FLASHES_S
	_historico.append(RegistroFlash.new(t, TipoEvento.PASSE_TELA))
	return janela_cheia


## Verifica se a área somada no passo vivo atinge o limiar de 228.096 px².
## Se não atingir, o flash do telégrafo acontece sem pedir vaga ao limitador (devolve true sem contar).
## Se atingir, pede vaga ao limitador (conta 1 no N_flash se aceito).
func pedir_flash_telegrafo(area_canvas2: float, zoom_camera: float = 1.0, t_agora_us: int = -1) -> bool:
	var t: int = agora_us() if t_agora_us < 0 else t_agora_us
	var area_tela: float = area_canvas2 * zoom_camera * zoom_camera
	if area_tela < LIMIAR_AREA_UNID2 - 1e-3:
		return true
	_podar(t)
	if _historico.size() >= LIMITE_FLASHES_S:
		return false
	_historico.append(RegistroFlash.new(t, TipoEvento.DISPAROS_TELEGRAFO))
	return true


## Resolve um lote de pedidos do mesmo passo na ordem estrita da F6:
## chefe > recusa > passes > telégrafos (AC-PV-38).
func resolver_lote_do_passo(tem_chefe: bool, tem_recusa: bool, tem_passe: bool, area_telegrafos: float, zoom_camera: float = 1.0, t_agora_us: int = -1) -> Dictionary:
	var t: int = agora_us() if t_agora_us < 0 else t_agora_us
	var res := {
		"chefe_aceito": false,
		"recusa_aceita": false,
		"passe_aceito": false,
		"passe_eh_fade": false,
		"telegrafo_aceito": true,
	}
	if tem_chefe:
		res["chefe_aceito"] = pedir_impacto(true, t)
	if tem_recusa:
		res["recusa_aceita"] = pedir_impacto(false, t)
	if tem_passe:
		res["passe_aceito"] = true
		res["passe_eh_fade"] = registrar_passe_obrigatorio(t)
	if area_telegrafos > 0.0:
		res["telegrafo_aceito"] = pedir_flash_telegrafo(area_telegrafos, zoom_camera, t)
	return res
