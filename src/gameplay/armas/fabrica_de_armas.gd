class_name FabricaDeArmas
extends RefCounted
## Fábrica e conversões das três armas do MVP (GDD armas-das-doutrinas.md R1, R2, R2b, R8;
## ADR-0004, ADR-0010).
##
## Entrega as instâncias de [WeaponDef] e [ArmasTuning] de fábrica em memória ou por
## cópia profunda ([code]duplicate_deep(Resource.DEEP_DUPLICATE_ALL)[/code]), além da
## tabela de nomes canônicos da R8 e das conversões do cânone (AC-AR-01 a AC-AR-05,
## AC-AR-41, AC-AR-42). Nenhum `if arma == ...` altera regra de combate: toda a diferença
## entre armas vive nos 7 campos do [WeaponDef] e nos [AttackDef].

const ID_LAMINA: StringName = &"lamina"
const ID_RESSONANCIA: StringName = &"ressonancia"
const ID_PACTOS: StringName = &"pactos"

## Os 7 campos exatos de conteúdo de um [WeaponDef] (R1, AC-AR-01; `id` e `obsoleto` vêm da base).
const CAMPOS_WEAPON_DEF: PackedStringArray = [
	"id", "doutrina", "chave_nome", "vida_max", "velocidade", "ataque", "especial"
]

## Nomes canônicos em pt-BR (NFC) exigidos pela R8 / V5 (AC-AR-33, AC-AR-34).
const NOMES_CANONICOS: Dictionary = {
	&"WEAPON_LAMINA_NAME": "Lâmina do Juramento",
	&"WEAPON_RESSONANCIA_NAME": "Foco Ressonante",
	&"WEAPON_GUARDIAO_NAME": "Escudo-Bastião",
	&"WEAPON_VEU_NAME": "Adagas do Véu",
	&"WEAPON_TRANSMUTACAO_NAME": "Cálice da Transmutação",
	&"WEAPON_PACTOS_NAME": "Besta do Vínculo",
	&"WEAPON_LAMINA_ATK": "Corte",
	&"WEAPON_LAMINA_ESP": "Investida",
	&"WEAPON_RESSONANCIA_ATK": "Pulso",
	&"WEAPON_RESSONANCIA_ESP": "Onda de Ressonância",
	&"WEAPON_GUARDIAO_ATK": "Golpe de Escudo",
	&"WEAPON_GUARDIAO_ESP": "Muralha",
	&"WEAPON_VEU_ATK": "Estocada",
	&"WEAPON_VEU_ESP": "Leque de Lâminas",
	&"WEAPON_TRANSMUTACAO_ATK": "Gota Corrosiva",
	&"WEAPON_TRANSMUTACAO_ESP": "Transmutar",
	&"WEAPON_PACTOS_ATK": "Virote",
	&"WEAPON_PACTOS_ESP": "Chamado do Pacto",
	&"TRAD_BLADE_CORTE_FANTASMA_NAME": "O Corte Fantasma",
}

## Descrições de uma linha `<chave_nome>_DESC` para as cartas da tela de escolha (R4).
const DESCRICOES_CANONICAS: Dictionary = {
	&"WEAPON_LAMINA_NAME_DESC": "Corpo a corpo de combo que quebra a preparação.",
	&"WEAPON_RESSONANCIA_NAME_DESC": "Distância e controle de área com menos Vida.",
	&"WEAPON_PACTOS_NAME_DESC": "Distância em dupla com a Maldição pactuada.",
	&"WEAPON_LAMINA_ATK_DESC": "Arco curto em 3 golpes; o 3º quebra o preparo.",
	&"WEAPON_LAMINA_ESP_DESC": "Avanço rápido invulnerável que atravessa a linha.",
	&"WEAPON_RESSONANCIA_ATK_DESC": "Projétil rápido e contínuo que empurra sem congelar.",
	&"WEAPON_RESSONANCIA_ESP_DESC": "Anel de área ao redor do Iniciado que afasta a multidão.",
	&"WEAPON_PACTOS_ATK_DESC": "Virote rápido que marca o alvo prioritário da Maldição.",
	&"WEAPON_PACTOS_ESP_DESC": "Ordena que a Maldição em campo salte, segure e atraia.",
}


## Cria a Lâmina do Juramento de fábrica (R2, AC-AR-02).
static func lamina() -> WeaponDef:
	var w := WeaponDef.new()
	w.id = ID_LAMINA
	w.doutrina = ID_LAMINA
	w.chave_nome = &"WEAPON_LAMINA_NAME"
	w.vida_max = 100
	w.velocidade = Unidades.velocidade_para_pxs(4.3 / 60.0) # 387.0 px/s

	var corte := AttackDef.new()
	corte.chave_nome = &"WEAPON_LAMINA_ATK"
	corte.forma = AtaqueConvertido.FORMA_ARCO
	corte.params = {
		&"alcance_px": Unidades.unidade_para_px(95.0), # 142.5
		&"meio_angulo_graus": Unidades.arredondar_casas(Unidades.arco_meio_angulo_graus(0.35), 2), # 69.51
	}
	corte.dano = 14.0
	corte.recarga_s = Unidades.ticks_para_segundos(16)
	corte.empurrao = Unidades.velocidade_para_pxs(5.0 / 60.0) # 450.0
	corte.multiplicadores_combo = PackedFloat64Array([1.0, 1.0, 1.8])
	w.ataque = corte

	var investida := AttackDef.new()
	investida.chave_nome = &"WEAPON_LAMINA_ESP"
	investida.forma = AtaqueConvertido.FORMA_AVANCO
	investida.params = {
		&"distancia_px": Unidades.unidade_para_px(220.0), # 330.0
		&"duracao_s": Unidades.ticks_para_segundos(10),
		&"raio_px": Unidades.unidade_para_px(46.0), # 69.0
	}
	investida.dano = 26.0
	investida.recarga_s = Unidades.ticks_para_segundos(70)
	investida.empurrao = Unidades.velocidade_para_pxs(12.0 / 60.0) # 1080.0
	w.especial = investida
	return w


## Cria o Foco Ressonante de fábrica (R2, AC-AR-03).
static func ressonancia() -> WeaponDef:
	var w := WeaponDef.new()
	w.id = ID_RESSONANCIA
	w.doutrina = ID_RESSONANCIA
	w.chave_nome = &"WEAPON_RESSONANCIA_NAME"
	w.vida_max = 80
	w.velocidade = Unidades.velocidade_para_pxs(4.2 / 60.0) # 378.0 px/s

	var pulso := AttackDef.new()
	pulso.chave_nome = &"WEAPON_RESSONANCIA_ATK"
	pulso.forma = AtaqueConvertido.FORMA_PROJETIL
	pulso.params = {
		&"velocidade_pxs": Unidades.velocidade_para_pxs(11.0 / 60.0), # 990.0
		&"raio_px": Unidades.unidade_para_px(10.0), # 15.0
		&"vida_s": Unidades.ticks_para_segundos(50),
	}
	pulso.leque = PackedFloat64Array([0.0])
	pulso.atravessa = false
	pulso.dano = 12.0
	pulso.recarga_s = Unidades.ticks_para_segundos(14)
	pulso.empurrao = Unidades.velocidade_para_pxs(6.0 / 60.0) # 540.0
	w.ataque = pulso

	var onda := AttackDef.new()
	onda.chave_nome = &"WEAPON_RESSONANCIA_ESP"
	onda.forma = AtaqueConvertido.FORMA_CIRCULO
	onda.params = {
		&"raio_px": Unidades.unidade_para_px(130.0), # 195.0
		&"deslocamento_px": 0.0,
	}
	onda.dano = 30.0
	onda.recarga_s = Unidades.ticks_para_segundos(90)
	onda.empurrao = Unidades.velocidade_para_pxs(14.0 / 60.0) # 1260.0
	w.especial = onda
	return w


## Cria a Besta do Vínculo de fábrica (R2b, AC-AR-41).
static func pactos() -> WeaponDef:
	var w := WeaponDef.new()
	w.id = ID_PACTOS
	w.doutrina = ID_PACTOS
	w.chave_nome = &"WEAPON_PACTOS_NAME"
	w.vida_max = 90
	w.velocidade = Unidades.velocidade_para_pxs(4.25 / 60.0) # 382.5 px/s

	var virote := AttackDef.new()
	virote.chave_nome = &"WEAPON_PACTOS_ATK"
	virote.forma = AtaqueConvertido.FORMA_PROJETIL
	virote.params = {
		&"velocidade_pxs": Unidades.velocidade_para_pxs(13.0 / 60.0), # 1170.0
		&"raio_px": Unidades.unidade_para_px(8.0), # 12.0
		&"vida_s": Unidades.ticks_para_segundos(45),
	}
	virote.leque = PackedFloat64Array([0.0])
	virote.atravessa = false
	virote.dano = 10.0
	virote.recarga_s = Unidades.ticks_para_segundos(15)
	virote.empurrao = Unidades.velocidade_para_pxs(4.0 / 60.0) # 360.0
	w.ataque = virote

	var chamado := AttackDef.new()
	chamado.chave_nome = &"WEAPON_PACTOS_ESP"
	chamado.forma = AtaqueConvertido.FORMA_CHAMADO
	chamado.dano = 17.0
	chamado.recarga_s = Unidades.ticks_para_segundos(120)
	chamado.empurrao = 0.0
	w.especial = chamado
	return w


## As 3 armas do MVP na ordem do catálogo: Lâmina, Ressonância, Besta do Vínculo.
static func armas_mvp() -> Array[WeaponDef]:
	return [lamina(), ressonancia(), pactos()]


## Devolve a arma de fábrica pelo [param id], ou null se desconhecida.
static func por_id(id: StringName) -> WeaponDef:
	match id:
		ID_LAMINA:
			return lamina()
		ID_RESSONANCIA:
			return ressonancia()
		ID_PACTOS:
			return pactos()
	return null


## [ArmasTuning] de fábrica (Tuning Knobs; `p_max` = 4 como alias do Limiar).
static func tuning(p_max_alias: int = 4) -> ArmasTuning:
	var t := ArmasTuning.new()
	t.id = &"armas_tuning"
	t.meta_paridade = 0.15
	t.margem_fragil = 2
	t.g_max_fragil = 3
	t.periodos_trava = 2
	t.f_esp_min = 0.15
	t.f_esp_max = 0.40
	t.vel_media_min = 360.0
	t.vel_media_max = 400.0
	t.p_max = p_max_alias
	return t


## [CombatTuning] padrão de fábrica (FP do Combate, usado pelas fórmulas e validações de armas).
static func combat_tuning_padrao() -> CombatTuning:
	var c := CombatTuning.new()
	c.id = &"combat_tuning"
	c.hitstop_leve_s = 3.0 / 60.0
	c.hitstop_pesado_s = 6.0 / 60.0
	c.hitstop_abate_s = 4.0 / 60.0
	c.hitstop_atingido_s = 5.0 / 60.0
	c.hitstop_abate_chefe_s = 36.0 / 60.0
	c.hitstop_recusa_s = 12.0 / 60.0
	c.janela_combo_s = 34.0 / 60.0
	c.fator_recuperacao_golpe = 0.5
	c.recuperacao_max_s = 12.0 / 60.0
	c.limiar_finalizador = 1.2
	c.empurrao_pesado = 900.0
	c.parede_vel_min = 630.0
	c.dano_parede = 6.0
	c.queda_empurrao = 0.78
	c.empurrao_zero = 4.5
	c.cambaleio_s = 8.0 / 60.0
	c.fator_cambaleio = 0.4
	c.quebrou_recuperacao_s = 24.0 / 60.0
	c.invuln_atingido_s = 40.0 / 60.0
	c.invuln_extra_investida_s = 2.0 / 60.0
	c.passo_apoio_px = 18.0
	c.raio_encostado_px = 27.0
	c.nascimento_projetil_px = 36.0
	c.giro_leque_graus = 7.0
	c.fator_obstaculo_projetil = 0.85
	c.passes_varredura = 8
	c.cura_recusa_frac = 0.4
	c.flash_acerto_s = 4.0 / 60.0
	c.extra_inversao_s = 2.0 / 60.0
	c.impact_chefe_s = 6.0 / 60.0
	return c


## Inimigos do Limiar do cânone (Eco, Anomalia Menor, Fenda Errante e Chefe) para F2–F4 e AV3–AV4.
static func inimigos_limiar() -> Dictionary[StringName, EnemyDef]:
	var eco := EnemyDef.new()
	eco.id = &"eco_perdido"
	eco.chave_nome = &"ENEMY_ECO_PERDIDO_NAME"
	eco.comportamento = &"corpo_a_corpo"
	eco.vida = 30.0
	eco.velocidade = 153.0
	eco.raio_px = 24.0
	eco.dano = 9.0
	eco.alcance_px = 45.0
	eco.preparo_s = 26.0 / 60.0
	eco.recarga_s = 1.0
	eco.custo_onda = 1

	var anomalia := EnemyDef.new()
	anomalia.id = &"anomalia_menor"
	anomalia.chave_nome = &"ENEMY_ANOMALIA_MENOR_NAME"
	anomalia.comportamento = &"distancia"
	anomalia.vida = 24.0
	anomalia.velocidade = 117.0
	anomalia.raio_px = 22.5
	anomalia.dano = 8.0
	anomalia.alcance_px = 420.0
	anomalia.preparo_s = 36.0 / 60.0
	anomalia.recarga_s = 1.2
	anomalia.velocidade_projetil = 414.0
	anomalia.custo_onda = 1

	var fenda := EnemyDef.new()
	fenda.id = &"fenda_errante"
	fenda.chave_nome = &"ENEMY_FENDA_ERRANTE_NAME"
	fenda.comportamento = &"arremetida"
	fenda.vida = 46.0
	fenda.velocidade = 126.0
	fenda.raio_px = 30.0
	fenda.dano = 13.0
	fenda.alcance_px = 240.0
	fenda.preparo_s = 42.0 / 60.0
	fenda.recarga_s = 1.5
	fenda.custo_onda = 2

	var chefe := EnemyDef.new()
	chefe.id = &"anomalia_maior"
	chefe.chave_nome = &"ENEMY_ANOMALIA_MAIOR_NAME"
	chefe.comportamento = &"chefe"
	chefe.vida = 700.0
	chefe.velocidade = 108.0
	chefe.raio_px = 63.0
	chefe.dano = 16.0
	chefe.alcance_px = 165.0
	chefe.preparo_s = 40.0 / 60.0
	chefe.recarga_s = 1.0
	chefe.custo_onda = 5

	return {
		&"eco_perdido": eco,
		&"anomalia_menor": anomalia,
		&"fenda_errante": fenda,
		&"anomalia_maior": chefe,
	}


## Recuperação derivada de um [AttackDef] (Combate F2; AC-AR-05, AC-AR-42):
## investida (`avanco`) = 0; demais formas (incluindo `chamado` no GDD de Armas R2b) =
## `min(passos(recuperacao_max_s), round_longe_zero(R × fator_recuperacao_golpe))`.
static func recuperacao_passos(a: AttackDef, ct: CombatTuning = null) -> int:
	if a == null or a.forma == AtaqueConvertido.FORMA_AVANCO:
		return 0
	var tuning_c: CombatTuning = ct if ct != null else combat_tuning_padrao()
	var r: int = Unidades.duracao_para_passos(a.recarga_s)
	var rec_max: int = Unidades.duracao_para_passos(tuning_c.recuperacao_max_s)
	return mini(rec_max, FormulasDeModificadores.arredondar_meio_longe_do_zero(float(r) * tuning_c.fator_recuperacao_golpe))


## Valida que [param w] possui os 7 campos obrigatórios preenchidos (AC-AR-01).
static func validar_esquema_weapon_def(w: WeaponDef) -> String:
	if w == null:
		return "WeaponDef nulo"
	if w.id == &"":
		return "id ausente"
	if w.doutrina == &"":
		return "doutrina ausente"
	if w.chave_nome == &"":
		return "chave_nome ausente"
	if w.vida_max <= 0:
		return "vida_max inválida"
	if w.velocidade <= 0.0:
		return "velocidade inválida"
	if w.ataque == null:
		return "ataque obrigatório ausente"
	if w.especial == null:
		return "especial obrigatório ausente"
	return ""
