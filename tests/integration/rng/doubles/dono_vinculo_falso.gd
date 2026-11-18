## Dublê: dono de `pactos` (Vínculo F1) com consumo fixo de 4 reais (R3-P).
## u0 decide o encontro, u1 a câmara, u2 reservado, u3 a espécie (F6 com u fixo).
class_name DonoVinculoFalso
extends RefCounted

var _vinculo: FluxosDeVinculo


func _init(vinculo: FluxosDeVinculo) -> void:
	_vinculo = vinculo


## Decide o encontro da região. Sempre consome 4 números, mesmo com garantia.
## Devolve o índice da câmara do encontro, ou −1 sem encontro.
func decidir(regiao: int, chance_encontro: float, garantia: bool, camara_garantida: int,
		n_camaras: int, pesos_especies: Array[float]) -> int:
	var fluxo: FluxoRng = _vinculo.pactos(regiao)
	var u: Array[int] = []
	for i: int in 4:
		u.append(fluxo.proximo_u32())
	RngAritmetica.escolha_ponderada_real(u[3], pesos_especies)
	if garantia:
		return camara_garantida
	if RngAritmetica.real_unitario(u[0]) >= chance_encontro:
		return -1
	return RngAritmetica.inteiro_limitado(u[1], n_camaras)
