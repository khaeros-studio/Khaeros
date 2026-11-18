class_name EstadoVisual
extends RefCounted
## Lógica pura do Pipeline Visual (ADR-0011 §1, §2, §7, §8; GDD pipeline-visual.md).
## Guarda o modo de tela (Transição > Morte > Bênção > Impacto > Normal),
## o `LimitadorDeFlashes` (F6), o `PasseDeTela` (wipe/fade), a oclusão F9 com histerese,
## o `fator_profundidade` (F2), os tempos de corpo do jogador/inimigo (R6) e o dicionário de globais sujos.
## Não toca em `RenderingServer` nem na `SceneTree`.

enum ModoTela {
	NORMAL = 0,
	IMPACTO = 1,
	BENCAO = 2,
	MORTE = 3,
	TRANSICAO = 4,
}

enum ModoImpacto {
	NENHUM = 0,
	RECUSA = 1,
	CHEFE = 2,
	REDUZIDO = 3,
}

class CoresDaRegiao extends RefCounted:
	var cor_nevoa: Color = Color(0.20, 0.23, 0.29, 1.0)
	var cor_feixe: Color = Color(0.90, 0.87, 0.81, 1.0)
	var cor_fundo: Color = Color(0.051, 0.055, 0.078, 1.0)

	func _init(
		p_nevoa: Color = Color(0.20, 0.23, 0.29, 1.0),
		p_feixe: Color = Color(0.90, 0.87, 0.81, 1.0),
		p_fundo: Color = Color(0.051, 0.055, 0.078, 1.0)
	) -> void:
		cor_nevoa = p_nevoa
		cor_feixe = p_feixe
		cor_fundo = p_fundo


class PropOclusor extends RefCounted:
	var id: int
	var r_oc: Rect2
	var y_prop: float
	var cobre: bool = false
	var alfa: float = 1.0

	func _init(p_id: int, p_rect: Rect2, p_y_prop: float) -> void:
		id = p_id
		r_oc = p_rect
		y_prop = p_y_prop


var _tuning: VisualTuning
var _limitador: LimitadorDeFlashes
var _passe: PasseDeTela = PasseDeTela.new()
var _modo_tela: ModoTela = ModoTela.NORMAL
var _modo_impacto_bruto: ModoImpacto = ModoImpacto.NENHUM
var _passos_impacto_restantes: int = 0
var _acumulador_apres_impacto: float = 0.0
var _bencao_pedida: bool = false
var _bencao_ativa: bool = false
var _transicao_ativa: bool = false
var _morte_ativa: bool = false

var _reduzir_flashes: bool = false
var _reduzir_movimento: bool = false
var _contorno_telegrafo_alto: bool = false

var _profundidade_atual: int = -1
var _fator_profundidade: float = 1.0
var _lut_atual: Texture2D = null
var _cores_atuais: CoresDaRegiao = CoresDaRegiao.new()
var _lut_pendente: Texture2D = null
var _cores_pendentes: CoresDaRegiao = null
var _tem_regiao_pendente: bool = false

var _t_vivo: float = 0.0
var _t_apres: float = 0.0
var _escala_traco: float = 1.0
var _intensidade_vinheta: float = 0.0
var _aviso_vv16_emitido: bool = false

var _sujos: Dictionary = {}
var _oclusores: Dictionary = {} # id -> PropOclusor


func configurar(tuning: VisualTuning, relogio_monotonico_us: Callable = Callable()) -> void:
	_tuning = tuning
	_limitador = LimitadorDeFlashes.new(relogio_monotonico_us)
	_sujos.clear()
	_profundidade_atual = -1
	_fator_profundidade = 1.0
	if _tuning != null:
		_marcar_sujo(&"saturacao_bencao", _tuning.saturacao_bencao)
		_marcar_sujo(&"valor_bencao", _tuning.valor_bencao)
		_marcar_sujo(&"fator_profundidade", 1.0)
		_marcar_sujo(&"modo_impacto", 0)
		_marcar_sujo(&"modo_bencao", 0)
		_marcar_sujo(&"escala_traco", 1.0)


func limitador() -> LimitadorDeFlashes:
	return _limitador


func passe_atual() -> PasseDeTela:
	return _passe


func modo_tela() -> ModoTela:
	return _modo_tela


func modo_impacto_efetivo() -> int:
	if _modo_tela != ModoTela.IMPACTO:
		return ModoImpacto.NENHUM
	if _reduzir_flashes and _modo_impacto_bruto != ModoImpacto.NENHUM:
		return ModoImpacto.REDUZIDO
	return _modo_impacto_bruto


func modo_bencao_efetivo() -> bool:
	return _modo_tela == ModoTela.BENCAO


func configurar_acessibilidade(reduzir_flashes: bool, reduzir_movimento: bool, contorno_alto: bool = false) -> void:
	var rf_mudou := _reduzir_flashes != reduzir_flashes
	_reduzir_flashes = reduzir_flashes
	_reduzir_movimento = reduzir_movimento
	_contorno_telegrafo_alto = contorno_alto
	if rf_mudou and _modo_tela == ModoTela.IMPACTO:
		_marcar_sujo(&"modo_impacto", modo_impacto_efetivo())


func contorno_telegrafo_efetivo_px() -> float:
	if _tuning == null:
		return 6.0 if _contorno_telegrafo_alto else 4.0
	return _tuning.contorno_telegrafo_alto_px if _contorno_telegrafo_alto else _tuning.contorno_telegrafo_px


func pedir_impacto(modo: ModoImpacto, impact_passos: int) -> bool:
	if modo == ModoImpacto.NENHUM or impact_passos <= 0:
		return false
	# Impacto pedido durante Transição, Morte ou Bênção é descartado (AC-PV-35).
	if _transicao_ativa or _morte_ativa or _bencao_ativa or _bencao_pedida:
		return false
	var eh_chefe: bool = (modo == ModoImpacto.CHEFE)
	if not _limitador.pedir_impacto(eh_chefe):
		return false
	_modo_impacto_bruto = modo
	_passos_impacto_restantes = impact_passos
	_acumulador_apres_impacto = 0.0
	_atualizar_modo_tela()
	return true


func pedir_passe(tipo: StringName) -> PasseDeTela:
	var janela_cheia: bool = _limitador.registrar_passe_obrigatorio()
	var usar_fade: bool = janela_cheia or _reduzir_movimento
	var dur_wipe: float = _tuning.duracao_wipe_s if _tuning != null else 0.40
	var dur_fade: float = _tuning.duracao_fade_s if _tuning != null else 0.30
	var dur: float = dur_fade if usar_fade else dur_wipe
	_passe.iniciar(tipo, dur, usar_fade)
	if tipo == &"morte":
		_morte_ativa = true
		_cortar_impacto_ativo()
	else:
		_transicao_ativa = true
		_cortar_impacto_ativo()
	_atualizar_modo_tela()
	return _passe


func concluir_transicao() -> void:
	_transicao_ativa = false
	_atualizar_modo_tela()


func definir_morte(ativa: bool) -> void:
	_morte_ativa = ativa
	if ativa:
		_cortar_impacto_ativo()
	_atualizar_modo_tela()


func pedir_flash_telegrafo(area_canvas2: float, zoom_camera: float = 1.0) -> bool:
	return _limitador.pedir_flash_telegrafo(area_canvas2, zoom_camera)


func agendar_regiao(lut: Texture2D, cores: CoresDaRegiao) -> void:
	_lut_pendente = lut
	_cores_pendentes = cores
	_tem_regiao_pendente = true


## Chamado na última das 6 ações da troca de câmara (na metade do wipe, tela coberta).
func trocar_regiao(lut: Texture2D, cores: CoresDaRegiao) -> void:
	_lut_atual = lut
	if cores != null:
		_cores_atuais = cores
	_tem_regiao_pendente = false
	_lut_pendente = null
	_cores_pendentes = null
	_marcar_sujo(&"lut_regiao", _lut_atual)
	_marcar_sujo(&"cor_nevoa", _cores_atuais.cor_nevoa)
	_marcar_sujo(&"cor_feixe", _cores_atuais.cor_feixe)
	_marcar_sujo(&"cor_fundo", _cores_atuais.cor_fundo)


func definir_profundidade(p: int) -> void:
	if p == _profundidade_atual:
		return
	_profundidade_atual = p
	var passo: float = _tuning.passo_profundidade if _tuning != null else 0.03
	var piso: float = _tuning.piso_profundidade if _tuning != null else 0.85
	_fator_profundidade = VisualMath.fator_profundidade(p, passo, piso)
	_marcar_sujo(&"fator_profundidade", _fator_profundidade)


func fator_profundidade_atual() -> float:
	return _fator_profundidade


func definir_bencao(ligada: bool) -> void:
	if ligada:
		_bencao_pedida = true
		if _passos_impacto_restantes <= 0:
			_bencao_ativa = true
	else:
		_bencao_pedida = false
		_bencao_ativa = false
	_atualizar_modo_tela()


func atualizar_escala_traco(w_janela: int, h_janela: int, z_camera: float = 1.0) -> void:
	var nova := VisualMathSdf.escala_traco(w_janela, h_janela, z_camera)
	if not is_equal_approx(nova, _escala_traco):
		_escala_traco = nova
		_marcar_sujo(&"escala_traco", _escala_traco)


func escala_traco_atual() -> float:
	return _escala_traco


func definir_intensidade_vinheta(intensidade: float) -> void:
	var teto: float = _tuning.vinheta_opacidade_max if _tuning != null else 0.40
	_intensidade_vinheta = clampf(intensidade, 0.0, teto)


func intensidade_vinheta() -> float:
	return _intensidade_vinheta


func receber_relogios(t_vivo_in: float, t_apres_in: float) -> void:
	_t_vivo = t_vivo_in
	_t_apres = t_apres_in
	if (_t_vivo > 4096.0 or _t_apres > 4096.0) and not _aviso_vv16_emitido:
		_aviso_vv16_emitido = true
	if _t_vivo == 0.0 and _t_apres == 0.0:
		_aviso_vv16_emitido = false


func aviso_vv16_emitido() -> bool:
	return _aviso_vv16_emitido


func t_vivo() -> float:
	return _t_vivo


func t_apres() -> float:
	return _t_apres


## Avança o desconto do impact frame e do passe de tela por `dt_apres` (já limitado por `dt_max_apres`).
func avancar_apres(dt_apres: float, pausado: bool = false) -> void:
	if pausado:
		return
	var dt_max: float = _tuning.dt_max_apres if _tuning != null else 0.10
	var dt: float = minf(maxf(dt_apres, 0.0), dt_max)
	if _passe.ativo():
		var antes := _passe.progresso()
		_passe.avancar(dt)
		if antes < 0.5 and _passe.progresso() >= 0.5 and _tem_regiao_pendente:
			trocar_regiao(_lut_pendente, _cores_pendentes)
		if not _passe.ativo() and _transicao_ativa:
			_transicao_ativa = false
			_atualizar_modo_tela()

	if _passos_impacto_restantes > 0 and _modo_tela == ModoTela.IMPACTO:
		_acumulador_apres_impacto += dt
		var passo_s := 1.0 / 60.0
		while _acumulador_apres_impacto >= passo_s - 1e-7 and _passos_impacto_restantes > 0:
			_acumulador_apres_impacto -= passo_s
			_passos_impacto_restantes -= 1
		if _passos_impacto_restantes <= 0:
			_modo_impacto_bruto = ModoImpacto.NENHUM
			if _bencao_pedida:
				_bencao_ativa = true
			_atualizar_modo_tela()


func globais_sujos() -> Dictionary:
	var copia := _sujos.duplicate()
	_sujos.clear()
	return copia


# --- F9: Oclusão com histerese ------------------------------------------------

func registrar_oclusor(id: int, r_oc: Rect2, y_prop: float) -> void:
	_oclusores[id] = PropOclusor.new(id, r_oc, y_prop)


func remover_oclusor(id: int) -> void:
	_oclusores.erase(id)


func limpar_oclusores() -> void:
	_oclusores.clear()


static func _dentro_semiaberto(r: Rect2, p: Vector2) -> bool:
	return p.x >= r.position.x and p.x < r.end.x and p.y >= r.position.y and p.y < r.end.y


func atualizar_oclusao_passo(p_pe: Vector2, p_corpo: Vector2, y_jogador: float, pausado: bool = false) -> void:
	if pausado:
		return
	var margem: float = _tuning.margem_histerese_oclusao_px if _tuning != null else 8.0
	var op_alvo: float = _tuning.opacidade_oclusao if _tuning != null else 0.40
	var dur_s: float = _tuning.duracao_transicao_oclusao_s if _tuning != null else 0.10
	var n_oc: int = maxi(1, int(round(dur_s * 60.0)))
	var passo_alfa: float = (1.0 - op_alvo) / float(n_oc)

	for id: int in _oclusores:
		var oc: PropOclusor = _oclusores[id]
		var entra := (_dentro_semiaberto(oc.r_oc, p_pe) or _dentro_semiaberto(oc.r_oc, p_corpo)) and (oc.y_prop > y_jogador)
		var r_exp := oc.r_oc.grow(margem)
		var sai := (not (_dentro_semiaberto(r_exp, p_pe) or _dentro_semiaberto(r_exp, p_corpo))) or (oc.y_prop <= y_jogador)
		if oc.cobre:
			oc.cobre = not sai
		else:
			oc.cobre = entra
		var alvo := op_alvo if oc.cobre else 1.0
		oc.alfa = move_toward(oc.alfa, alvo, passo_alfa)


func alfa_oclusor(id: int) -> float:
	if not _oclusores.has(id):
		return 1.0
	return (_oclusores[id] as PropOclusor).alfa


func oclusor_cobre(id: int) -> bool:
	if not _oclusores.has(id):
		return false
	return (_oclusores[id] as PropOclusor).cobre


# --- Interno ------------------------------------------------------------------

func _cortar_impacto_ativo() -> void:
	_passos_impacto_restantes = 0
	_modo_impacto_bruto = ModoImpacto.NENHUM


func _atualizar_modo_tela() -> void:
	var novo := ModoTela.NORMAL
	if _transicao_ativa:
		novo = ModoTela.TRANSICAO
	elif _morte_ativa:
		novo = ModoTela.MORTE
	elif _bencao_ativa:
		novo = ModoTela.BENCAO
	elif _passos_impacto_restantes > 0 and _modo_impacto_bruto != ModoImpacto.NENHUM:
		novo = ModoTela.IMPACTO

	var imp_antes := int(_sujos.get(&"modo_impacto", -999))
	var ben_antes := int(_sujos.get(&"modo_bencao", -999))
	_modo_tela = novo
	var imp_novo := modo_impacto_efetivo()
	var ben_novo := 1 if modo_bencao_efetivo() else 0
	if imp_novo != imp_antes:
		_marcar_sujo(&"modo_impacto", imp_novo)
	if ben_novo != ben_antes:
		_marcar_sujo(&"modo_bencao", ben_novo)


func _marcar_sujo(nome: StringName, valor: Variant) -> void:
	_sujos[nome] = valor
