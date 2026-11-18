class_name PontosDeVinculo
extends RefCounted
## Fórmulas F3 (pontos e níveis) e F4 (bônus de nível, ML5 e paridade de TTK)
## de Vínculo e pactos (GDD vinculo-e-pactos.md V17, V19, F3, F4; ADR-0009, ADR-0017).

const FONTE_VINCULO_PREFIXO: String = "vinculo:"


## Acumulador em memória dos pontos ganhos por uma espécie durante uma run (V17, F3).
class AcumuladorDaRun:
	extends RefCounted
	var especie_id: StringName
	var camaras_com_acerto: int = 0
	var abates: int = 0
	var tecnicas_com_acerto: int = 0
	var vitoria: int = 0
	var pontos_extras: int = 0
	var _acertou_na_camara_atual: bool = false

	func _init(p_id: StringName) -> void:
		especie_id = p_id

	func registrar_acerto_na_camara() -> void:
		_acertou_na_camara_atual = true

	func ao_limpar_camara_combate_ou_chefe() -> void:
		if _acertou_na_camara_atual:
			camaras_com_acerto += 1
		_acertou_na_camara_atual = false

	func iniciar_nova_camara() -> void:
		_acertou_na_camara_atual = false

	func registrar_abate() -> void:
		abates += 1

	func registrar_tecnica_com_acerto() -> void:
		tecnicas_com_acerto += 1

	func registrar_vitoria() -> void:
		vitoria = 1

	func somar_extra(pts: int) -> void:
		pontos_extras += maxi(0, pts)


## F3: Calcula o total de [code]pontos_run[/code] de uma espécie a partir do seu [param acum] e [param tuning].
static func calcular_pontos_run(acum: AcumuladorDaRun, tuning: VinculoTuning) -> int:
	if acum == null or tuning == null:
		return 0
	var p_cam: int = tuning.pts_camara * maxi(0, acum.camaras_com_acerto)
	var p_ab: int = tuning.pts_abate * mini(maxi(0, acum.abates), maxi(0, tuning.teto_abates_run))
	var p_tec: int = tuning.pts_tecnica * mini(maxi(0, acum.tecnicas_com_acerto), maxi(0, tuning.teto_tecnicas_run))
	var p_vit: int = tuning.pts_vitoria * (1 if acum.vitoria > 0 else 0)
	return p_cam + p_ab + p_tec + p_vit + maxi(0, acum.pontos_extras)


## F3: Soma [param pontos_run] a [param vinculo_pontos_atuais] respeitando [code]pontos_teto[/code] (9999).
static func somar_com_teto(vinculo_pontos_atuais: int, pontos_run: int, tuning: VinculoTuning) -> int:
	var teto: int = tuning.pontos_teto if (tuning != null and tuning.pontos_teto > 0) else 9999
	return mini(teto, maxi(0, vinculo_pontos_atuais) + maxi(0, pontos_run))


## F3: Deriva o nível (0 se não pactuada; 1..5 se pactuada) a partir de [param vinculo_pontos] e [code]limiares_nivel[/code].
static func calcular_nivel(pactuada: bool, vinculo_pontos: int, tuning: VinculoTuning = null) -> int:
	if not pactuada:
		return 0
	var limiares: PackedInt64Array = tuning.limiares_nivel if (tuning != null and not tuning.limiares_nivel.is_empty()) else PackedInt64Array([20, 50, 90, 140])
	var nivel: int = 1
	for limiar: int in limiares:
		if vinculo_pontos >= limiar:
			nivel += 1
	var n_max: int = tuning.nivel_max if (tuning != null and tuning.nivel_max > 0) else (1 + limiares.size())
	return mini(n_max, nivel)


## F4: Calcula os atributos e multiplicadores efetivos de uma espécie no [param nivel] no início da run (V19, AC-VP-20):
## - Nível >= 2: [code]vida_max_v = round(vida_max * (1 + bonus_vida))[/code] (+5% → Baluarte 135 -> 142);
## - Nível >= 3: [code]passos_exausta_v = passos(recuperacao_exausta_s * mult_recuperacao)[/code] (× 0,90 → 10s -> 540 passos);
## - Nível >= 4: [code]dano_basico_v = dano_basico * (1 + bonus_dano_basico)[/code] (+5% → Baluarte 12,6 -> 13,23);
## - Chamado, Efeitos de Saída e Entrada e recarga da troca permanecem iguais à base (F4 / AC-VP-20).
static func calcular_bonus_nivel(def: CurseDef, nivel: int, tuning: VinculoTuning,
		maldicoes_tuning: MaldicoesTuning = null) -> Dictionary[StringName, Variant]:
	var b_vida: float = tuning.bonus_vida if (tuning != null and nivel >= 2) else 0.0
	var m_recup: float = tuning.mult_recuperacao if (tuning != null and nivel >= 3) else 1.0
	var b_dano: float = tuning.bonus_dano_basico if (tuning != null and nivel >= 4) else 0.0

	var vida_base: float = def.vida_max if def != null else 110.0
	var dano_base: float = def.dano_basico if def != null else 9.0
	var recup_s: float = maldicoes_tuning.recuperacao_exausta_s if maldicoes_tuning != null else 10.0
	if def != null and def.id == &"soberano_do_limiar" and def.passivas.has(&"vinculo_inquebravel"):
		recup_s = 8.0

	var vida_max_v: int = Unidades.arredondar_meio_longe_do_zero(vida_base * (1.0 + b_vida))
	var passos_exausta_v: int = Unidades.duracao_para_passos(recup_s * m_recup)
	var dano_basico_v: float = dano_base * (1.0 + b_dano)
	var recarga_troca_s: float = maldicoes_tuning.recarga_troca_s if maldicoes_tuning != null else 4.0

	return {
		&"nivel": nivel,
		&"bonus_vida": b_vida,
		&"mult_recuperacao": m_recup,
		&"bonus_dano_basico": b_dano,
		&"vida_max": vida_max_v,
		&"passos_exausta": passos_exausta_v,
		&"dano_basico": dano_basico_v,
		&"dano_saida": 5.0,
		&"dano_entrada": 7.0 if (def != null and def.id == &"baluarte_de_cinza") else 6.0,
		&"recarga_troca_s": recarga_troca_s,
	}


## Cria a [FonteDeModificador] [code]vinculo:<especie_id>[/code] aplicada ao [Portador] da Maldição no início da run (ADR-0017 §12).
static func criar_fonte_vinculo(especie_id: StringName, nivel: int, tuning: VinculoTuning) -> FonteDeModificador:
	var mods: Array[Modificador] = []
	if nivel >= 2 and tuning != null and tuning.bonus_vida > 0.0:
		mods.append(Modificador.new(Atributos.VIDA_MAX, Modificador.Operacao.PERCENTUAL, tuning.bonus_vida))
	return FonteDeModificador.new(StringName(FONTE_VINCULO_PREFIXO + String(especie_id)), mods)
