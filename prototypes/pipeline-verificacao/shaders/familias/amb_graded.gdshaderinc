#ifndef FAMILIA_AMB_GRADED_INCLUDED
#define FAMILIA_AMB_GRADED_INCLUDED

#include "res://shaders/comum/lut.gdshaderinc"

global uniform sampler2D lut_regiao : filter_linear, repeat_disable;
global uniform float fator_profundidade;
global uniform int modo_impacto;
global uniform int modo_bencao;
global uniform float saturacao_bencao;
global uniform float valor_bencao;
global uniform float t_vivo;
global uniform float t_apres;

const vec3 COR_TINTA = vec3(0.051, 0.055, 0.078);
const vec3 COR_OSSO_PLENO = vec3(0.902, 0.875, 0.812);

vec4 aplicar_amb_graded(vec4 cor_in, bool recebe_profundidade) {
	vec3 c = amostrar_lut_manual(lut_regiao, cor_in.rgb);
	if (recebe_profundidade) {
		c = linear_para_srgb(fator_profundidade * srgb_para_linear(c));
	}
	if (modo_bencao != 0) {
		c = aplicar_bencao_f5(c, saturacao_bencao, valor_bencao);
	}
	if (modo_impacto == 1) {
		c = COR_TINTA;
	} else if (modo_impacto == 2) {
		c = COR_OSSO_PLENO;
	} else if (modo_impacto == 3) {
		c = aplicar_bencao_f5(c, 0.5, 0.78);
	}
	return vec4(c, cor_in.a);
}

#endif
