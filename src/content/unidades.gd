class_name Unidades
extends RefCounted
## Unidades do Godot e funções F1–F7 do GDD de Conteúdo (Formulas; R6; ADR-0004 +
## ADR-0001). Módulo estático e puro: nenhuma função guarda estado nem lê [Engine]
## (o valor do motor entra por parâmetro). Thread-safe (só constantes e matemática).
##
## [constant TICK_RATE] é a constante ÚNICA do passo de física (60/s); o
## orquestrador do passo e a validação da carga consomem esta mesma constante.
## F1–F6 rodam na importação; F7 roda no jogo, uma vez, no fim da cadeia de
## multiplicadores. O arredondamento é próprio ([method arredondar_meio_longe_do_zero]),
## nunca [code]round()[/code].
##
## Exemplo:
## [codeblock]
## var t := Unidades.ticks_para_segundos(16)          # 16/60 s
## var v := Unidades.velocidade_para_pxs(1.7)         # 153 px/s
## var p := Unidades.duracao_para_passos(t)           # 16
## var d := Unidades.verificar_tick_rate(Engine.physics_ticks_per_second)  # null se 60
## [/codeblock]

## Passos de física por segundo (cânone, baseline §54; padrão do Godot).
const TICK_RATE: int = 60
## Escala unidade do cânone → px (viewport lógico 1920×1080; arena 1280×720 = uma tela).
const UNIT_TO_PX: float = 1.5
## Arena canônica, em unidades do cânone (base da exigência de escala uniforme da F4).
const ARENA_CANONICA := Vector2(1280.0, 720.0)
## Menor meio-ângulo válido da F5 (abaixo é arco degenerado).
const ARCO_MINIMO_GRAUS: float = 5.0
## Maior meio-ângulo da F5 (círculo).
const ARCO_MAXIMO_GRAUS: float = 180.0
## Regra usada no diagnóstico de passo de física divergente (AC-19).
const REGRA_TICK_RATE := &"TICK_RATE"


## F1: ticks → segundos ([code]ticks / TICK_RATE[/code]), float64 sem arredondar.
static func ticks_para_segundos(ticks: int) -> float:
	return float(ticks) / float(TICK_RATE)


## F2: velocidade unidade/tick → px/s ([code]v × TICK_RATE × UNIT_TO_PX[/code]).
## Vale também para empurrão e limiar de impacto na parede.
static func velocidade_para_pxs(v_por_tick: float) -> float:
	return v_por_tick * float(TICK_RATE) * UNIT_TO_PX


## F3: taxa por tick → taxa por segundo ([code]r × TICK_RATE[/code]).
static func taxa_por_segundo(r_por_tick: float) -> float:
	return r_por_tick * float(TICK_RATE)


## F4: distância unidade → px ([code]d × UNIT_TO_PX[/code]).
static func unidade_para_px(d_unidades: float) -> float:
	return d_unidades * UNIT_TO_PX


## F4: [code]true[/code] se a arena de origem tem escala uniforme com a canônica
## (1280/largura = 720/altura). Falso recusa a importação.
static func escala_uniforme(largura: float, altura: float) -> bool:
	if largura <= 0.0 or altura <= 0.0:
		return false
	return is_equal_approx(ARENA_CANONICA.x / largura, ARENA_CANONICA.y / altura)


## F5: limiar [code]dot[/code] do cânone → meio-ângulo em graus
## ([code]rad_to_deg(acos(dot))[/code]); [param dot] é limitado a [-1, 1].
static func arco_meio_angulo_graus(dot: float) -> float:
	return rad_to_deg(acos(clampf(dot, -1.0, 1.0)))


## F5: meio-ângulo válido (5° a 180°). Abaixo de 5° é erro de validação.
static func arco_valido(meio_angulo_graus: float) -> bool:
	return meio_angulo_graus >= ARCO_MINIMO_GRAUS and meio_angulo_graus <= ARCO_MAXIMO_GRAUS


## F5 em jogo: cosseno do meio-ângulo, calculado uma vez na carga.
static func cosseno_do_meio_angulo(meio_angulo_graus: float) -> float:
	return cos(deg_to_rad(meio_angulo_graus))


## F5 em jogo: o golpe acerta quando [code]cos(ângulo até a mira) ≥ cos_meio[/code]
## (inclusivo: alvo exatamente em θ é acertado). Tolerância de 1e-9 contra o erro do
## float no limite.
static func acerta_arco(cos_angulo_ate_mira: float, cos_meio: float) -> bool:
	return cos_angulo_ate_mira >= cos_meio - 1e-9


## F6: tempo de vida do projétil ([code]rangeTicks / TICK_RATE[/code]).
static func vida_do_projetil_s(range_ticks: int) -> float:
	return ticks_para_segundos(range_ticks)


## F6 derivado (só leitura): alcance máximo [code]v_pxs × life_s[/code].
static func alcance_do_projetil_px(v_pxs: float, life_s: float) -> float:
	return v_pxs * life_s


## F6: linha informativa do relatório de validação (uma por projétil).
static func linha_de_alcance(rotulo: String, v_pxs: float, life_s: float) -> String:
	return "%s: life_s %.4f, reach_px %.1f" % [rotulo, life_s, alcance_do_projetil_px(v_pxs, life_s)]


## Arredonda ao inteiro mais próximo com empate em x,5 para longe do zero.
static func arredondar_meio_longe_do_zero(x: float) -> int:
	if x < 0.0:
		return -int(floor(-x + 0.5))
	return int(floor(x + 0.5))


## Arredonda a [param casas] casas decimais (meio longe do zero). Usado na gravação
## da F5 (2 casas).
static func arredondar_casas(x: float, casas: int) -> float:
	var f := pow(10.0, casas)
	return float(arredondar_meio_longe_do_zero(x * f)) / f


## F7: duração → passos de física. [code]max(1, arred(t × TICK_RATE))[/code] para
## [code]t > 0[/code]; 0 para [code]t ≤ 0[/code] (aceitar ou não o zero é decisão da
## validação, ver [method verificar_duracao]). Quantiza uma vez, no fim.
static func duracao_para_passos(t_s: float) -> int:
	if t_s <= 0.0:
		return 0
	return maxi(1, arredondar_meio_longe_do_zero(t_s * float(TICK_RATE)))


## F7 na validação de um valor gravado. Devolve [code]""[/code] se ok,
## [code]"erro:<texto>"[/code] (t = 0 em campo que não aceita zero, ou negativo) ou
## [code]"aviso:<texto>"[/code] (t > 0 abaixo de meio passo: sobe para 1 passo).
static func verificar_duracao(t_s: float, aceita_zero: bool) -> String:
	if t_s < 0.0:
		return "erro:%s (mín. 0)" % t_s
	if t_s == 0.0:
		return "" if aceita_zero else "erro:0 (mín. 1 passo)"
	if t_s * float(TICK_RATE) < 0.5:
		return "aviso:%s s abaixo de meio passo, vira 1 passo" % t_s
	return ""


## AC-19: confere o passo de física do projeto contra [constant TICK_RATE].
## [code]null[/code] se igual; senão um diagnóstico de erro bloqueante.
static func verificar_tick_rate(physics_ticks_per_second: int) -> Diagnostico:
	if physics_ticks_per_second == TICK_RATE:
		return null
	return Diagnostico.novo(REGRA_TICK_RATE, "physics_ticks_per_second", physics_ticks_per_second,
		"physics_ticks_per_second %d diferente de %d (F1, F3 e F7 perdem a paridade com o cânone)" % [physics_ticks_per_second, TICK_RATE])
