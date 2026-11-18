class_name EspelhoDeFontes
extends RefCounted
## Propagação das fontes do jogador aos portadores das Maldições da dupla (GDD
## modificadores-e-atributos R14, F6; ADR-0009 Emenda; ADR-0017). Todo modificador do
## jogador cujo tipo de efeito está em [code]tipos_propagados_maldicao[/code] ganha um
## espelho [code]espelho:<fonte>[/code] com valor × [code]fator_propagacao_maldicao[/code],
## mesma operação e a duração restante da original. Nenhum gatilho propaga. Um por
## [code]player_id[/code]; sem RNG.
##
## Escreva no jogador por [method aplicar_fonte_do_jogador] /
## [method remover_fonte_do_jogador]; depois do [code]avancar[/code] do jogador, chame
## [method sincronizar] (retira espelhos cuja original expirou).
##
## Exemplo:
## [codeblock]
## var e := EspelhoDeFontes.new(portador_jogador, tuning)
## e.adicionar_maldicao(portador_baluarte)
## e.aplicar_fonte_do_jogador(preco_com_nome)
## [/codeblock]

const PREFIXO: String = "espelho:"

var _jogador: Portador
var _tuning: ModifiersTuning
var _maldicoes: Array[Portador] = []


func _init(jogador: Portador, tuning: ModifiersTuning) -> void:
	_jogador = jogador
	_tuning = tuning


## Id do espelho de [param id_fonte].
static func id_espelho(id_fonte: StringName) -> StringName:
	return StringName(PREFIXO + String(id_fonte))


## Fonte espelho de [param fonte] com [param duracao] (null se nada propaga; F6).
static func espelhar(fonte: FonteDeModificador, duracao: int, tuning: ModifiersTuning) -> FonteDeModificador:
	if tuning.fator_propagacao_maldicao <= 0.0:
		return null
	var mods: Array[Modificador] = []
	for m: Modificador in fonte.modificadores:
		if m.slots != 0:
			continue
		var tipo := TabelaDeEfeitos.tipo_do_modificador(m)
		if tipo == &"" or not tuning.tipos_propagados_maldicao.has(tipo):
			continue
		mods.append(Modificador.new(m.atributo, m.operacao, m.valor * tuning.fator_propagacao_maldicao,
				m.condicao, m.param, m.slots))
	if mods.is_empty():
		return null
	return FonteDeModificador.new(id_espelho(fonte.id), mods, [], duracao)


## Põe [param maldicao] na dupla e espelha nela as fontes ativas do jogador, com a
## duração restante (criação no começo da run ou no passo do pacto, R14/R24).
func adicionar_maldicao(maldicao: Portador) -> void:
	if _maldicoes.has(maldicao):
		return
	_maldicoes.append(maldicao)
	for id: StringName in _jogador.ids_de_fontes():
		_espelhar_em(maldicao, _jogador.fonte_ativa(id), _jogador.duracao_restante(id))


## Tira [param maldicao] da dupla (fim da run). Não destrói o portador.
func remover_maldicao(maldicao: Portador) -> void:
	_maldicoes.erase(maldicao)


## Aplica [param fonte] no jogador e o espelho (ou a retirada dele) em toda a dupla.
func aplicar_fonte_do_jogador(fonte: FonteDeModificador) -> void:
	_jogador.aplicar_fonte(fonte)
	for m: Portador in _maldicoes:
		_espelhar_em(m, fonte, _jogador.duracao_restante(fonte.id))


## Remove a fonte do jogador e o espelho em toda a dupla (idempotente).
func remover_fonte_do_jogador(id_fonte: StringName) -> void:
	_jogador.remover_fonte(id_fonte)
	for m: Portador in _maldicoes:
		m.remover_fonte(id_espelho(id_fonte))


## Retira dos portadores da dupla os espelhos cuja fonte original não está mais no jogador.
func sincronizar() -> void:
	for m: Portador in _maldicoes:
		for id: StringName in m.ids_de_fontes():
			var texto := String(id)
			if texto.begins_with(PREFIXO) and not _jogador.tem_fonte(StringName(texto.substr(PREFIXO.length()))):
				m.remover_fonte(id)


func _espelhar_em(maldicao: Portador, fonte: FonteDeModificador, duracao: int) -> void:
	var esp := espelhar(fonte, duracao, _tuning)
	if esp == null:
		maldicao.remover_fonte(id_espelho(fonte.id))
	else:
		maldicao.aplicar_fonte(esp)
