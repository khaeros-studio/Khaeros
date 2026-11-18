## Plano puro de recuperação de sobras da gravação atômica (ADR-0013 §4).
##
## Recebe só o que existe no disco e devolve as ações, em ordem. Regras:
## destino existe → usa e apaga sobras ([code].old[/code], [code].tmp[/code]);
## destino ausente e [code].old[/code] presente → restaura [code].old[/code];
## [code].tmp[/code] sozinho [b]nunca[/b] é promovido (pode estar truncado), só apagado.
##
## Exemplo:
## [codeblock]
## var acoes := RecuperacaoDeGravacao.planejar(false, true, true)
## # [&"restaurar_old", &"apagar_tmp"]
## [/codeblock]
class_name RecuperacaoDeGravacao
extends RefCounted

## Renomear [code]destino.old[/code] → [code]destino[/code].
const RESTAURAR_OLD: StringName = &"restaurar_old"
## Apagar [code]destino.old[/code].
const APAGAR_OLD: StringName = &"apagar_old"
## Apagar [code]destino.tmp[/code].
const APAGAR_TMP: StringName = &"apagar_tmp"


## Ações de recuperação, em ordem de execução, para o estado informado.
static func planejar(existe_destino: bool, existe_old: bool, existe_tmp: bool) -> Array[StringName]:
	var acoes: Array[StringName] = []
	if existe_destino:
		if existe_old:
			acoes.append(APAGAR_OLD)
	elif existe_old:
		acoes.append(RESTAURAR_OLD)
	if existe_tmp:
		acoes.append(APAGAR_TMP)
	return acoes
