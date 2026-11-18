class_name ModeloDoBlocoDoPacto
extends RefCounted
## Submodelo reativo do **Bloco do Pacto** (`R15–R19`, `design/gdd/hud.md`, `design/ux/hud.md`).
## - Visível apenas quando `doutrina == &"pactos"` e há ao menos 1 Maldição equipada.
## - Dimensões a 100%: `332×88 px` com reserva (`228×88 px` sem reserva), ancorado `12 px`
##   acima do topo do grupo do jogador.
## - Silhueta ativa `72×72` em osso (`#F2EDE4`) **sem magenta**, barra de vida fixa `132 px`
##   segmentada de 10 em 10.
## - Silhueta da reserva `56×56` com anel de regeneração na Exaustão (`1 - restante/total`),
##   setor de recarga de troca e estado do Chamado (`Pronto`, `Em recarga`, `Bloqueado`).
## - Reação a `troca_indisponivel`: sacode `4 px` por `0.15 s` (ou pulso de borda com `reduzir_movimento`).
## - Reação a `troca_feita`: permuta instantânea de slots com pulso de `0.10 s`.

const TAMANHO_COM_RESERVA_100: Vector2 = Vector2(332.0, 88.0)
const TAMANHO_SEM_RESERVA_100: Vector2 = Vector2(228.0, 88.0)
const OFFSET_ACIMA_GRUPO_JOGADOR_PX: float = 12.0
const TAMANHO_SILHUETA_ATIVA_100: Vector2 = Vector2(72.0, 72.0)
const TAMANHO_SILHUETA_RESERVA_100: Vector2 = Vector2(56.0, 56.0)
const LARGURA_BARRA_ATIVA_100_PX: float = 132.0

const COR_SILHUETA_OSSO: Color = Color(0.949, 0.929, 0.894, 1.0) # #F2EDE4 (zero magenta)
const COR_EXAUSTA_CINZA: Color = Color(0.450, 0.440, 0.430, 0.75)

const CHAMADO_PRONTO: StringName = &"HUD_CHAMADO_PRONTO"
const CHAMADO_RECARGA: StringName = &"HUD_CHAMADO_RECARGA"
const CHAMADO_BLOQUEADO: StringName = &"HUD_CHAMADO_BLOQUEADO"

var _visivel: bool = false
var _tem_reserva: bool = false

# Maldição ativa (em campo)
var _id_ativa: StringName = &""
var _vida_ativa_atual: int = 0
var _vida_ativa_max: int = 1
var _ativa_exaurida: bool = false
var _ativa_regeneracao_progresso: float = 0.0

# Maldição na reserva
var _id_reserva: StringName = &""
var _vida_reserva_atual: int = 0
var _vida_reserva_max: int = 1
var _reserva_exaurida: bool = false
var _reserva_regeneracao_progresso: float = 0.0

# Recarga de troca e Chamado
var _troca_recarga_restante_s: float = 0.0
var _troca_recarga_total_s: float = 1.0
var _chamado_recarga_restante_s: float = 0.0
var _chamado_recarga_total_s: float = 1.0
var _fluxo_suficiente_chamado: bool = true

# Animações de feedback em t_ui
var _sacudida_restante_s: float = 0.0
var _pulso_troca_restante_s: float = 0.0
var _reduzir_movimento: bool = false


func configurar_acessibilidade(reduzir_movimento: bool) -> void:
	_reduzir_movimento = reduzir_movimento


func sincronizar(pacto_dict: Dictionary) -> void:
	var doutrina: StringName = pacto_dict.get("doutrina", &"")
	var ativa_dict: Dictionary = pacto_dict.get("ativa", {})
	var reserva_dict: Dictionary = pacto_dict.get("reserva", {})

	_id_ativa = ativa_dict.get("id", &"")
	_visivel = (doutrina == &"pactos") and (_id_ativa != &"")
	if not _visivel:
		_tem_reserva = false
		return

	_vida_ativa_max = maxi(1, int(ativa_dict.get("vida_max", 60)))
	_vida_ativa_atual = clampi(int(ativa_dict.get("vida_atual", _vida_ativa_max)), 0, _vida_ativa_max)
	_ativa_exaurida = bool(ativa_dict.get("exaurida", _vida_ativa_atual <= 0))
	var reg_rest_a: float = maxf(0.0, float(ativa_dict.get("regeneracao_restante_s", 0.0)))
	var reg_tot_a: float = maxf(0.001, float(ativa_dict.get("regeneracao_total_s", 10.0)))
	_ativa_regeneracao_progresso = clampf(1.0 - (reg_rest_a / reg_tot_a), 0.0, 1.0) if _ativa_exaurida else 1.0

	_id_reserva = reserva_dict.get("id", &"")
	_tem_reserva = (_id_reserva != &"")
	if _tem_reserva:
		_vida_reserva_max = maxi(1, int(reserva_dict.get("vida_max", 60)))
		_vida_reserva_atual = clampi(int(reserva_dict.get("vida_atual", _vida_reserva_max)), 0, _vida_reserva_max)
		_reserva_exaurida = bool(reserva_dict.get("exaurida", _vida_reserva_atual <= 0))
		var reg_rest_r: float = maxf(0.0, float(reserva_dict.get("regeneracao_restante_s", 0.0)))
		var reg_tot_r: float = maxf(0.001, float(reserva_dict.get("regeneracao_total_s", 10.0)))
		_reserva_regeneracao_progresso = clampf(1.0 - (reg_rest_r / reg_tot_r), 0.0, 1.0) if _reserva_exaurida else 1.0

	_troca_recarga_restante_s = maxf(0.0, float(pacto_dict.get("troca_recarga_restante_s", 0.0)))
	_troca_recarga_total_s = maxf(0.001, float(pacto_dict.get("troca_recarga_total_s", 3.0)))
	_chamado_recarga_restante_s = maxf(0.0, float(pacto_dict.get("chamado_recarga_restante_s", 0.0)))
	_chamado_recarga_total_s = maxf(0.001, float(pacto_dict.get("chamado_recarga_total_s", 8.0)))
	_fluxo_suficiente_chamado = bool(pacto_dict.get("fluxo_suficiente_chamado", true))


func notificar_troca_feita() -> void:
	_pulso_troca_restante_s = 0.10


func notificar_troca_indisponivel() -> void:
	_sacudida_restante_s = 0.15


func avancar(dt_ui: float) -> void:
	if dt_ui <= 0.0:
		return
	if _sacudida_restante_s > 0.0:
		_sacudida_restante_s = maxf(0.0, _sacudida_restante_s - dt_ui)
	if _pulso_troca_restante_s > 0.0:
		_pulso_troca_restante_s = maxf(0.0, _pulso_troca_restante_s - dt_ui)


func visivel() -> bool:
	return _visivel


func tem_reserva() -> bool:
	return _tem_reserva


func tamanho_bloco_100() -> Vector2:
	return TAMANHO_COM_RESERVA_100 if _tem_reserva else TAMANHO_SEM_RESERVA_100


func id_ativa() -> StringName:
	return _id_ativa


func id_reserva() -> StringName:
	return _id_reserva


func fracao_vida_ativa() -> float:
	if not _visivel:
		return 0.0
	return clampf(float(_vida_ativa_atual) / float(maxi(1, _vida_ativa_max)), 0.0, 1.0)


func segmentos_barra_ativa() -> int:
	return maxi(1, int(ceili(float(_vida_ativa_max) / 10.0)))


func ativa_exaurida() -> bool:
	return _ativa_exaurida


func reserva_exaurida() -> bool:
	return _reserva_exaurida


func progresso_regeneracao_reserva() -> float:
	return _reserva_regeneracao_progresso


func progresso_recarga_troca() -> float:
	if _troca_recarga_restante_s <= 0.0:
		return 1.0
	return clampf(1.0 - (_troca_recarga_restante_s / _troca_recarga_total_s), 0.0, 1.0)


func estado_chamado() -> StringName:
	if not _tem_reserva or _reserva_exaurida or not _fluxo_suficiente_chamado:
		return CHAMADO_BLOQUEADO
	if _chamado_recarga_restante_s > 0.001:
		return CHAMADO_RECARGA
	return CHAMADO_PRONTO


func cor_silhueta_ativa() -> Color:
	return COR_EXAUSTA_CINZA if _ativa_exaurida else COR_SILHUETA_OSSO


func deslocamento_sacudida_px() -> float:
	if _sacudida_restante_s <= 0.0 or _reduzir_movimento:
		return 0.0
	return 4.0 * sin((_sacudida_restante_s / 0.15) * PI * 4.0)


func pulso_borda_indisponivel_ativo() -> bool:
	return _sacudida_restante_s > 0.0


func pulso_troca_ativo() -> bool:
	return _pulso_troca_restante_s > 0.0


static func caminho_retrato_maldicao(id_especie: StringName) -> String:
	if id_especie == &"":
		return ""
	return "res://assets/art/ui/maldicoes/%s_retrato.png" % String(id_especie)
