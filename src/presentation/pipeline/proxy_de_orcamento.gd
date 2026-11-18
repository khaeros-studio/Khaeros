class_name ProxyDeOrcamento
extends RefCounted
## Proxy determinístico de contagem de draw calls por grupo e cálculo de overdraw/memória (F10, R9;
## ADR-0011 §7, §8, Performance Implications).
## O teto global do ADR-0011 é 500 draw calls (444 nos grupos + 56 de reserva), e o orçamento
## operacional medido em runtime da cena de estresse fica ≤ 350 draw calls (`dc_estresse = 292`).

const TETO_DC_TOTAL: int = 500
const TETO_OPERACIONAL_DC: int = 350
const TETO_MEMORIA_MIB: int = 512
const ALERTA_MEMORIA_MIB: int = 448

var _contagem: Dictionary = {
	&"ambiente": 0,
	&"sombras_e_telegrafos": 0,
	&"entidades": 0,
	&"vfx": 0,
	&"passes": 0,
	&"ui": 0,
}

var _emissores_ativos: int = 0
var _particulas_gpu_ativas: int = 0
var _flipbooks_ativos: int = 0


func definir_grupo(grupo: StringName, draw_calls: int) -> void:
	if _contagem.has(grupo):
		_contagem[grupo] = maxi(0, draw_calls)


func definir_particulas(emissores: int, particulas_gpu: int, flipbooks: int = 0) -> void:
	_emissores_ativos = maxi(0, emissores)
	_particulas_gpu_ativas = maxi(0, particulas_gpu)
	_flipbooks_ativos = maxi(0, flipbooks)


func draw_calls_do_grupo(grupo: StringName) -> int:
	return int(_contagem.get(grupo, 0))


func total_draw_calls_proxy() -> int:
	var soma := 0
	for k: StringName in _contagem:
		soma += int(_contagem[k])
	return soma


func dentro_do_orcamento_operacional() -> bool:
	return total_draw_calls_proxy() <= TETO_OPERACIONAL_DC


func dentro_do_teto_absoluto() -> bool:
	return total_draw_calls_proxy() <= TETO_DC_TOTAL


## F3 do Feedback: `uso = max(dc_vfx / 64, emissores / 24, particulas_gpu / 1500)`.
func uso_vfx() -> float:
	var u_dc := float(draw_calls_do_grupo(&"vfx")) / 64.0
	var u_em := float(_emissores_ativos) / 24.0
	var u_pt := float(_particulas_gpu_ativas) / 1500.0
	return maxf(u_dc, maxf(u_em, u_pt))


## F10: Overdraw equivalente em telas de 1920×1080 para `n` telégrafos C120 (quad + malha de borda).
static func overdraw_telegrafos_c120(n_telegrafos: int, usar_malha_borda: bool = true) -> float:
	var area_quad := 244.0 * 244.0 # 59.536
	var area_contorno := PI * (122.0 * 122.0 - 114.0 * 114.0) if usar_malha_borda else area_quad
	return float(n_telegrafos) * (area_quad + area_contorno) / (1920.0 * 1080.0)


## F10: Memória residente de uma textura em bytes (`W * H * bpp * (4/3 se mipmaps)`).
static func bytes_textura(largura: int, altura: int, bpp: int = 4, com_mipmaps: bool = false) -> int:
	var base := float(largura) * float(altura) * float(bpp)
	if com_mipmaps:
		base *= 4.0 / 3.0
	return int(round(base))
