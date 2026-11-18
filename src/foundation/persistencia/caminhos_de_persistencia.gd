## Caminhos lógicos dos arquivos do MVP por perfil (ADR-0013 §2; save-e-perfil R1).
##
## Só o perfil 0 existe no MVP; qualquer outro é rejeitado: [member valido] fica
## [code]false[/code], os caminhos ficam vazios e [member diagnostico] diz o motivo.
## Os caminhos são lógicos; [ArmazemUserGodot] os resolve contra a raiz injetada.
##
## Exemplo:
## [codeblock]
## var c := CaminhosDePersistencia.de(0)
## assert(c.valido and c.perfil == "user://perfil.cfg")
## [/codeblock]
class_name CaminhosDePersistencia
extends RefCounted

## Único perfil suportado no MVP (save-e-perfil R1).
const PERFIL_UNICO: int = 0

## [code]false[/code] se o perfil pedido não é suportado.
var valido: bool = false
## Motivo da rejeição; vazio quando [member valido].
var diagnostico: String = ""
## Índice do perfil pedido.
var indice: int = -1
## [code]user://perfil.cfg[/code] (dono do formato: Save).
var perfil: String = ""
## [code]user://opcoes.cfg[/code] (por máquina).
var opcoes: String = ""
## [code]user://preferencias.cfg[/code] (Armas).
var preferencias: String = ""
## [code]user://input_binds.cfg[/code] (Input, ADR-0006 §6).
var input_binds: String = ""
## Pasta [code]user://telemetria[/code] (sem barra final).
var pasta_telemetria: String = ""


## Devolve os caminhos do perfil [param n]. Perfil != 0 vem com
## [member valido] [code]false[/code] e [member diagnostico] preenchido.
static func de(n: int) -> CaminhosDePersistencia:
	var c := CaminhosDePersistencia.new()
	c.indice = n
	if n != PERFIL_UNICO:
		c.valido = false
		c.diagnostico = "perfil %d não suportado no MVP: só o perfil %d existe (save-e-perfil R1)" % [n, PERFIL_UNICO]
		return c
	c.valido = true
	c.perfil = "user://perfil.cfg"
	c.opcoes = "user://opcoes.cfg"
	c.preferencias = "user://preferencias.cfg"
	c.input_binds = "user://input_binds.cfg"
	c.pasta_telemetria = "user://telemetria"
	return c
