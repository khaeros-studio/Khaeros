class_name CatalogoDeRespostas
extends RefCounted
## Catálogo de respostas visuais, de câmera e de áudio por evento do passo (`R3`, `R10`, `R15`).
## Ver `design/gdd/feedback-de-combate.md` e `ADR-0011`.

class RespostaDeEvento extends RefCounted:
	var evento_id: StringName = &""
	var prioridade: int = 2 # 0 = P0 .. 4 = P4
	var relogio: StringName = &"vivo" # &"vivo" ou &"apres"
	var gancho_som: StringName = &""
	var preset_camera: StringName = &"" # &"", &"leve", &"pesado", &"chefe"
	var escala_camera: float = 0.0
	var modo_impacto: int = 0 # 0=normal, 1=recusa, 2=reduzido, 3=chefe
	var duracao_impacto_passos: int = 0
	var tipo_passe: StringName = &"" # &"", &"vinheta_dano", &"vinheta_recusa", &"morte"
	var flash_entidade_passos: int = 0
	var gera_estrela_acerto: bool = false
	var cor_vfx: Color = Color(0.949, 0.929, 0.894, 1.0) # Osso #F2EDE4

	func _init(
		p_id: StringName,
		p_prio: int,
		p_relogio: StringName = &"vivo",
		p_som: StringName = &"",
		p_cam: StringName = &"",
		p_esc_cam: float = 0.0,
		p_impacto: int = 0,
		p_dur_imp: int = 0,
		p_passe: StringName = &"",
		p_flash_ent: int = 0,
		p_estrela: bool = false,
		p_cor: Color = Color(0.949, 0.929, 0.894, 1.0)
	) -> void:
		evento_id = p_id
		prioridade = p_prio
		relogio = p_relogio
		gancho_som = p_som
		preset_camera = p_cam
		escala_camera = p_esc_cam
		modo_impacto = p_impacto
		duracao_impacto_passos = p_dur_imp
		tipo_passe = p_passe
		flash_entidade_passos = p_flash_ent
		gera_estrela_acerto = p_estrela
		cor_vfx = p_cor


const COR_OSSO: Color = Color(0.949, 0.929, 0.894, 1.0) # #F2EDE4
const COR_CARMIM: Color = Color(0.784, 0.216, 0.290, 1.0) # #C8374A
const COR_DOURADO: Color = Color(0.910, 0.722, 0.290, 1.0) # #E8B84A
const COR_MAGENTA: Color = Color(0.847, 0.220, 0.424, 1.0) # #D8386C
const COR_AMBAR: Color = Color(0.910, 0.604, 0.235, 1.0) # #E89A3C

var _tabela: Dictionary = {} # StringName -> RespostaDeEvento


func _init(tuning: FeedbackTuning = null) -> void:
	_construir_tabela_padrao(tuning if tuning != null else FeedbackTuning.new())


func obter(evento_id: StringName) -> RespostaDeEvento:
	return _tabela.get(evento_id, null)


func contem(evento_id: StringName) -> bool:
	return _tabela.has(evento_id)


func listar_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for k: StringName in _tabela.keys():
		ids.append(k)
	return ids


func validar(tuning: FeedbackTuning) -> Array[StringName]:
	var erros: Array[StringName] = []
	if tuning == null:
		erros.append(&"FB_TUNING_NULO")
		return erros
	if tuning.janela_soma_s < 0.15 or tuning.janela_soma_s > 0.45:
		erros.append(&"FB1_JANELA_SOMA_FORA_DA_FAIXA")
	if tuning.teto_numeros_simultaneos < 4 or tuning.teto_numeros_simultaneos > 8:
		erros.append(&"FB1_TETO_NUMEROS_FORA_DA_FAIXA")
	if tuning.teto_estrelas_passo < 3 or tuning.teto_estrelas_passo > 8:
		erros.append(&"FB1_TETO_ESTRELAS_FORA_DA_FAIXA")
	if not (
		tuning.sair_nivel_1 < tuning.entrar_nivel_1
		and tuning.entrar_nivel_1 <= tuning.sair_nivel_2 + 0.10
		and tuning.sair_nivel_2 < tuning.entrar_nivel_2
	):
		erros.append(&"FB3_HISTERESE_DEGRADACAO_INVALIDA")

	for k: StringName in _tabela.keys():
		var r: RespostaDeEvento = _tabela[k]
		if r.prioridade < 0 or r.prioridade > 4:
			erros.append(&"FB2_PRIORIDADE_INVALIDA")
		if r.relogio != &"vivo" and r.relogio != &"apres":
			erros.append(&"FB2_RELOGIO_INVALIDO")
		if r.preset_camera != &"" and r.preset_camera != &"leve" and r.preset_camera != &"pesado" and r.preset_camera != &"chefe":
			erros.append(&"FB2_PRESET_CAMERA_INVALIDO")
	return erros


func _registrar(r: RespostaDeEvento) -> void:
	_tabela[r.evento_id] = r


func _construir_tabela_padrao(tuning: FeedbackTuning) -> void:
	_tabela.clear()
	var flash_jg: int = tuning.flash_jogador_passos if tuning != null else 5
	var flash_in: int = tuning.flash_inimigo_passos if tuning != null else 4
	var imp_recusa: int = tuning.impact_recusa_passos if tuning != null else 2
	var imp_chefe: int = tuning.impact_chefe_passos if tuning != null else 3

	# P0: Eventos críticos de sobrevivência, morte e disparo de telégrafo
	_registrar(RespostaDeEvento.new(&"jogador_morreu", 0, &"apres", &"sfx_jogador_morte", &"chefe", 1.0, 0, 0, &"morte", flash_jg, false, COR_CARMIM))
	_registrar(RespostaDeEvento.new(&"recusou_morte", 0, &"apres", &"sfx_recusa_morte", &"chefe", 1.0, 1, imp_recusa, &"vinheta_recusa", flash_jg, true, COR_DOURADO))
	_registrar(RespostaDeEvento.new(&"jogador_atingido", 0, &"apres", &"sfx_jogador_atingido", &"pesado", 1.0, 0, 0, &"vinheta_dano", flash_jg, true, COR_CARMIM))
	_registrar(RespostaDeEvento.new(&"chefe_fase_2", 0, &"apres", &"sfx_chefe_fase", &"chefe", 1.0, 3, imp_chefe, &"", flash_in, true, COR_MAGENTA))
	_registrar(RespostaDeEvento.new(&"chefe_derrotado", 0, &"apres", &"sfx_chefe_derrotado", &"chefe", 1.0, 3, imp_chefe, &"", flash_in, true, COR_DOURADO))
	_registrar(RespostaDeEvento.new(&"telegrafo_disparou", 0, &"vivo", &"sfx_telegrafo_disparo", &"", 0.0, 0, 0, &"", 0, false, COR_OSSO))

	# P1: Golpes pesados, quebra de telégrafo, eventos de chefe e momentos-chave das Maldições (R15)
	_registrar(RespostaDeEvento.new(&"golpe_pesado", 1, &"vivo", &"sfx_golpe_pesado", &"pesado", 0.85, 2, 1, &"", flash_in, true, COR_DOURADO))
	_registrar(RespostaDeEvento.new(&"telegrafo_quebrado", 1, &"vivo", &"sfx_telegrafo_quebra", &"pesado", 0.8, 2, 1, &"", flash_in, true, COR_DOURADO))
	_registrar(RespostaDeEvento.new(&"inimigo_eliminado", 1, &"vivo", &"sfx_inimigo_morte", &"leve", 0.5, 0, 0, &"", flash_in, true, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"escudo_quebrado", 1, &"apres", &"sfx_escudo_quebra", &"pesado", 0.75, 0, 0, &"vinheta_dano", flash_jg, false, COR_OSSO))
	# R15 — 13 eventos das Maldições
	_registrar(RespostaDeEvento.new(&"maldicao_exaurida", 1, &"apres", &"sfx_maldicao_exaurida", &"", 0.0, 0, 0, &"", flash_in, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"maldicao_regenerada", 2, &"apres", &"sfx_maldicao_regenerada", &"", 0.0, 0, 0, &"", 2, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"troca_feita", 1, &"vivo", &"sfx_pacto_troca", &"", 0.0, 0, 0, &"", 2, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"troca_indisponivel", 2, &"apres", &"ui_negado", &"", 0.0, 0, 0, &"", 0, false, COR_AMBAR))
	_registrar(RespostaDeEvento.new(&"chamado_disparado", 1, &"vivo", &"sfx_chamado_inicio", &"", 0.0, 0, 0, &"", 2, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"chamado_pouso", 1, &"vivo", &"sfx_chamado_pouso", &"leve", 0.6, 0, 0, &"", flash_in, true, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"tecnica_combinada", 1, &"vivo", &"sfx_tecnica_combinada", &"leve", 0.6, 2, 1, &"", flash_in, true, COR_DOURADO))
	_registrar(RespostaDeEvento.new(&"virote_marcou", 2, &"vivo", &"sfx_virote_marca", &"", 0.0, 0, 0, &"", 2, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"virote_expirou", 3, &"vivo", &"", &"", 0.0, 0, 0, &"", 0, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"pacto_firmado", 1, &"apres", &"sfx_pacto_firmado", &"leve", 0.5, 0, 0, &"", 3, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"pacto_recusado", 2, &"apres", &"sfx_pacto_recusado", &"", 0.0, 0, 0, &"", 0, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"chefe_subjugado", 0, &"apres", &"sfx_chefe_subjugado", &"chefe", 0.9, 3, imp_chefe, &"", flash_in, true, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"chefe_exorcizado", 1, &"apres", &"sfx_chefe_exorcizado", &"pesado", 0.8, 0, 0, &"", flash_in, true, COR_DOURADO))

	# P2: Golpes leves, ataques da Maldição, esquiva, impacto em parede (R3 / R10)
	_registrar(RespostaDeEvento.new(&"golpe_leve", 2, &"vivo", &"sfx_golpe_leve", &"leve", 0.4, 0, 0, &"", flash_in, true, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"maldicao_atacou", 2, &"vivo", &"sfx_maldicao_ataque", &"", 0.0, 0, 0, &"", 0, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"maldicao_atingida", 2, &"vivo", &"sfx_maldicao_atingida", &"", 0.0, 0, 0, &"", 3, false, COR_AMBAR))
	_registrar(RespostaDeEvento.new(&"esquiva_executada", 2, &"vivo", &"sfx_esquiva", &"", 0.0, 0, 0, &"", 0, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"impacto_parede", 2, &"vivo", &"sfx_impacto_parede", &"leve", 0.45, 0, 0, &"", flash_in, true, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"explosao_inimigo", 2, &"vivo", &"sfx_explosao", &"leve", 0.5, 0, 0, &"", flash_in, true, COR_AMBAR))
	# R10 — Respostas mínimas de lacunas
	_registrar(RespostaDeEvento.new(&"fluxo_pronto", 2, &"apres", &"sfx_fluxo_pronto", &"", 0.0, 0, 0, &"", 0, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"sem_fluxo", 2, &"apres", &"ui_sem_fluxo", &"", 0.0, 0, 0, &"", 0, false, COR_AMBAR))
	_registrar(RespostaDeEvento.new(&"esquiva_sem_carga", 2, &"apres", &"ui_sem_esquiva", &"", 0.0, 0, 0, &"", 0, false, COR_AMBAR))
	_registrar(RespostaDeEvento.new(&"porta_destrancada", 2, &"apres", &"sfx_porta_destrancada", &"leve", 0.3, 0, 0, &"", 0, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"cura_recebida", 2, &"apres", &"sfx_cura", &"", 0.0, 0, 0, &"", 2, false, COR_OSSO))

	# P3: Ticks de status, coleta de fragmentos, aplicação de status
	_registrar(RespostaDeEvento.new(&"tick_status", 3, &"vivo", &"sfx_status_tick", &"", 0.0, 0, 0, &"", 0, false, COR_AMBAR))
	_registrar(RespostaDeEvento.new(&"status_aplicado", 3, &"vivo", &"sfx_status_aplicado", &"", 0.0, 0, 0, &"", 2, false, COR_AMBAR))
	_registrar(RespostaDeEvento.new(&"fragmento_coletado", 3, &"apres", &"sfx_fragmento", &"", 0.0, 0, 0, &"", 0, false, COR_DOURADO))

	# P4: Poeira de passo, partículas ambientes e estilhaços cosméticos
	_registrar(RespostaDeEvento.new(&"passo_poeira", 4, &"vivo", &"sfx_passo", &"", 0.0, 0, 0, &"", 0, false, COR_OSSO))
	_registrar(RespostaDeEvento.new(&"estilhaco_ambiente", 4, &"vivo", &"", &"", 0.0, 0, 0, &"", 0, false, COR_OSSO))
