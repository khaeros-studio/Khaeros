class_name EstadoDeStatus
extends RefCounted
## Estado vivo dos três status em um único inimigo (`design/gdd/efeitos-de-status.md` R1–R6).
##
## Mantém acúmulos e passos restantes de `sangramento`, `queimadura` e `abalo`, bem como
## o acumulador do número agregado (`R6`, `F5`).

var sangramento_acumulos: float = 0.0
var sangramento_restante: int = 0

var queimadura_acumulos: float = 0.0
var queimadura_restante: int = 0

var abalo_restante: int = 0

## Dano silencioso acumulado na janela atual de `intervalo_numero_s` + resto da janela anterior.
var dano_acumulado_janela: float = 0.0
## Passos vivos contados na janela atual (só avança enquanto sangramento ou queimadura > 0).
var passos_janela: int = 0


func tem_dot_ativo() -> bool:
	return sangramento_restante > 0 or queimadura_restante > 0


func tem_qualquer_ativo() -> bool:
	return sangramento_restante > 0 or queimadura_restante > 0 or abalo_restante > 0


func limpar() -> void:
	sangramento_acumulos = 0.0
	sangramento_restante = 0
	queimadura_acumulos = 0.0
	queimadura_restante = 0
	abalo_restante = 0
	dano_acumulado_janela = 0.0
	passos_janela = 0


func _formatar_acumulos(ac: float, rest: int) -> Variant:
	if rest <= 0 or ac <= 0.0:
		return 0
	var iv: int = int(round(ac))
	if absf(ac - float(iv)) <= 1e-6:
		return iv
	return ac


func para_dicionario() -> Dictionary:
	return {
		&"sangramento": {
			&"acumulos": _formatar_acumulos(sangramento_acumulos, sangramento_restante),
			&"restante": sangramento_restante,
		},
		&"queimadura": {
			&"acumulos": _formatar_acumulos(queimadura_acumulos, queimadura_restante),
			&"restante": queimadura_restante,
		},
		&"abalo": {
			&"ativo": abalo_restante > 0,
			&"restante": abalo_restante,
		},
	}
