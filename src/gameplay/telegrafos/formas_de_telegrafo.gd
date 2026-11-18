class_name FormasDeTelegrafo
extends RefCounted
## Derivação pura das formas e dimensões de telégrafo a partir de EnemyDef e BossPatternDef
## (GDD telegrafos.md R5, R5a, F2–F4, F7; ADR-0014 Decisões 4, 10).


class FormaDerivada extends RefCounted:
	var valida: bool = false
	var forma: TelegrafoTipos.Forma = TelegrafoTipos.Forma.SETOR
	var modo: TelegrafoTipos.Modo = TelegrafoTipos.Modo.CENTRO_A_BORDA
	var preparo_passos: int = 0
	var raio: float = 0.0
	var r_int: float = 0.0
	var r_ext: float = 0.0
	var cos_meio: float = TelegrafoTipos.COS_MEIO_SETOR_PADRAO
	var meio_angulo_graus: float = TelegrafoTipos.MEIO_ANGULO_SETOR_GRAUS
	var x_min: float = 0.0
	var comprimento: float = 0.0
	var largura: float = 0.0
	var percurso: float = 0.0
	var r_c: float = 0.0
	var folga_canto: float = 0.0
	var eh_faixa_projetil: bool = false
	var eh_avanco: bool = false
	var contorno_secundario_raio: float = 0.0
	var ondas_concentricas: int = 1
	var leques: int = 1


## Deriva a forma de um inimigo comum ou elite pelo seu EnemyDef e raio do alvo travado (F2–F4, F7).
static func derivar(def: EnemyDef, raio_alvo: float = TelegrafoTipos.RAIO_JOGADOR_PADRAO_PX,
		avanco_passos: int = TelegrafoTipos.AVANCO_PASSOS_PADRAO) -> FormaDerivada:
	var f := FormaDerivada.new()
	if def == null or raio_alvo <= 0.0:
		return f
	f.preparo_passos = Unidades.duracao_para_passos(def.preparo_s)
	if f.preparo_passos < 1:
		return f
	var comp := def.comportamento
	if comp == &"corpo_a_corpo" or comp == &"melee":
		# F2 / F7: R = alcance_px + r_alvo + 0,5 * raio_inimigo_px
		f.forma = TelegrafoTipos.Forma.SETOR
		f.modo = TelegrafoTipos.Modo.CENTRO_A_BORDA
		f.raio = def.alcance_px + raio_alvo + 0.5 * def.raio_px
		f.cos_meio = TelegrafoTipos.COS_MEIO_SETOR_PADRAO
		f.meio_angulo_graus = Unidades.arco_meio_angulo_graus(f.cos_meio)
		f.valida = f.raio > 0.0
		return f
	if comp == &"distancia" or comp == &"ranged":
		# F3 / F7: r_acerto = 13,5 + r_alvo; largura = 2 * r_acerto;
		# saida = raio_inimigo_px + 9; alcance = 240 * (vel_proj_pxs / 60); comprimento = saida + alcance + r_acerto
		f.forma = TelegrafoTipos.Forma.RETANGULO
		f.modo = TelegrafoTipos.Modo.AO_LONGO_DO_EIXO
		f.eh_faixa_projetil = true
		var r_acerto := TelegrafoTipos.RAIO_PROJETIL_PADRAO_PX + raio_alvo
		var saida := def.raio_px + TelegrafoTipos.SAIDA_OFFSET_PX
		var v_proj_passo := def.velocidade_projetil / float(Unidades.TICK_RATE)
		var alcance := float(TelegrafoTipos.VIDA_PROJETIL_PADRAO_PASSOS) * v_proj_passo
		f.x_min = 0.0
		f.largura = 2.0 * r_acerto
		f.comprimento = saida + alcance + r_acerto
		f.r_c = r_acerto
		f.valida = f.largura > 0.0 and f.comprimento > 0.0 and def.velocidade_projetil > 0.0
		return f
	if comp == &"arremetida" or comp == &"charger":
		# F4 / F7: percurso = (vel_pxs / 60) * 3,6 * N; R_c = raio_inimigo_px + r_alvo; L = percurso + 2*R_c; W = 2*R_c
		f.forma = TelegrafoTipos.Forma.RETANGULO
		f.modo = TelegrafoTipos.Modo.AO_LONGO_DO_EIXO
		f.eh_avanco = true
		var v_passo := def.velocidade / float(Unidades.TICK_RATE)
		f.percurso = v_passo * TelegrafoTipos.AVANCO_MULT_VELOCIDADE * float(avanco_passos)
		f.r_c = def.raio_px + raio_alvo
		f.x_min = -f.r_c
		f.comprimento = f.percurso + 2.0 * f.r_c
		f.largura = 2.0 * f.r_c
		f.folga_canto = (sqrt(2.0) - 1.0) * f.r_c
		f.valida = f.largura > 0.0 and f.comprimento > 0.0 and f.percurso > 0.0
		return f
	return f


## Deriva a forma de um padrão de chefe (BossPatternDef) com o raio do chefe e o raio do alvo travado (R5a, F2 de Chefes).
static func derivar_padrao_chefe(padrao: BossPatternDef, raio_chefe_px: float = 45.0,
		raio_alvo: float = TelegrafoTipos.RAIO_JOGADOR_PADRAO_PX,
		v_avanco_pxs: float = 675.0) -> FormaDerivada:
	var f := FormaDerivada.new()
	if padrao == null or raio_alvo <= 0.0:
		return f
	f.preparo_passos = Unidades.duracao_para_passos(padrao.preparo_s)
	if f.preparo_passos < 1:
		return f
	f.contorno_secundario_raio = padrao.raio_secundario_px
	f.ondas_concentricas = maxi(1, int(padrao.dimensoes.get(&"ondas", 1.0)))
	f.leques = maxi(1, int(padrao.dimensoes.get(&"leques", 1.0)))
	var ft := padrao.forma_telegrafo
	if ft == &"setor":
		f.forma = TelegrafoTipos.Forma.SETOR
		f.modo = TelegrafoTipos.Modo.CENTRO_A_BORDA
		f.raio = float(padrao.dimensoes.get(&"raio_px", 165.0))
		f.cos_meio = float(padrao.dimensoes.get(&"cos_meio", TelegrafoTipos.COS_MEIO_SETOR_PADRAO))
		f.meio_angulo_graus = Unidades.arco_meio_angulo_graus(f.cos_meio)
		f.valida = f.raio > 0.0
		return f
	if ft == &"retangulo":
		f.forma = TelegrafoTipos.Forma.RETANGULO
		f.modo = TelegrafoTipos.Modo.AO_LONGO_DO_EIXO
		f.eh_avanco = true
		var exec_passos := Unidades.duracao_para_passos(padrao.execucao_s)
		var vel_av := float(padrao.dimensoes.get(&"v_avanco_pxs", v_avanco_pxs))
		f.percurso = float(padrao.dimensoes.get(&"percurso_px", (vel_av / float(Unidades.TICK_RATE)) * float(exec_passos)))
		f.r_c = raio_chefe_px + raio_alvo
		f.x_min = -f.r_c
		f.comprimento = f.percurso + 2.0 * f.r_c
		f.largura = 2.0 * f.r_c
		f.folga_canto = (sqrt(2.0) - 1.0) * f.r_c
		f.valida = f.largura > 0.0 and f.comprimento > 0.0 and f.percurso > 0.0
		return f
	if ft == &"anel":
		f.forma = TelegrafoTipos.Forma.ANEL
		f.modo = TelegrafoTipos.Modo.BORDA_AO_CENTRO
		f.r_int = float(padrao.dimensoes.get(&"r_int", 0.0))
		f.r_ext = float(padrao.dimensoes.get(&"r_ext", float(padrao.dimensoes.get(&"raio_px", 210.0))))
		f.raio = f.r_ext
		f.valida = f.r_ext > 0.0 and f.r_int >= 0.0 and f.r_ext > f.r_int
		return f
	if ft == &"circulo":
		f.forma = TelegrafoTipos.Forma.CIRCULO
		f.modo = TelegrafoTipos.Modo.BORDA_AO_CENTRO
		f.raio = float(padrao.dimensoes.get(&"raio_px", 225.0))
		f.valida = f.raio > 0.0
		return f
	return f


## F6: folga de leitura em passos (preparo - passos(reacao_ref_s)).
static func folga_de_leitura(preparo_passos: int, reacao_ref_s: float = 0.25) -> int:
	return preparo_passos - Unidades.duracao_para_passos(reacao_ref_s)
