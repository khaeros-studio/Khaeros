class_name ValidadorCombatTuning
extends RefCounted
## Validação das faixas do [CombatTuning] (AC-03) e das regras CV1–CV22 (GDD combate-nucleo.md
## §Validação do CombatTuning e dos AttackDef, AC-60..AC-65; ADR-0004, ADR-0010).
##
## Uma entrada por regra e por objeto; o erro vence o aviso da mesma regra; CV1 é uma entrada
## só com todas as causas; CV3 é avaliado mesmo numa lista de combo recusada pelo CV4.
##
## Exemplo:
## [codeblock]
## var diags := ValidadorCombatTuning.validar(tuning, ataques, especial_formas)
## [/codeblock]


## Descritor de um AttackDef para validação (com nome/id e se é slot Ataque ou Especial).
class EntradaAtaque:
	extends RefCounted
	var id: StringName
	var def: AttackDef
	var eh_ataque: bool
	## Lista crua de combo (permite testar lista vazia explícita vs sem combo no AC-61).
	var tem_combo_declarado: bool

	func _init(p_id: StringName, p_def: AttackDef, p_eh_ataque: bool = true,
			p_tem_combo_declarado: bool = false) -> void:
		id = p_id
		def = p_def
		eh_ataque = p_eh_ataque
		tem_combo_declarado = p_tem_combo_declarado or not p_def.multiplicadores_combo.is_empty()


## Contexto cruzado (inimigos, câmaras, movimento, modificadores) para CV6, CV7, CV12, CV14, CV16–CV20.
class ContextoCruzado:
	extends RefCounted
	var empurrao_corte_esquiva: float = 360.0
	var fator_empurrao_chefe: float = 0.12
	var r_min: float = 22.5
	var r_obs_min: float = 42.0
	var raio_jogador_px: float = 27.0
	## Lista de [vida: float, preparo_passos: int] dos inimigos comuns para CV18.
	var inimigos_comuns: Array = [[30.0, 8]]


## Valida apenas as faixas declarativas do [param t] (AC-03).
static func validar_faixas(t: CombatTuning) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var esq := t.esquema()
	for r in esq.regras():
		if r.nome == &"id" or r.nome == &"obsoleto":
			continue
		var v_var: Variant = t.get(r.nome)
		var v := float(v_var)
		var msg := V2Faixas.verificar_valor(r, v)
		if msg != "":
			out.append(Diagnostico.novo(&"FAIXA", String(r.nome), v_var,
				"CombatTuning: %s %s" % [r.nome, msg], Diagnostico.Nivel.ERRO))
	return out


## Verifica se um valor bruto para [param campo] é válido na faixa de [param t] (inclui checagem de inteiro em passes_varredura).
static func campo_em_faixa(t: CombatTuning, campo: StringName, valor: Variant) -> bool:
	if campo == &"passes_varredura" and typeof(valor) == TYPE_FLOAT:
		var vf := float(valor)
		if vf != floorf(vf):
			return false
	var copia := t.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as CombatTuning
	copia.set(campo, valor)
	for d in validar_faixas(copia):
		if d.campo == String(campo):
			return false
	return true


## Executa faixas + CV1–CV22 sobre [param t], [param ataques] e [param ctx].
static func validar_tudo(
		t: CombatTuning,
		ataques: Array[EntradaAtaque] = [],
		ctx: ContextoCruzado = null) -> Array[Diagnostico]:
	var c := ctx if ctx != null else ContextoCruzado.new()
	var out: Array[Diagnostico] = validar_faixas(t)
	var p := ParametrosDoCombate.de(t)

	# CV1 (aviso): ordem leve <= abate <= pesado <= abate_chefe, leve <= atingido <= abate_chefe, atingido <= recusa <= abate_chefe
	var causas_cv1: PackedStringArray = PackedStringArray()
	if p.hitstop_leve > p.hitstop_abate:
		causas_cv1.append("leve > abate")
	if p.hitstop_abate > p.hitstop_pesado:
		causas_cv1.append("abate > pesado")
	if p.hitstop_pesado > p.hitstop_abate_chefe:
		causas_cv1.append("pesado > abate_chefe")
	if p.hitstop_leve > p.hitstop_atingido:
		causas_cv1.append("leve > atingido")
	if p.hitstop_atingido > p.hitstop_abate_chefe:
		causas_cv1.append("atingido > abate_chefe")
	if p.hitstop_recusa < p.hitstop_atingido:
		causas_cv1.append("recusa < atingido")
	if p.hitstop_recusa > p.hitstop_abate_chefe:
		causas_cv1.append("recusa > abate_chefe")
	if not causas_cv1.is_empty():
		out.append(Diagnostico.novo(&"CV1", "hitstop", null,
			"CombatTuning: hierarquia de hitstop violada (%s)" % "; ".join(causas_cv1),
			Diagnostico.Nivel.AVISO))

	# CV2 (aviso): f_cong > 0,33 em alguma arma com combo sustentado
	var disparou_cv2 := false
	for ea in ataques:
		var a := ea.def
		if not ea.tem_combo_declarado or a.multiplicadores_combo.is_empty():
			continue
		var r_a := Unidades.duracao_para_passos(a.recarga_s)
		var n_c := a.multiplicadores_combo.size()
		var soma_h := 0
		for mult: float in a.multiplicadores_combo:
			var fin := mult > t.limiar_finalizador
			var emp := maxf(a.empurrao * mult, t.empurrao_pesado) if fin else a.empurrao
			var pes := fin or not ea.eh_ataque or emp >= t.empurrao_pesado
			if a.forma == &"arco" or a.forma == &"circulo":
				soma_h += p.hitstop_pesado if pes else p.hitstop_leve
			elif a.forma == &"avanco":
				soma_h += p.hitstop_pesado
		var denom := float(n_c * r_a + soma_h)
		if denom > 0.0 and (float(soma_h) / denom) > 0.33:
			disparou_cv2 = true
			break
	if disparou_cv2:
		out.append(Diagnostico.novo(&"CV2", "hitstop", null,
			"CombatTuning: f_cong > 0,33 em combo sustentado", Diagnostico.Nivel.AVISO))

	# CV3 (erro / aviso) e CV4 (erro) e CV5 (erro)
	if t.limiar_finalizador < 1.0:
		out.append(Diagnostico.novo(&"CV3", "limiar_finalizador", t.limiar_finalizador,
			"CombatTuning: limiar_finalizador < 1,0", Diagnostico.Nivel.ERRO))
	for ea in ataques:
		var a := ea.def
		if not ea.tem_combo_declarado:
			continue
		var combo := a.multiplicadores_combo
		var cv4_erro := combo.is_empty()
		var qtd_fin := 0
		for m: float in combo:
			if m <= 0.0:
				cv4_erro = true
			if m > t.limiar_finalizador:
				qtd_fin += 1
		# CV3 é avaliado mesmo numa lista recusada pelo CV4 (exceto se já houve CV3 erro no tuning para não duplicar? Não, CV3 erro é no tuning, CV3 aviso é no AttackDef)
		if t.limiar_finalizador >= 1.0 and qtd_fin != 1:
			out.append(Diagnostico.novo(&"CV3", String(ea.id), qtd_fin,
				"AttackDef %s: combo com %d entradas > limiar_finalizador" % [ea.id, qtd_fin],
				Diagnostico.Nivel.AVISO))
		if cv4_erro:
			out.append(Diagnostico.novo(&"CV4", String(ea.id), combo,
				"AttackDef %s: combo vazio ou com entrada <= 0" % ea.id,
				Diagnostico.Nivel.ERRO))
		var r_a := Unidades.duracao_para_passos(a.recarga_s)
		if r_a >= p.janela_combo:
			out.append(Diagnostico.novo(&"CV5", String(ea.id), r_a,
				"AttackDef %s: R (%d) >= J (%d)" % [ea.id, r_a, p.janela_combo],
				Diagnostico.Nivel.ERRO))

	# CV6 (erro / aviso): empurrao_zero <= 0 ou queda_empurrao fora de (0, 1); aviso: empurrao_zero >= menor empurrão efetivo
	if t.empurrao_zero <= 0.0 or t.queda_empurrao <= 0.0 or t.queda_empurrao >= 1.0:
		out.append(Diagnostico.novo(&"CV6", "empurrao_zero", t.empurrao_zero,
			"CombatTuning: empurrao_zero <= 0 ou queda_empurrao fora de (0, 1)",
			Diagnostico.Nivel.ERRO))
	else:
		var menor_emp := INF
		if c.empurrao_corte_esquiva > 0.0:
			menor_emp = minf(menor_emp, c.empurrao_corte_esquiva)
		for ea in ataques:
			if ea.def.empurrao > 0.0:
				menor_emp = minf(menor_emp, ea.def.empurrao)
		if is_finite(menor_emp):
			var menor_efetivo := menor_emp * c.fator_empurrao_chefe
			if t.empurrao_zero >= menor_efetivo:
				out.append(Diagnostico.novo(&"CV6", "empurrao_zero", t.empurrao_zero,
					"CombatTuning: empurrao_zero >= menor empurrão efetivo (%.3f)" % menor_efetivo,
					Diagnostico.Nivel.AVISO))

	# CV7 (erro / aviso): erro: parede_vel_min <= empurrao_zero; aviso: <= maior empurrão leve ou > empurrao_pesado
	if t.parede_vel_min <= t.empurrao_zero:
		out.append(Diagnostico.novo(&"CV7", "parede_vel_min", t.parede_vel_min,
			"CombatTuning: parede_vel_min <= empurrao_zero", Diagnostico.Nivel.ERRO))
	else:
		var maior_leve := c.empurrao_corte_esquiva
		for ea in ataques:
			if ea.eh_ataque:
				maior_leve = maxf(maior_leve, ea.def.empurrao)
		if t.parede_vel_min <= maior_leve or t.parede_vel_min > t.empurrao_pesado:
			out.append(Diagnostico.novo(&"CV7", "parede_vel_min", t.parede_vel_min,
				"CombatTuning: parede_vel_min <= maior empurrão leve ou > empurrao_pesado",
				Diagnostico.Nivel.AVISO))

	# CV8 (aviso): algum Ataque tem empurrao >= empurrao_pesado
	for ea in ataques:
		if ea.eh_ataque and ea.def.empurrao >= t.empurrao_pesado:
			out.append(Diagnostico.novo(&"CV8", String(ea.id), ea.def.empurrao,
				"AttackDef %s: Ataque com empurrão >= empurrao_pesado" % ea.id,
				Diagnostico.Nivel.AVISO))
			break

	# CV9 (erro): fator_recuperacao_golpe fora de [0, 1]
	if t.fator_recuperacao_golpe < 0.0 or t.fator_recuperacao_golpe > 1.0:
		out.append(Diagnostico.novo(&"CV9", "fator_recuperacao_golpe", t.fator_recuperacao_golpe,
			"CombatTuning: fator_recuperacao_golpe fora de [0, 1]", Diagnostico.Nivel.ERRO))

	# CV10 (erro): R = 0 em algum AttackDef
	for ea in ataques:
		var r_a := Unidades.duracao_para_passos(ea.def.recarga_s)
		if r_a == 0:
			out.append(Diagnostico.novo(&"CV10", String(ea.id), ea.def.recarga_s,
				"AttackDef %s: recarga R = 0" % ea.id, Diagnostico.Nivel.ERRO))

	# CV11 (erro): passes_varredura < 1
	if t.passes_varredura < 1:
		out.append(Diagnostico.novo(&"CV11", "passes_varredura", t.passes_varredura,
			"CombatTuning: passes_varredura < 1", Diagnostico.Nivel.ERRO))

	# CV12, CV13, CV15, CV16, CV19, CV20 por AttackDef
	var menor_r_empurrao := 999999
	for ea in ataques:
		var a := ea.def
		var r_a := Unidades.duracao_para_passos(a.recarga_s)
		if a.empurrao > 0.0:
			menor_r_empurrao = mini(menor_r_empurrao, r_a)
		if a.forma == &"projetil":
			var s_px: float = a.params.get(&"velocidade_pxs", 0.0) / float(Unidades.TICK_RATE)
			var raio_p: float = a.params.get(&"raio_px", 0.0)
			var l_passos: int = Unidades.duracao_para_passos(a.params.get(&"vida_s", 0.0))
			if l_passos < 2:
				out.append(Diagnostico.novo(&"CV13", String(ea.id), l_passos,
					"AttackDef %s: vida do projétil L < 2" % ea.id, Diagnostico.Nivel.ERRO))
			var soma_r := raio_p + c.r_min
			if s_px > 2.0 * soma_r:
				out.append(Diagnostico.novo(&"CV12", String(ea.id), s_px,
					"AttackDef %s: s > 2 * (raio_px + r_min)" % ea.id, Diagnostico.Nivel.ERRO))
			elif s_px > soma_r:
				out.append(Diagnostico.novo(&"CV12", String(ea.id), s_px,
					"AttackDef %s: s > raio_px + r_min" % ea.id, Diagnostico.Nivel.AVISO))
			if t.nascimento_projetil_px + s_px - soma_r > c.raio_jogador_px + c.r_min:
				out.append(Diagnostico.novo(&"CV20", String(ea.id), t.nascimento_projetil_px,
					"AttackDef %s: zona cega à queima-roupa (CV20)" % ea.id,
					Diagnostico.Nivel.AVISO))
		elif a.forma == &"avanco":
			var n_inv := Unidades.duracao_para_passos(a.params.get(&"duracao_s", 0.0))
			var e_inv := p.invuln_extra_investida
			var inv_tot := n_inv + e_inv
			if r_a <= inv_tot:
				out.append(Diagnostico.novo(&"CV15", String(ea.id), r_a,
					"AttackDef %s: R (%d) <= N + E (%d)" % [ea.id, r_a, inv_tot],
					Diagnostico.Nivel.ERRO))
			elif (r_a > 0 and float(inv_tot) / float(r_a) > 0.5) or e_inv < 1:
				out.append(Diagnostico.novo(&"CV15", String(ea.id), r_a,
					"AttackDef %s: (N + E) / R > 0,5 ou E < 1" % ea.id,
					Diagnostico.Nivel.AVISO))
			var dist_inv: float = a.params.get(&"distancia_px", 0.0)
			var raio_inv: float = a.params.get(&"raio_px", 0.0)
			if n_inv > 0 and (dist_inv / float(n_inv)) > 2.0 * (raio_inv + c.r_min):
				out.append(Diagnostico.novo(&"CV16", String(ea.id), dist_inv,
					"AttackDef %s: passo da investida > 2 * (raio_px + r_min)" % ea.id,
					Diagnostico.Nivel.AVISO))
		elif a.forma == &"arco":
			var alc_arco: float = a.params.get(&"alcance_px", 0.0)
			if c.raio_jogador_px + t.folga_encostado_px >= alc_arco:
				out.append(Diagnostico.novo(&"CV19", String(ea.id), alc_arco,
					"AttackDef %s: raio_jogador_px + folga_encostado_px >= alcance_px" % ea.id,
					Diagnostico.Nivel.AVISO))

	# CV14 (aviso): passo_apoio_px >= raio_jogador_px + r_min, ou >= r_obs_min + raio_jogador_px
	if t.passo_apoio_px >= c.raio_jogador_px + c.r_min or t.passo_apoio_px >= c.r_obs_min + c.raio_jogador_px:
		out.append(Diagnostico.novo(&"CV14", "passo_apoio_px", t.passo_apoio_px,
			"CombatTuning: passo_apoio_px atravessaria corpo ou obstáculo",
			Diagnostico.Nivel.AVISO))

	# CV17 (aviso): passos(cambaleio_s) >= menor R entre golpes com empurrão > 0
	if menor_r_empurrao < 999999 and p.cambaleio >= menor_r_empurrao:
		out.append(Diagnostico.novo(&"CV17", "cambaleio_s", p.cambaleio,
			"CombatTuning: cambaleio (%d) >= menor R com empurrão (%d)" % [p.cambaleio, menor_r_empurrao],
			Diagnostico.Nivel.AVISO))

	# CV18 (aviso, cruzada com IA): existe inimigo comum e arma com combo com Q <= n * R < Q + W e Vida > dano * Σc
	var disparou_cv18 := false
	var q_passos := p.quebrou_recuperacao
	for ea in ataques:
		var a := ea.def
		if not ea.tem_combo_declarado or a.multiplicadores_combo.is_empty():
			continue
		var n_c := a.multiplicadores_combo.size()
		var r_a := Unidades.duracao_para_passos(a.recarga_s)
		var nr := n_c * r_a
		var soma_c := 0.0
		for m: float in a.multiplicadores_combo:
			soma_c += m
		var dano_ciclo := a.dano * soma_c
		for par: Array in c.inimigos_comuns:
			var vida_ini := float(par[0])
			var w_ini := int(par[1])
			if q_passos <= nr and nr < q_passos + w_ini and vida_ini > dano_ciclo:
				disparou_cv18 = true
				break
		if disparou_cv18:
			break
	if disparou_cv18:
		out.append(Diagnostico.novo(&"CV18", "quebrou_recuperacao_s", t.quebrou_recuperacao_s,
			"CombatTuning: trava de Quebrou! detectada (CV18)", Diagnostico.Nivel.AVISO))

	# CV21 (aviso): passos(invuln_atingido_s) <= passos(hitstop_atingido_s)
	if p.invuln_atingido <= p.hitstop_atingido:
		out.append(Diagnostico.novo(&"CV21", "invuln_atingido_s", t.invuln_atingido_s,
			"CombatTuning: invuln_atingido <= hitstop_atingido", Diagnostico.Nivel.AVISO))

	# CV22 (aviso): passos(impact_chefe_s) > passos(hitstop_abate_chefe_s), ou passos(hitstop_atingido_s) + passos(extra_inversao_s) >= passos(invuln_atingido_s)
	if p.impact_chefe > p.hitstop_abate_chefe or (p.hitstop_atingido + p.extra_inversao) >= p.invuln_atingido:
		out.append(Diagnostico.novo(&"CV22", "impact_chefe_s", t.impact_chefe_s,
			"CombatTuning: duração visual excede congelamento ou proteção (CV22)",
			Diagnostico.Nivel.AVISO))

	return out
