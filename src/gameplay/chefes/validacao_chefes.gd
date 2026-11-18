class_name ValidacaoChefes
extends RegrasCh


func validar_completo(itens: Array[ItemDoCatalogo], catalogo: Catalogo = null) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	out.append_array(validar(itens))
	out.append_array(validar_segunda_passada(itens, catalogo))
	return out


static func validar_padroes_direto(
	chefe: EnemyDef,
	tuning: ChefesTuning,
	tem_eco_perdido: bool = true,
	vidas_armas: Array[int] = [100, 80],
	passos_invuln: int = 40,
	max_onda: int = 9
) -> Array[Diagnostico]:
	var itens: Array[ItemDoCatalogo] = []
	var ordem := 0
	if chefe != null:
		itens.append(ItemDoCatalogo.new(&"enemy", "res://content/enemies/%s.tres" % String(chefe.id), ordem, chefe))
		ordem += 1

	if tuning != null:
		itens.append(ItemDoCatalogo.new(&"tuning", "res://content/tuning/chefes_tuning.tres", ordem, tuning))
		ordem += 1

	var reg := RegionDef.new()
	reg.id = &"regiao_teste"
	reg.chefe = chefe.id if chefe != null else CatalogoChefes.ID_SOBERANO
	itens.append(ItemDoCatalogo.new(&"region", "res://content/regions/regiao_teste.tres", ordem, reg))
	ordem += 1

	if tem_eco_perdido:
		var eco := CatalogoChefes.criar_eco_perdido_padrao()
		itens.append(ItemDoCatalogo.new(&"enemy", "res://content/enemies/eco_perdido.tres", ordem, eco))
		ordem += 1

	var wr := WaveRules.new()
	wr.id = &"wave_rules"
	wr.max_inimigos_onda = max_onda
	itens.append(ItemDoCatalogo.new(&"wave_rules", "res://content/tuning/wave_rules.tres", ordem, wr))
	ordem += 1

	for idx in range(vidas_armas.size()):
		var w := WeaponDef.new()
		w.id = StringName("arma_%d" % idx)
		w.vida_max = vidas_armas[idx]
		itens.append(ItemDoCatalogo.new(&"weapon", "res://content/weapons/arma_%d.tres" % idx, ordem, w))
		ordem += 1

	var cbt := CombatTuning.new()
	cbt.id = &"combat_tuning"
	cbt.invuln_atingido_s = float(passos_invuln) / float(Unidades.TICK_RATE)
	itens.append(ItemDoCatalogo.new(&"tuning", "res://content/tuning/combat_tuning.tres", ordem, cbt))

	var val := ValidacaoChefes.new()
	return val.validar_completo(itens, null)
