class_name Selo
extends RefCounted
## Módulo de Selo e Fluxo (GDD `design/gdd/selo-e-fluxo.md` R1–R8, F1, F2, F6, F7;
## Stories 002–005, AC-SF-01 a AC-SF-31; ADR-0001, ADR-0002, ADR-0003, ADR-0009, ADR-0010).
##
## Gerencia:
## - o recurso `fluxo` (`0..fluxo_max`, começa cheio na run, passa entre câmaras);
## - a recarga do Selo (`recarga_s`, em passos vivos) e o plantio no item 6 (F1, F6);
## - a lista de Selos ativos em ordem de criação (dano silencioso `δ × M_selo` por passo,
##   marca `no_selo(id)` para lentidão da IA e gatilho `selo_abala` para o Abalo);
## - limpeza na troca de câmara (`ao_camara_nova()`) sem emitir `selo_fim` (R6).

const TOLERANCIA_FRONTEIRA_FLUXO: float = 1e-9


## Registro de um Selo ativo no chão (R3).
class SeloAtivo:
	extends RefCounted
	var player_id: int
	var centro: Vector2
	var raio_px: float
	var restante: int

	func _init(p_centro: Vector2, p_raio_px: float, p_restante: int, p_player_id: int = 0) -> void:
		player_id = p_player_id
		centro = p_centro
		raio_px = p_raio_px
		restante = p_restante


var _tuning: SealTuning
var _eventos: EventosDoPasso
var _portador: ConsultaDeAtributos
var _fluxo: float = 100.0
var _recarga: int = 0
var _recarga_passos: int = 30
var _duracao_passos: int = 200
var _regen_passo: float = 0.06
var _dano_passo: float = 0.12
var _selos_ativos: Array[SeloAtivo] = []
var _no_selo: Dictionary[int, bool] = {}
var _ultima_mira: Vector2 = Vector2.RIGHT
var _investida_no_item_5: bool = false
var _vida_atual_jogador: float = 100.0


func _init(tuning: SealTuning = null, eventos: EventosDoPasso = null,
		portador: ConsultaDeAtributos = null) -> void:
	_tuning = (tuning.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as SealTuning) if tuning != null else SealTuning.fabrica()
	_eventos = eventos if eventos != null else EventosDoPasso.new()
	_portador = portador
	_recarga_passos = Unidades.duracao_para_passos(_tuning.recarga_s)
	_duracao_passos = Unidades.duracao_para_passos(_tuning.duracao_s)
	_regen_passo = _tuning.regen_fluxo_s / float(Unidades.TICK_RATE)
	_dano_passo = _tuning.dano_selo_s / float(Unidades.TICK_RATE)
	_fluxo = _tuning.fluxo_max


## Configura ou substitui a consulta de atributos do portador do jogador.
func definir_portador(portador: ConsultaDeAtributos) -> void:
	_portador = portador


## Atualiza a Vida atual do jogador usada no `ContextoDeDano` para avaliar `dano_vida_baixa_pct` no M do Selo (AC-SF-17).
func definir_vida_jogador(vida_atual: float) -> void:
	_vida_atual_jogador = vida_atual


## Entrega do Combate no fim do item 5 (TR-selo-004, AC-SF-10): valor de "investida ativa"
## lido **antes** de o disparo do item 5 acontecer.
func receber_investida_do_item_5(ativa: bool) -> void:
	_investida_no_item_5 = ativa


## Valor atual do Fluxo (`0..fluxo_max`).
func fluxo() -> float:
	return _fluxo


## Define o Fluxo diretamente (para fixtures de teste FS).
func definir_fluxo_para_teste(valor: float) -> void:
	_fluxo = clampf(valor, 0.0, _tuning.fluxo_max)


## Teto do Fluxo (`fluxo_max`).
func fluxo_max() -> float:
	return _tuning.fluxo_max


## Recarga restante do Selo em passos vivos (`0` = pronto).
func recarga() -> int:
	return _recarga


## Define a recarga diretamente (para fixtures de teste FS).
func definir_recarga_para_teste(passos: int) -> void:
	_recarga = maxi(0, passos)


## Quantidade de Selos ativos no chão.
func quantidade_ativos() -> int:
	return _selos_ativos.size()


## Cópia da lista de Selos ativos na ordem de criação.
func selos_ativos() -> Array[SeloAtivo]:
	return _selos_ativos.duplicate()


## Consulta da IA (R4, AC-SF-22): verdadeiro se o inimigo `id` estava dentro de ao menos
## um Selo ativo na última execução do item 6.
func no_selo(inimigo_id: int) -> bool:
	return _no_selo.get(inimigo_id, false)


## Fator de lentidão do Selo (`0,5` no catálogo de fábrica; R4).
func fator_lentidao() -> float:
	return _tuning.fator_lentidao


## F7: velocidade efetiva de andar de um inimigo combinando `no_selo` e `cambaleando` (`f_c = 0,4`).
func velocidade_andar_efetiva(v_andar: float, inimigo_id: int, cambaleando: bool = false,
		fator_cambaleio: float = 0.4) -> float:
	var f_s: float = _tuning.fator_lentidao if no_selo(inimigo_id) else 1.0
	var f_c: float = fator_cambaleio if cambaleando else 1.0
	return v_andar * f_s * f_c


## F6: calcula o centro do Selo preso ao retângulo jogável encolhido de `margem_borda_px`.
func calcular_centro_preso(pos_jogador: Vector2, mira: Vector2, retangulo_jogavel: Rect2) -> Vector2:
	var dir: Vector2 = mira.normalized() if mira != Vector2.ZERO else _ultima_mira
	var bruto: Vector2 = pos_jogador + dir * _tuning.distancia_px
	var m: float = _tuning.margem_borda_px
	var x0: float = retangulo_jogavel.position.x + m
	var x1: float = retangulo_jogavel.position.x + retangulo_jogavel.size.x - m
	var y0: float = retangulo_jogavel.position.y + m
	var y1: float = retangulo_jogavel.position.y + retangulo_jogavel.size.y - m
	return Vector2(clampf(bruto.x, x0, x1), clampf(bruto.y, y0, y1))


## Credita `n` acertos de arma do item 5 (`φ₅ = min(F_max, φ + a × n₅)`; F1).
## Só `acerto_de_arma` verdadeiro gera Fluxo (Corte da esquiva, parede, explosão, reflexo,
## status, Selo e golpes de Maldição com `de_arma = false` não somam nada; R1, R1a).
func creditar_acertos_item_5(n_acertos: int, de_arma: bool = true) -> void:
	if not de_arma or n_acertos <= 0:
		return
	_fluxo = minf(_tuning.fluxo_max, _fluxo + _tuning.fluxo_por_acerto * float(n_acertos))


## Chamada direta do Combate no item 8 (projétil do jogador: Pulso ou Virote; ADR-0002, ADR-0010 §8,
## AC-SF-26, AC-SF-29): credita +`fluxo_por_acerto` depois que o item 6 já rodou, então
## só serve para plantar no passo seguinte.
func creditar_acerto_tardio(_player_id: int = 0, de_arma: bool = true) -> void:
	if not de_arma:
		return
	_fluxo = minf(_tuning.fluxo_max, _fluxo + _tuning.fluxo_por_acerto)


## Passo congelado (hitstop ou fora de `JOGO`, AC-SF-05, AC-SF-25): Selos, recarga e Fluxo ficam parados.
func passo_congelado() -> void:
	pass


## Aviso de câmara nova na metade do wipe (R6, AC-SF-06, AC-SF-23):
## apaga todos os Selos ativos e limpa as marcas `no_selo`, **sem** emitir `selo_fim`.
## O Fluxo e a recarga passam para a câmara nova como estão.
func ao_camara_nova() -> void:
	_selos_ativos.clear()
	_no_selo.clear()


## Nova run (R1, AC-SF-06): Fluxo volta a `fluxo_max` (100), recarga zera e Selos são limpos.
func nova_run() -> void:
	_fluxo = _tuning.fluxo_max
	_recarga = 0
	_selos_ativos.clear()
	_no_selo.clear()
	_investida_no_item_5 = false


## Item 6 do passo vivo (R1, R2, R3; F1, F2, F6):
## 1. Regenera Fluxo (`φ₆ = min(F_max, φ₅ + r)`) e desconta 1 da recarga se > 0;
## 2. Testa o plantio do Selo (buffer `quer_selo`, flag `toque_novo_selo`, `!em_esquiva`,
##    `!investida_ativa_no_item_5`, `recarga == 0`, `φ₆ >= custo_fluxo`);
## 3. Zera as marcas `no_selo` do passo anterior e aplica dano silencioso (`ferir_inimigo`
##    callback ou mutação de dicionário de inimigo) + marca `no_selo` + Abalo (`selo_abala`)
##    em cada inimigo atingível (facção inimigo, nunca Maldição; R3a);
## 4. Desconta 1 de `restante` em cada Selo ativo e emite [EvSeloFim] para os que chegaram a 0.
func passo_item_6(pos_jogador: Vector2, mira: Vector2, retangulo_jogavel: Rect2,
		buffer: BufferDeComandos = null, toque_novo_selo: bool = false,
		em_esquiva: bool = false, inimigos: Array = [],
		ferir_silencioso: Callable = Callable(), aplicar_abalo: Callable = Callable(),
		m_selo_override: float = -1.0, player_id: int = 0) -> void:
	if mira != Vector2.ZERO:
		_ultima_mira = mira.normalized()

	# 1. Regeneração do passo (φ₆) e queda de recarga
	_fluxo = minf(_tuning.fluxo_max, _fluxo + _regen_passo)
	if _recarga > 0:
		_recarga -= 1

	# 2. Plantar o Selo (R2)
	var quer_selo: bool = buffer != null and buffer.tem(Acoes.SELO)
	var tem_fluxo: bool = _fluxo >= _tuning.custo_fluxo - TOLERANCIA_FRONTEIRA_FLUXO
	if toque_novo_selo and not tem_fluxo:
		_eventos.emitir(EvSeloSemFluxo.new(player_id))

	if quer_selo and not em_esquiva and not _investida_no_item_5 and _recarga == 0 and tem_fluxo:
		buffer.consumir(Acoes.SELO)
		_fluxo = maxf(0.0, _fluxo - _tuning.custo_fluxo)
		_recarga = _recarga_passos
		var centro: Vector2 = calcular_centro_preso(pos_jogador, _ultima_mira, retangulo_jogavel)
		_selos_ativos.append(SeloAtivo.new(centro, _tuning.raio_px, _duracao_passos, player_id))
		_eventos.emitir(EvSelo.new(centro, _tuning.raio_px, _duracao_passos, player_id))

	# 3. Selos ativos ferem inimigos atingíveis e marcam no_selo (R3, R3a)
	_no_selo.clear()
	var m_atual: float = _calcular_m_selo(m_selo_override)
	var duracao_abalo_s: float = _obter_duracao_selo_abala()

	var sobreviventes: Array[SeloAtivo] = []
	for selo: SeloAtivo in _selos_ativos:
		for ini: Variant in inimigos:
			if not _inimigo_atingivel(ini):
				continue
			var pos_i: Vector2 = _inimigo_pos(ini)
			var r_i: float = _inimigo_raio(ini)
			if pos_i.distance_to(selo.centro) <= selo.raio_px + r_i + 1e-6:
				var id_i: int = _inimigo_id(ini)
				var dano: float = _dano_passo * m_atual
				if dano > 0.0:
					if ferir_silencioso.is_valid():
						ferir_silencioso.call(id_i, dano)
					else:
						_descontar_vida_inimigo(ini, dano)
				_no_selo[id_i] = true
				if duracao_abalo_s > 0.0 and aplicar_abalo.is_valid():
					aplicar_abalo.call(id_i, &"abalo", duracao_abalo_s)
		selo.restante -= 1
		if selo.restante <= 0:
			_eventos.emitir(EvSeloFim.new(selo.centro, selo.player_id))
		else:
			sobreviventes.append(selo)
	_selos_ativos = sobreviventes


func _calcular_m_selo(override_val: float) -> float:
	if override_val >= 0.0:
		return override_val
	if _portador == null:
		return 1.0
	# R3 / F2: `vida_abaixo` vale; `apos_esquiva` e `enesimo_acerto` NÃO valem para o Selo (AC-SF-17)
	var ctx := ContextoDeDano.new(_vida_atual_jogador, false)
	return _portador.multiplicador_de_dano(Modificador.Slot.SELO, ctx)


func _obter_duracao_selo_abala() -> float:
	if _portador == null:
		return 0.0
	var g: ResumoDeGatilho = _portador.gatilhos(&"selo_abala")
	if g == null or g.total <= 0.0:
		return 0.0
	return float(g.params.get(&"duracao_s", 0.5))


static func _inimigo_atingivel(ini: Variant) -> bool:
	if ini is Dictionary:
		var d: Dictionary = ini
		if d.get(&"faccao", &"inimigo") != &"inimigo":
			return false
		if bool(d.get(&"surgindo", false)):
			return false
		return float(d.get(&"vida", 0.0)) > 0.0
	if ini is Object:
		if ini.has_method("atingivel"):
			return bool(ini.call("atingivel"))
	return false


static func _inimigo_id(ini: Variant) -> int:
	if ini is Dictionary:
		return int((ini as Dictionary).get(&"id", 0))
	if ini is Object and "id" in ini:
		return int(ini.get("id"))
	return 0


static func _inimigo_pos(ini: Variant) -> Vector2:
	if ini is Dictionary:
		return (ini as Dictionary).get(&"pos", Vector2.ZERO)
	if ini is Object and "pos" in ini:
		return ini.get("pos")
	return Vector2.ZERO


static func _inimigo_raio(ini: Variant) -> float:
	if ini is Dictionary:
		return float((ini as Dictionary).get(&"raio", 24.0))
	if ini is Object and "raio" in ini:
		return float(ini.get("raio"))
	return 24.0


static func _descontar_vida_inimigo(ini: Variant, dano: float) -> void:
	if ini is Dictionary:
		var d: Dictionary = ini
		d[&"vida"] = float(d.get(&"vida", 0.0)) - dano
	elif ini is Object and "vida" in ini:
		ini.set("vida", float(ini.get("vida")) - dano)
