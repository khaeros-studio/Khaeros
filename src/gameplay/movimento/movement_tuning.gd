class_name MovementTuning
extends DefinicaoBase
## Knobs do Movimento (GDD movimento-e-esquiva R11; ADR-0008 §7). Só leitura em execução.
##
## Suporta validação declarativa de faixas (R11, AC-53) via [EsquemaDeDefinicao] e regras
## MV1–MV8 via [method validar_tuning] e [method validar_com_contexto] (story movimento-010).
## Os padrões são 0 de propósito: valor jogável vem sempre do dado (em teste, de fixture).
##
## Exemplo:
## [codeblock]
## var t := MovementTuning.new()
## t.duracao_esquiva_s = 0.15
## var p := ParametrosDoMovimento.de(t)   # p.d == 9
## [/codeblock]

## Cargas de base (1–3); o máximo efetivo é [code]valor(cargas_esquiva)[/code] do portador.
@export var cargas_base: int = 0
## Duração da esquiva em segundos (0,05–0,5).
@export var duracao_esquiva_s: float = 0.0
## Velocidade da esquiva em px/s (300–3000); não escala com nada.
@export var velocidade_esquiva_pxs: float = 0.0
## Invulnerabilidade extra depois da esquiva, em segundos (0–0,25; zero permitido).
@export var invuln_extra_s: float = 0.0
## Tempo de recarga de uma carga em segundos (0,1–3,0).
@export var recarga_s: float = 0.0
## Fator de velocidade de andar durante a recuperação de golpe (0–1).
@export var fator_recuperacao: float = 0.0
## Raio do corpo do jogador em px (10–50, MV4).
@export var raio_jogador_px: float = 0.0
## Teto de alvos do Corte; 0 = vazio (sem teto) em execução, ou nil/ausente no arquivo (MV5).
@export var alvos_max_corte: int = 0
## Marca se [member alvos_max_corte] foi explicitamente definido (para distinguir 0 inválido de vazio no MV5).
var _alvos_max_corte_definido: bool = false


func tipo_do_catalogo() -> StringName:
	return &"tuning"


func definir_alvos_max_corte(valor: Variant) -> void:
	if valor == null:
		_alvos_max_corte_definido = false
		alvos_max_corte = 0
	else:
		_alvos_max_corte_definido = true
		alvos_max_corte = int(valor)


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"cargas_base").faixa(1.0, 3.0)
	e.regra(&"duracao_esquiva_s").faixa(0.05, 0.5)
	e.regra(&"velocidade_esquiva_pxs").faixa(300.0, 3000.0)
	e.regra(&"invuln_extra_s").faixa(0.0, 0.25).aceita_default()
	e.regra(&"recarga_s").faixa(0.1, 3.0)
	e.regra(&"fator_recuperacao").faixa(0.0, 1.0).aceita_default()
	e.regra(&"raio_jogador_px").faixa(10.0, 50.0)
	e.regra(&"alvos_max_corte").opcional()


## Valida faixas R11 (V2/MV4) e regras MV1–MV8.
## [param r_obs_min]: menor raio de obstáculo das Câmaras (<= 0 se não aplicável).
## [param r_inimigo_min]: menor raio de inimigo do catálogo (<= 0 se sem inimigo/gatilho).
## [param alcance_extra_px]: param alcance_extra_px do gatilho corte_da_esquiva (< 0 se sem gatilho).
## [param input_buffer_steps]: prazo do buffer do InputTuning (<= 0 se não aplicável; padrão 10).
## [param alvos_corte_explicito]: se true, valida alvos_max_corte <= 0 como erro MV5 mesmo quando 0.
func validar_com_contexto(
		r_obs_min: float = -1.0,
		r_inimigo_min: float = -1.0,
		alcance_extra_px: float = -1.0,
		input_buffer_steps: int = 10,
		alvos_corte_explicito: bool = false) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	# Faixas R11 e MV4 (raio_jogador_px 10..50)
	var esq := esquema()
	for nome_campo: StringName in [
			&"cargas_base", &"duracao_esquiva_s", &"velocidade_esquiva_pxs",
			&"invuln_extra_s", &"recarga_s", &"fator_recuperacao", &"raio_jogador_px"]:
		var r := esq.regra(nome_campo)
		var v := float(get(nome_campo))
		var msg := V2Faixas.verificar_valor(r, v)
		if msg != "":
			var cod: StringName = &"MV4" if nome_campo == &"raio_jogador_px" else &"FAIXA"
			out.append(_diag(cod, String(nome_campo), get(nome_campo),
				"MovementTuning: %s %s" % [nome_campo, msg], Diagnostico.Nivel.ERRO))

	# MV5: alvos_max_corte = 0 (quando explícito) ou negativo
	if alvos_max_corte < 0 or ((_alvos_max_corte_definido or alvos_corte_explicito) and alvos_max_corte <= 0):
		out.append(_diag(&"MV5", "alvos_max_corte", alvos_max_corte,
			"MovementTuning: alvos_max_corte %d inválido (sem teto = vazio; com teto >= 1)" % alvos_max_corte,
			Diagnostico.Nivel.ERRO))

	var p := ParametrosDoMovimento.de(self)
	# MV3: inv_esquiva = D + E (soma de inteiros) já garantido em ParametrosDoMovimento.de(self)

	# MV2: R <= D + E (erro); (D + E) / R > 0,5 (aviso)
	if p.r <= p.inv_esquiva:
		out.append(_diag(&"MV2", "recarga_s", recarga_s,
			"MovementTuning: R (%d) <= D + E (%d) gera invulnerabilidade perpétua" % [p.r, p.inv_esquiva],
			Diagnostico.Nivel.ERRO))
	elif p.r > 0 and float(p.inv_esquiva) / float(p.r) > 0.5:
		out.append(_diag(&"MV2", "recarga_s", recarga_s,
			"MovementTuning: cobertura (D + E) / R = %.3f > 0,5" % (float(p.inv_esquiva) / float(p.r)),
			Diagnostico.Nivel.AVISO))

	# MV1: d_passo >= r_obs_min + raio_jogador_px (erro); margem < 2 (aviso)
	if r_obs_min > 0.0:
		var r_comb := r_obs_min + raio_jogador_px
		if p.d_passo >= r_comb:
			out.append(_diag(&"MV1", "velocidade_esquiva_pxs", velocidade_esquiva_pxs,
				"MovementTuning: d_passo (%.2f) >= r_obs_min + raio (%.2f)" % [p.d_passo, r_comb],
				Diagnostico.Nivel.ERRO))
		elif p.d_passo > 0.0 and (r_comb / p.d_passo) < 2.0:
			out.append(_diag(&"MV1", "velocidade_esquiva_pxs", velocidade_esquiva_pxs,
				"MovementTuning: margem de colisão %.3f < 2,0" % (r_comb / p.d_passo),
				Diagnostico.Nivel.AVISO))

	# MV6: d_passo > 2 * (raio_jogador_px + r_inimigo_min + alcance_extra_px) (aviso)
	if r_inimigo_min > 0.0 and alcance_extra_px >= 0.0:
		var lim_corte := 2.0 * (raio_jogador_px + r_inimigo_min + alcance_extra_px)
		if p.d_passo > lim_corte:
			out.append(_diag(&"MV6", "velocidade_esquiva_pxs", velocidade_esquiva_pxs,
				"MovementTuning: d_passo (%.2f) > 2 * alcance do Corte (%.2f)" % [p.d_passo, lim_corte],
				Diagnostico.Nivel.AVISO))

	# MV7: dist_total fora de [2 * raio_jogador_px, 600] (aviso)
	var min_dist := 2.0 * raio_jogador_px
	if p.dist_total < min_dist or p.dist_total > 600.0:
		out.append(_diag(&"MV7", "duracao_esquiva_s", p.dist_total,
			"MovementTuning: dist_total (%.2f) fora de [%.1f, 600]" % [p.dist_total, min_dist],
			Diagnostico.Nivel.AVISO))

	# MV8: D > input_buffer_steps (aviso)
	if input_buffer_steps > 0 and p.d > input_buffer_steps:
		out.append(_diag(&"MV8", "duracao_esquiva_s", p.d,
			"MovementTuning: D (%d) > input_buffer_steps (%d)" % [p.d, input_buffer_steps],
			Diagnostico.Nivel.AVISO))

	return out


func _diag(regra: StringName, campo: String, valor: Variant, msg: String,
		nivel: Diagnostico.Nivel) -> Diagnostico:
	var d := Diagnostico.novo(regra, campo, valor, msg, nivel)
	d.tipo = &"tuning"
	d.id = id if id != &"" else &"movement_tuning"
	return d

