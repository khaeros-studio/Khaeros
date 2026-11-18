class_name SorteioDeOferta
extends RefCounted
## Sorteio de uma oferta (GDD bencaos-tradicoes.md R4, R6, R7, F5; ADR-0005).
##
## Fluxo [code]bencaos[/code]: F7 com k' = min(tamanho_oferta, n) e descarte de
## tamanho_oferta − k' reais (consumo fixo). Fluxo [code]raridade[/code]: sempre
## tamanho_oferta reais; a carta i usa o real i; os das cartas inexistentes são
## descartados. Limiares estritos (u < acumulado) a partir dos pesos da [RarityTable];
## [code]raridade_bonus[/code] soma com teto em Épica. Nunca usa RNG da engine.
##
## Exemplo:
## [codeblock]
## var s := SorteioDeOferta.new(tabela, tuning)
## var cartas := s.sortear(registro.livres(), fluxos.bencaos(0, 2), fluxos.raridade(0, 2))
## [/codeblock]

## Índices de raridade (mesma ordem de [member RarityTable.pesos] e [member RarityTable.escalas]).
const COMUM: int = 0
const RARA: int = 1
const EPICA: int = 2
## Resolução técnica dos pesos (não é valor de gameplay): 1e-6 de precisão.
const RESOLUCAO_PESOS: float = 1000000.0

var _tabela: RarityTable
var _tuning: BencaosTuning


## Recebe a tabela e o tuning já validados (BN1, BN2).
func _init(tabela: RarityTable, tuning: BencaosTuning) -> void:
	_tabela = tabela
	_tuning = tuning


## Tabela de raridade usada pelo sorteio (somente leitura).
func tabela() -> RarityTable:
	return _tabela


## Escala numérica da [param raridade] (1,0 / 1,5 / 2,0).
func escala_de(raridade: int) -> float:
	return TextoDaCarta.escala_da_raridade(raridade, _tabela)


## Sorteia uma oferta sobre [param livres] (ordem do manifesto). Consome sempre
## [code]tamanho_oferta[/code] reais de cada fluxo, inclusive com pool menor ou vazio.
func sortear(livres: Array[BoonDef], fluxo_bencaos: FluxoRng, fluxo_raridade: FluxoRng) -> Array[CartaDaOferta]:
	var tamanho: int = _tuning.tamanho_oferta
	var n: int = livres.size()
	var k: int = mini(tamanho, n)
	var indices: Array[int] = fluxo_bencaos.k_distintos(n, k)
	for _d: int in tamanho - indices.size():
		fluxo_bencaos.real_unitario()
	var out: Array[CartaDaOferta] = []
	for i: int in tamanho:
		var u: float = fluxo_raridade.real_unitario()
		if i < indices.size():
			var idx: int = indices[i]
			out.append(CartaDaOferta.new(idx, livres[idx].id, raridade_de(u)))
	return out


## Raridade de um real u em [0, 1) com o bônus do tuning (R4, R7).
func raridade_de(u: float) -> int:
	return aplicar_bonus(raridade_base(u))


## Raridade sem bônus: primeira faixa com u < peso acumulado / soma. Os pesos são
## levados a inteiros em [constant RESOLUCAO_PESOS] antes de acumular, para que
## 0,6 + 0,3 dê exatamente o limiar 0,9 (a soma em float daria 0,8999…; AC-BN-05).
func raridade_base(u: float) -> int:
	var inteiros: Array[int] = []
	var soma: int = 0
	for p: float in _tabela.pesos:
		var w: int = FormulasDeModificadores.arredondar_meio_longe_do_zero(p * RESOLUCAO_PESOS)
		inteiros.append(w)
		soma += w
	var acumulado: int = 0
	var ultima: int = inteiros.size() - 1
	for i: int in ultima:
		acumulado += inteiros[i]
		if u < float(acumulado) / float(soma):
			return i
	return ultima


## Soma [code]raridade_bonus[/code] (parte inteira) com teto na última raridade (R7).
func aplicar_bonus(raridade: int) -> int:
	return mini(raridade + int(_tuning.raridade_bonus), _tabela.pesos.size() - 1)
