## Item 1 do passo (ADR-0001, ADR-0006): devolve a amostra de entrada do passo.
##
## Chamado exatamente uma vez por [code]passo_fisico()[/code], em todo estado (fora de
## [code]JOGO[/code] o Input amostra no contexto do estado; no hitstop o buffer fica com o
## prazo parado — regras do Input). Em produção, adaptador sobre [ProvedorDeEntrada].
##
## Exemplo:
## [codeblock]
## class_name FonteDoProvedor extends FonteDeAmostra
## var _provedor: ProvedorDeEntrada
## func amostrar() -> AmostraDeEntrada:
##     return _provedor.amostrar()
## [/codeblock]
## Não é seguro entre threads.
@abstract
class_name FonteDeAmostra
extends RefCounted


## Amostra do passo corrente (nunca [code]null[/code]).
@abstract func amostrar() -> AmostraDeEntrada
