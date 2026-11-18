class_name ProfundidadeCamara
extends RefCounted
## Cálculo de profundidade [code]p[/code], [code]p_max[/code] e fonte [code]profundidade[/code]
## (GDD camaras-e-ondas.md R1-P, R3, R3-P; ADR-0015 §4; ADR-0009).
##
## As Câmaras são a **dona única** de [code]p[/code] e [code]p_max[/code]:
## - Câmaras de combate contam a partir de 0 (no Limiar: índices 0, 1, 2, 4, 5 → p = 0, 1, 2, 3, 4).
## - Santuário (índice 3) e Chefe (índice 6) não incrementam [code]p[/code] e usam o [code]p[/code]
##   da última câmara de combate anterior (índice 3 usa p = 2; índice 6 usa p = 4).
## - [code]p_max[/code] = nº de câmaras de combate − 1 (no Limiar: 5 − 1 = 4).
## - A chave dos fluxos de estrutura do RNG é sempre [code](regiao_idx, indice_camara)[/code], nunca [code]p[/code].

const TIPO_COMBATE: StringName = &"combate"
const TIPO_SANTUARIO: StringName = &"santuario"
const TIPO_CHEFE: StringName = &"chefe"
const FONTE_PROFUNDIDADE: StringName = &"profundidade"
const ESCALA_VIDA_POR_PROF: float = 0.05


## Calcula [code]p_max[/code] da região (nº de câmaras de combate jogáveis − 1).
static func calcular_p_max(camaras: Array[StringName], camaras_jogaveis: int = -1) -> int:
	var limite: int = camaras.size() if camaras_jogaveis < 0 else mini(camaras_jogaveis, camaras.size())
	var n_combate: int = 0
	for i: int in limite:
		if camaras[i] == TIPO_COMBATE:
			n_combate += 1
	return maxi(0, n_combate - 1)


## Devolve a profundidade [code]p[/code] efetiva para o [param indice] na sequência [param camaras].
## Santuário e chefe usam o [code]p[/code] da última câmara de combate anterior (R3, R3-P).
static func profundidade_no_indice(camaras: Array[StringName], indice: int) -> int:
	if camaras.is_empty() or indice < 0:
		return 0
	var limite: int = mini(indice, camaras.size() - 1)
	var p_atual: int = -1
	for i: int in range(limite + 1):
		if camaras[i] == TIPO_COMBATE:
			p_atual += 1
	return maxi(0, p_atual)


## Verdadeiro se a câmara no [param indice] é de combate (tem [code]p[/code] próprio).
static func eh_camara_de_combate(camaras: Array[StringName], indice: int) -> bool:
	if indice < 0 or indice >= camaras.size():
		return false
	return camaras[indice] == TIPO_COMBATE


## Chave estrutural para os fluxos do RNG: sempre [code](regiao_idx, indice_camara)[/code] (TR-camaras-001).
static func chave_rng(regiao_idx: int, indice_camara: int) -> Vector2i:
	return Vector2i(regiao_idx, indice_camara)


## Cria a [FonteDeModificador] [code]profundidade[/code] (+5% de [code]vida_max[/code] por [param p], IA F2 / Modificadores).
static func criar_fonte_profundidade(p: int) -> FonteDeModificador:
	var bonus: float = ESCALA_VIDA_POR_PROF * float(maxi(0, p))
	var mods: Array[Modificador] = []
	if bonus > 0.0:
		mods.append(Modificador.new(Atributos.VIDA_MAX, Modificador.Operacao.PERCENTUAL, bonus))
	return FonteDeModificador.new(FONTE_PROFUNDIDADE, mods)
