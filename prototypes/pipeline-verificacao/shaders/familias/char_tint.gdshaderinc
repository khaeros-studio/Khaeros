#ifndef FAMILIA_CHAR_TINT_INCLUDED
#define FAMILIA_CHAR_TINT_INCLUDED

#include "res://shaders/comum/lut.gdshaderinc"

global uniform sampler2D lut_regiao : filter_linear, repeat_disable;
global uniform int modo_impacto;
global uniform int modo_bencao;
global uniform float saturacao_bencao;
global uniform float valor_bencao;
global uniform float t_vivo;
global uniform float t_apres;
global uniform float escala_traco;

const vec3 COR_TINTA = vec3(0.051, 0.055, 0.078);
const vec3 COR_OSSO_MUNDO = vec3(0.812, 0.776, 0.706);
const vec3 COR_OSSO_PLENO = vec3(0.902, 0.875, 0.812);

vec4 aplicar_char_tint(vec4 cor_in, float forca_grading, float flash) {
	vec3 c = mix(cor_in.rgb, amostrar_lut_manual(lut_regiao, cor_in.rgb), forca_grading);
	c = mix(c, COR_OSSO_MUNDO, clamp(flash, 0.0, 1.0));
	if (modo_bencao != 0) {
		c = aplicar_bencao_f5(c, saturacao_bencao, valor_bencao);
	}
	if (modo_impacto == 1 || modo_impacto == 2) {
		c = COR_TINTA;
	} else if (modo_impacto == 3) {
		c = aplicar_bencao_f5(c, 0.5, 0.85);
	}
	return vec4(c, cor_in.a);
}

#endif
