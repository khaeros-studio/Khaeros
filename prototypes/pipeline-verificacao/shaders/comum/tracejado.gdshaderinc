#ifndef COMUM_TRACEJADO_INCLUDED
#define COMUM_TRACEJADO_INCLUDED

float fase_tracejado(float s, float perimetro, float traco_px, float intervalo_px, float aa_grad_s) {
	float P = traco_px + intervalo_px;
	float n = max(1.0, round(perimetro / P));
	float P_aj = perimetro / n;
	float r_t = traco_px / P;
	float phi = fract(s / P_aj);
	float delta = abs(fract(phi - 0.5 * r_t + 0.5) - 0.5);
	float aa_phi = max(aa_grad_s / P_aj, 1e-5);
	return clamp(0.5 - (delta - 0.5 * r_t) / aa_phi, 0.0, 1.0);
}

#endif
