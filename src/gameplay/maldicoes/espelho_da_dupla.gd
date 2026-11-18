class_name EspelhoDaDupla
extends RefCounted
## Colaborador puro para propagação de bênçãos (`dano_todo_pct`, `velocidade_pct`) do portador do jogador
## para os portadores das Maldições da dupla (GDD maldicoes.md R24, Modificadores R14, F6; ADR-0017 §8).
## Nenhum gatilho propaga.

var _espelhos_por_jogador: Dictionary[int, EspelhoDeFontes] = {}


func configurar_jogador(player_id: int, portador_jogador: Portador, tuning: ModifiersTuning) -> EspelhoDeFontes:
	var t := ModuloDeMaldicoes._normalizar_mod_tuning(tuning)
	var esp := EspelhoDeFontes.new(portador_jogador, t)
	_espelhos_por_jogador[player_id] = esp
	return esp


func espelho_de(player_id: int) -> EspelhoDeFontes:
	return _espelhos_por_jogador.get(player_id, null)


func registrar_maldicao(player_id: int, portador_maldicao: Portador) -> void:
	var esp: EspelhoDeFontes = _espelhos_por_jogador.get(player_id, null)
	if esp != null and portador_maldicao != null:
		esp.adicionar_maldicao(portador_maldicao)


func fonte_aplicada(player_id: int, fonte: FonteDeModificador) -> void:
	var esp: EspelhoDeFontes = _espelhos_por_jogador.get(player_id, null)
	if esp != null and fonte != null:
		esp.aplicar_fonte_do_jogador(fonte)


func fonte_removida(player_id: int, id_fonte: StringName) -> void:
	var esp: EspelhoDeFontes = _espelhos_por_jogador.get(player_id, null)
	if esp != null:
		esp.remover_fonte_do_jogador(id_fonte)


func sincronizar(player_id: int) -> void:
	var esp: EspelhoDeFontes = _espelhos_por_jogador.get(player_id, null)
	if esp != null:
		esp.sincronizar()
