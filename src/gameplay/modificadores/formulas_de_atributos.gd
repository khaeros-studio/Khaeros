class_name FormulasDeModificadores
extends RefCounted
## Funções puras do GDD modificadores-e-atributos (F1, F2, F3) e o arredondamento próprio
## (ADR-0009 §2; ADR-0010: um arredondamento só). Nunca usa round()/roundi()/snappedf,
## nem int() intermediário, nem epsilon. Tudo em float até o fim.
##
## Exemplo:
## [codeblock]
## FormulasDeModificadores.arredondar_meio_longe_do_zero(22.5)  # 23
## FormulasDeModificadores.dano_recebido(20.0 * 0.7, 0.12, 0.6, 1.0)  # 12
## [/codeblock]

# Forma da F3: "max(1, …)" — o dano recebido nunca é menor que 1 antes do escudo.
const _PISO_DANO_RECEBIDO: int = 1


## Arredonda ao inteiro mais próximo com o meio longe do zero (22,5 → 23; −22,5 → −23;
## 0,49999999999999994 → 0). [code]f = floor(|x|)[/code]; +1 se [code]|x| − f ≥ 0,5[/code];
## reaplica o sinal.
static func arredondar_meio_longe_do_zero(x: float) -> int:
	var a: float = absf(x)
	var f: float = floorf(a)
	if a - f >= 0.5:
		f += 1.0
	var r: int = int(f)  # f já é inteiro exato: conversão final, não intermediária
	return -r if x < 0.0 else r


## F1 sem o arredondamento: [code]clamp(max(0, base + Σp) × max(0, 1 + Σ%) × Πm, piso, teto)[/code].
## O piso vale só no fim (independe da ordem das bênçãos).
static func valor_f1(base: float, soma_planos: float, soma_percentuais: float,
		produto_multiplicadores: float, piso: float, teto: float) -> float:
	var v: float = maxf(0.0, base + soma_planos) * maxf(0.0, 1.0 + soma_percentuais) * produto_multiplicadores
	return clampf(v, piso, teto)


## F2 sem o teto: [code]max(0, 1 + P_todo + P_slot) × Π multiplicadores[/code].
## O teto ([code]teto_multiplicador_dano[/code]) é aplicado por último pelo [DanoCongelado].
static func multiplicador_f2(p_todo: float, p_slot: float, produto_multiplicadores: float) -> float:
	return maxf(0.0, 1.0 + p_todo + p_slot) * produto_multiplicadores


## F3: dano recebido (int ≥ 1, antes do escudo).
## [code]max(1, arred(bruto × (1 − min(teto_red, max(0, reducao))) × guarda))[/code], com
## [code]bruto = dano_base × M_atacante[/code] (o Combate passa o bruto; ver ADR-0010).
static func dano_recebido(bruto: float, reducao: float, teto_red: float, guarda: float) -> int:
	var red: float = minf(teto_red, maxf(0.0, reducao))
	var d: int = arredondar_meio_longe_do_zero(bruto * (1.0 - red) * guarda)
	return maxi(_PISO_DANO_RECEBIDO, d)


## F3, depois do escudo: Vida perdida = [code]max(0, dano − escudo)[/code].
static func vida_perdida(dano: int, escudo: int) -> int:
	return maxi(0, dano - escudo)


## F3, depois do escudo: escudo restante = [code]max(0, escudo − dano)[/code].
static func escudo_restante(dano: int, escudo: int) -> int:
	return maxi(0, escudo - dano)


## Texto do número já arredondado pela mesma regra do valor aplicado (TR-bencaos-009:
## Rara 137,5 mostra "138").
static func formatar_numero_arredondado(x: float) -> String:
	return str(arredondar_meio_longe_do_zero(x))
