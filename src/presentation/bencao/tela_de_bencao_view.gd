class_name TelaDeBencaoView
extends Control
## Vista e Controlador da Tela de Bênção e Carta (`story-005` a `story-008`):
## - Suporta os 3 modos canônicos:
##   1. `modo == &"bencao"`: escolha de Bênção (com botão de Trocar Ofertas `R` e integração com `Bencaos` real).
##   2. `modo == &"arma"`: escolha da Arma inicial entre `lamina`, `ressonancia` e `besta_do_vinculo`,
##      com foco inicial em `ultima_arma` (ou `lamina` se ausente/inválida).
##   3. `modo == &"maldicao"`: escolha da dupla de Maldições (`Campo` depois `Reserva`) entre as espécies
##      pactuadas no perfil (`0` espécies -> pula tela; `1` espécie -> confirmação de 1 carta; `>= 2` -> escolhe
##      Campo e Reserva com `Esc`/`voltar` em cascata desfazendo Campo ou voltando à escolha de Arma).
## - Emite `preco_revelado` e `tela_fechada`.

signal preco_revelado()
signal tela_fechada()
signal arma_escolhida(id_arma: StringName)
signal dupla_maldicoes_escolhida(id_campo: StringName, id_reserva: StringName)
signal voltar_para_escolha_de_arma()

const ARMAS_CANONICAS: Array[StringName] = [
	&"lamina",
	&"ressonancia",
	&"besta_do_vinculo",
]

var _tuning: TelaBencaoTuning = TelaBencaoTuning.new()
var _grupo: GrupoDeCartas = GrupoDeCartas.new()
var _fila_sons_ui: FilaDeSonsDeInterface = null
var _cartas_views: Array[CartaView] = []

# Estado específico dos modos arma e maldicao
var _especies_pactuadas: Array[StringName] = []
var _maldicao_campo_escolhida: StringName = &""
var _maldicao_reserva_escolhida: StringName = &""
var _etapa_dupla: int = 0 # 0 = escolhendo Campo, 1 = escolhendo Reserva


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_inicializar_views_se_necessario()


func grupo() -> GrupoDeCartas:
	return _grupo


func cartas_views() -> Array[CartaView]:
	_inicializar_views_se_necessario()
	return _cartas_views


func maldicao_campo_escolhida() -> StringName:
	return _maldicao_campo_escolhida


func maldicao_reserva_escolhida() -> StringName:
	return _maldicao_reserva_escolhida


func abrir_modo_bencao(
	cartas: Array[DadosDaCarta],
	trocas_restantes: int,
	porta: PortasDaBencao.PortaDaBencao = null,
	reduzir_movimento: bool = false
) -> void:
	_inicializar_views_se_necessario()
	_grupo.configurar(_tuning, porta, _fila_sons_ui, reduzir_movimento)
	_grupo.abrir(cartas, &"bencao", trocas_restantes, -1, _calcular_retangulos_cartas(cartas.size()))
	_sincronizar_views_com_grupo(reduzir_movimento)
	visible = true


## Abre o modo `arma` (`story-007`) com as 3 armas canônicas e foco inicial em `ultima_arma` (ou `lamina`).
func abrir_modo_arma(
	ultima_arma: StringName = &"lamina",
	pactos_disponiveis: int = 0,
	reduzir_movimento: bool = false
) -> void:
	_inicializar_views_se_necessario()
	var cartas: Array[DadosDaCarta] = []
	var foco_ini: int = 0
	for i: int in range(ARMAS_CANONICAS.size()):
		var id_a: StringName = ARMAS_CANONICAS[i]
		cartas.append(DadosDaCarta.criar_de_arma(id_a, pactos_disponiveis))
		if id_a == ultima_arma:
			foco_ini = i

	_grupo.configurar(_tuning, null, _fila_sons_ui, reduzir_movimento)
	_grupo.abrir(cartas, &"arma", 0, foco_ini, _calcular_retangulos_cartas(cartas.size()))
	_sincronizar_views_com_grupo(reduzir_movimento)
	visible = true


## Abre o modo `maldicao` (`story-008`) para escolha da dupla (Campo + Reserva).
## Se `especies_pactuadas` estiver vazia, fecha imediatamente e emite `dupla_maldicoes_escolhida(&"", &"")`.
func abrir_modo_maldicao(
	especies_pactuadas: Array[StringName],
	reduzir_movimento: bool = false
) -> bool:
	_inicializar_views_se_necessario()
	_especies_pactuadas = especies_pactuadas.duplicate()
	_maldicao_campo_escolhida = &""
	_maldicao_reserva_escolhida = &""
	_etapa_dupla = 0

	if _especies_pactuadas.is_empty():
		visible = false
		dupla_maldicoes_escolhida.emit(&"", &"")
		tela_fechada.emit()
		return false

	_montar_fileira_maldicao_etapa_atual(reduzir_movimento)
	visible = true
	return true


func avancar_tempo(dt_ui: float) -> void:
	var ev: Dictionary = _grupo.avancar(dt_ui)
	if bool(ev.get("preco_revelado", false)):
		preco_revelado.emit()
	if bool(ev.get("tela_fechada", false)):
		visible = false
		tela_fechada.emit()


func processar_comandos(cmd: ComandosDeTela, reduzir_movimento: bool = false) -> Dictionary:
	# No modo maldicao, Esc/voltar desfaz em cascata:
	# - se estava escolhendo Reserva (etapa 1), desfaz Campo e volta à etapa 0
	# - se estava escolhendo Campo (etapa 0), volta para a escolha de Arma
	if _grupo.modo() == &"maldicao" and cmd != null and cmd.voltar and _grupo.estado() == GrupoDeCartas.Estado.LIVRE:
		if _etapa_dupla == 1:
			_etapa_dupla = 0
			_maldicao_campo_escolhida = &""
			_montar_fileira_maldicao_etapa_atual(reduzir_movimento)
			return {"desfez_campo": true}
		visible = false
		voltar_para_escolha_de_arma.emit()
		return {"voltou_para_arma": true}

	var res: Dictionary = _grupo.processar_comandos(cmd)
	var idx_conf: int = int(res.get("confirmou_indice", -1))
	if idx_conf >= 0 and idx_conf < _grupo.cartas().size():
		var carta_escolhida: DadosDaCarta = _grupo.cartas()[idx_conf]
		if _grupo.modo() == &"arma":
			arma_escolhida.emit(carta_escolhida.id)
		elif _grupo.modo() == &"maldicao":
			if _etapa_dupla == 0:
				_maldicao_campo_escolhida = carta_escolhida.id
				if _especies_pactuadas.size() == 1:
					_maldicao_reserva_escolhida = &""
					dupla_maldicoes_escolhida.emit(_maldicao_campo_escolhida, &"")
				else:
					_etapa_dupla = 1
					_montar_fileira_maldicao_etapa_atual(reduzir_movimento)
			else:
				_maldicao_reserva_escolhida = carta_escolhida.id
				dupla_maldicoes_escolhida.emit(_maldicao_campo_escolhida, _maldicao_reserva_escolhida)

	_sincronizar_views_com_grupo(reduzir_movimento)
	return res


func _montar_fileira_maldicao_etapa_atual(reduzir_movimento: bool) -> void:
	var cartas: Array[DadosDaCarta] = []
	for id_esp: StringName in _especies_pactuadas:
		if _etapa_dupla == 1 and id_esp == _maldicao_campo_escolhida:
			continue
		if cartas.size() < 3:
			cartas.append(DadosDaCarta.criar_de_maldicao(id_esp))
	_grupo.configurar(_tuning, null, _fila_sons_ui, reduzir_movimento)
	_grupo.abrir(cartas, &"maldicao", 0, 0, _calcular_retangulos_cartas(cartas.size()))
	_sincronizar_views_com_grupo(reduzir_movimento)


func _sincronizar_views_com_grupo(reduzir_movimento: bool) -> void:
	_inicializar_views_se_necessario()
	var cartas_atuais: Array[DadosDaCarta] = _grupo.cartas()
	var rects: Array[Rect2] = _calcular_retangulos_cartas(cartas_atuais.size())
	var idx_foco: int = _grupo.foco().foco_atual()
	for i: int in range(_cartas_views.size()):
		var cv: CartaView = _cartas_views[i]
		if i < cartas_atuais.size():
			cv.visible = true
			cv.position = rects[i].position
			cv.size = rects[i].size
			cv.configurar_carta(cartas_atuais[i], _tuning, reduzir_movimento)
			cv.aplicar_estado_foco(i == idx_foco)
		else:
			cv.visible = false


func _calcular_retangulos_cartas(n: int) -> Array[Rect2]:
	var qtd: int = clampi(n, 1, 3)
	var larg_total: float = GrupoDeCartas.largura_fileira_100_px(qtd)
	var x0: float = (1920.0 - larg_total) * 0.5
	var y0: float = (1080.0 - DadosDaCarta.ALTURA_CARTA_100_PX) * 0.5
	var rects: Array[Rect2] = []
	for i: int in range(qtd):
		var x: float = x0 + float(i) * (DadosDaCarta.LARGURA_CARTA_100_PX + DadosDaCarta.ESPACAMENTO_CARTAS_100_PX)
		rects.append(Rect2(Vector2(x, y0), Vector2(DadosDaCarta.LARGURA_CARTA_100_PX, DadosDaCarta.ALTURA_CARTA_100_PX)))
	return rects


func _inicializar_views_se_necessario() -> void:
	if not _cartas_views.is_empty():
		return
	for i: int in range(3):
		var cv: CartaView = CartaView.new()
		cv.name = "CartaView_%d" % i
		cv.visible = false
		add_child(cv)
		_cartas_views.append(cv)
