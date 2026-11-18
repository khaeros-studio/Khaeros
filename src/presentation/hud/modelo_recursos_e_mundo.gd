class_name ModeloRecursosEMundo
extends RefCounted
## Submodelo reativo de Fluxo (gota com marca de 40%), Esquiva (chevrons + tremor de 80 ms),
## Fragmentos (contador + agregação `+N` por 1.5 s), glifos dinâmicos (`rotulo_acao`),
## pool de 9 fios de vida de inimigos comuns, prompt de interação (`<= 111 px`) e
## Barra de Chefe no topo com divisor de 50% (Fase 2) (`story-003` e `story-004`).

const MARCA_FLUXO_HABILIDADE: float = 0.40
const TREMOR_ESQUIVA_DURACAO_S: float = 0.08
const TETO_FIOS_INIMIGOS: int = 9
const DISTANCIA_MAX_PORTA_PX: float = 111.0
const DIVISOR_FASE_2_CHEFE: float = 0.50

const ESTADO_FLUXO_PRONTO: StringName = &"HUD_FLUXO_PRONTO"
const ESTADO_FLUXO_SEM_FLUXO: StringName = &"HUD_FLUXO_INSUFICIENTE"
const ESTADO_FLUXO_EM_RECARGA: StringName = &"HUD_FLUXO_RECARGA"

var _tuning: HudTuning = HudTuning.new()

# Fluxo
var _fluxo_atual: float = 0.0
var _fluxo_max: float = 100.0
var _fluxo_custo: float = 40.0
var _fluxo_recarga_s: float = 0.0
var _pulso_sem_fluxo_s: float = 0.0

# Esquiva
var _esquiva_cargas: int = 2
var _esquiva_max: int = 2
var _esquiva_progresso_recarga: float = 0.0
var _tremor_esquiva_s: float = 0.0

# Fragmentos
var _saldo_fragmentos: int = 0
var _ganho_agregado: int = 0
var _janela_ganho_restante_s: float = 0.0
var _inicializado_saldo: bool = false

# Fios de vida de inimigos comuns (pool fixo de 9)
var _fios_ativos: Array[Dictionary] = []

# Porta interagível
var _porta_visivel: bool = false
var _porta_chave_prompt: StringName = &"HUD_INTERAGIR_PORTA"
var _porta_pos_mundo: Vector2 = Vector2.ZERO

# Barra de Chefe no topo
var _chefe_ativo: bool = false
var _chefe_chave_nome: StringName = &""
var _chefe_vida_atual: int = 0
var _chefe_vida_max: int = 1
var _chefe_fase: int = 1
var _chefe_subjugado: bool = false


func _init(tuning: HudTuning = null) -> void:
	if tuning != null:
		_tuning = tuning


func configurar(tuning: HudTuning) -> void:
	if tuning != null:
		_tuning = tuning


func sincronizar_recursos(fluxo_dict: Dictionary, esquiva_dict: Dictionary, novo_saldo: int) -> void:
	_fluxo_atual = clampf(float(fluxo_dict.get("atual", 0.0)), 0.0, float(fluxo_dict.get("max", 100.0)))
	_fluxo_max = maxf(1.0, float(fluxo_dict.get("max", 100.0)))
	_fluxo_custo = maxf(1.0, float(fluxo_dict.get("custo", _fluxo_max * MARCA_FLUXO_HABILIDADE)))
	_fluxo_recarga_s = maxf(0.0, float(fluxo_dict.get("recarga_s", 0.0)))

	_esquiva_max = maxi(1, int(esquiva_dict.get("max", 2)))
	_esquiva_cargas = clampi(int(esquiva_dict.get("cargas", _esquiva_max)), 0, _esquiva_max)
	_esquiva_progresso_recarga = clampf(float(esquiva_dict.get("progresso", 0.0)), 0.0, 1.0)

	if not _inicializado_saldo:
		_saldo_fragmentos = maxi(0, novo_saldo)
		_inicializado_saldo = true
	else:
		var delta_saldo: int = novo_saldo - _saldo_fragmentos
		_saldo_fragmentos = maxi(0, novo_saldo)
		if delta_saldo > 0:
			_ganho_agregado += delta_saldo
			_janela_ganho_restante_s = _tuning.janela_agregacao_fragmentos_s


func sincronizar_mundo(
	inimigos_feridos: Array[Dictionary],
	porta_dict: Dictionary,
	chefe_dict: Dictionary,
	pos_jogador: Vector2 = Vector2.ZERO
) -> void:
	# 1. Filtra inimigos comuns feridos (0 < vida < max, não chefe) e ordena por distância
	var candidatos: Array[Dictionary] = []
	for ini: Dictionary in inimigos_feridos:
		if bool(ini.get("eh_chefe", false)):
			continue
		var v_at: int = int(ini.get("vida_atual", 0))
		var v_mx: int = int(ini.get("vida_max", 1))
		if v_at <= 0 or v_at >= v_mx:
			continue
		candidatos.append(ini)

	var n: int = candidatos.size()
	for i: int in range(1, n):
		var chave: Dictionary = candidatos[i]
		var d_chave: float = Vector2(chave.get("pos", Vector2.ZERO)).distance_squared_to(pos_jogador)
		var j: int = i - 1
		while j >= 0:
			var d_j: float = Vector2(candidatos[j].get("pos", Vector2.ZERO)).distance_squared_to(pos_jogador)
			if d_chave >= d_j:
				break
			candidatos[j + 1] = candidatos[j]
			j -= 1
		candidatos[j + 1] = chave

	_fios_ativos.clear()
	var limite: int = mini(TETO_FIOS_INIMIGOS, candidatos.size())
	for k: int in range(limite):
		_fios_ativos.append(candidatos[k])

	# 2. Prompt de porta interagível (<= 111 px e destrancada)
	var destrancada: bool = bool(porta_dict.get("destrancada", false))
	var dist_porta: float = float(porta_dict.get("distancia_px", 9999.0))
	_porta_visivel = destrancada and dist_porta <= DISTANCIA_MAX_PORTA_PX
	_porta_chave_prompt = porta_dict.get("chave_prompt", &"HUD_INTERAGIR_PORTA")
	_porta_pos_mundo = porta_dict.get("pos", Vector2.ZERO)

	# 3. Barra de Chefe no topo
	_chefe_ativo = bool(chefe_dict.get("ativo", false)) and int(chefe_dict.get("vida_atual", 0)) > 0
	if _chefe_ativo:
		_chefe_chave_nome = chefe_dict.get("chave_nome", &"HUD_CHEFE_SOBERANO")
		_chefe_vida_max = maxi(1, int(chefe_dict.get("vida_max", 1000)))
		_chefe_vida_atual = clampi(int(chefe_dict.get("vida_atual", _chefe_vida_max)), 0, _chefe_vida_max)
		_chefe_fase = maxi(1, int(chefe_dict.get("fase", 1 if float(_chefe_vida_atual) > float(_chefe_vida_max) * DIVISOR_FASE_2_CHEFE else 2)))
		_chefe_subjugado = bool(chefe_dict.get("subjugado", false))


func notificar_sem_fluxo() -> void:
	_pulso_sem_fluxo_s = 0.20


func notificar_esquiva_sem_carga() -> void:
	_tremor_esquiva_s = TREMOR_ESQUIVA_DURACAO_S


func avancar(dt_ui: float) -> void:
	if dt_ui <= 0.0:
		return
	if _pulso_sem_fluxo_s > 0.0:
		_pulso_sem_fluxo_s = maxf(0.0, _pulso_sem_fluxo_s - dt_ui)
	if _tremor_esquiva_s > 0.0:
		_tremor_esquiva_s = maxf(0.0, _tremor_esquiva_s - dt_ui)
	if _janela_ganho_restante_s > 0.0:
		_janela_ganho_restante_s = maxf(0.0, _janela_ganho_restante_s - dt_ui)
		if _janela_ganho_restante_s <= 0.0:
			_ganho_agregado = 0


func fracao_fluxo() -> float:
	return clampf(_fluxo_atual / _fluxo_max, 0.0, 1.0)


func fracao_marca_fluxo() -> float:
	return MARCA_FLUXO_HABILIDADE


func estado_fluxo() -> StringName:
	if _fluxo_recarga_s > 0.001:
		return ESTADO_FLUXO_EM_RECARGA
	if _fluxo_atual + 0.001 >= _fluxo_custo:
		return ESTADO_FLUXO_PRONTO
	return ESTADO_FLUXO_SEM_FLUXO


func esquiva_cargas() -> int:
	return _esquiva_cargas


func esquiva_max() -> int:
	return _esquiva_max


func tremor_esquiva_ativo() -> bool:
	return _tremor_esquiva_s > 0.0


func saldo_fragmentos_formatado() -> String:
	return FormatoNumerico.formatar_inteiro(_saldo_fragmentos)


func ganho_agregado_formatado() -> String:
	if _ganho_agregado <= 0 or _janela_ganho_restante_s <= 0.0:
		return ""
	return "+%s" % FormatoNumerico.formatar_inteiro(_ganho_agregado)


func fios_inimigos_ativos() -> Array[Dictionary]:
	return _fios_ativos


func porta_interagivel_visivel() -> bool:
	return _porta_visivel


func chave_prompt_porta() -> StringName:
	return _porta_chave_prompt


func chefe_visivel() -> bool:
	return _chefe_ativo


func fracao_vida_chefe() -> float:
	if not _chefe_ativo:
		return 0.0
	return clampf(float(_chefe_vida_atual) / float(maxi(1, _chefe_vida_max)), 0.0, 1.0)


func fracao_divisor_fase_2_chefe() -> float:
	return DIVISOR_FASE_2_CHEFE


func fase_chefe() -> int:
	return _chefe_fase


func chave_nome_chefe() -> StringName:
	return _chefe_chave_nome


static func resolver_glifo_acao(acao: StringName, dispositivo: StringName) -> String:
	var rotulos: RotulosDeAcao = RotulosDeAcao.new()
	var info: Dictionary = rotulos.rotulo(MapaDeBinds.padrao(), acao, dispositivo)
	return String(info.get("glifo", ""))


static func visibilidade_por_estado_de_jogo(estado: int) -> Dictionary:
	# Regra de visibilidade por EstadoDeJogo (ADR-0012 §2):
	# - JOGO: tudo visível
	# - PAUSA: grupo do jogador visível sob véu; fios/porta ocultos
	# - BENCAO: grupo do jogador e saldo visíveis; chefe/fios/porta ocultos
	# - TRANSICAO / MORTE / MENU: HUD de combate oculto
	if estado == EstadoDeJogo.Valor.JOGO:
		return {"grupo_jogador": true, "saldo": true, "chefe": true, "mundo": true}
	if estado == EstadoDeJogo.Valor.BENCAO:
		return {"grupo_jogador": true, "saldo": true, "chefe": false, "mundo": false}
	if estado == EstadoDeJogo.Valor.PAUSA:
		return {"grupo_jogador": true, "saldo": true, "chefe": true, "mundo": false}
	return {"grupo_jogador": false, "saldo": false, "chefe": false, "mundo": false}
