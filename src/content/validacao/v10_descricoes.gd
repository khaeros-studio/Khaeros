class_name V10Descricoes
extends ValidadorDeRegra
## V10: descrições sem dígitos fora de [code]{…}[/code]; todo marcador resolve para
## [code]valor[/code], um [code]params[/code] de um [EffectDef] da definição ou um campo
## do [StatusTuning]; formato só [code]int[/code], [code]pct[/code], [code]num[/code]
## (GDD de Conteúdo R7). Com mais de um efeito, o marcador leva o tipo
## ([code]{vida_max_plano.valor:int}[/code]).
##
## Exemplo:
## [codeblock]
## var erros := V10Descricoes.verificar("causa {valor} de dano", efeitos, status_tuning, registros)
## var texto := V10Descricoes.formatar(-10.0, "int")   # "10"
## [/codeblock]

## Lista fechada de formatos (R7).
const FORMATOS: PackedStringArray = ["int", "pct", "num"]

static var _re_marcador: RegEx
static var _re_digito: RegEx

var _textos: TabelaDeTextos
var _registros: RegistrosDeChaves


func _init(textos: TabelaDeTextos, registros: RegistrosDeChaves) -> void:
	_textos = textos
	_registros = registros


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var status_tuning: StatusTuning = null
	for item in itens:
		if item.definicao is StatusTuning:
			status_tuning = item.definicao
	for item in itens:
		var efeitos: Array[EffectDef] = []
		var lista: Variant = item.definicao.get(&"efeitos")
		if lista is Array:
			for ef: Variant in lista:
				if ef is EffectDef:
					efeitos.append(ef)
		for r in item.definicao.esquema().regras():
			if not r.descricao:
				continue
			var chave := str(item.definicao.get(r.nome))
			if chave.is_empty() or not _textos.tem(chave):
				continue
			for msg in verificar(_textos.texto(chave), efeitos, status_tuning, _registros):
				out.append(Diagnostico.de_item(item, &"V10", String(r.nome), chave, "%s: %s" % [rotulo(item), msg]))
	return out


## Erros V10 de um texto contra os efeitos da definição (vazio = passou).
static func verificar(texto: String, efeitos: Array[EffectDef], status_tuning: StatusTuning, registros: RegistrosDeChaves) -> PackedStringArray:
	_preparar()
	var erros := PackedStringArray()
	var sem_marcadores := _re_marcador.sub(texto, "", true)
	var dig := _re_digito.search(sem_marcadores)
	if dig != null:
		erros.append("descrição com número literal \"%s\"" % dig.get_string())
	for m in _re_marcador.search_all(texto):
		var corpo := m.get_string(1)
		var partes := corpo.split(":")
		var campo := partes[0]
		if partes.size() > 1 and not FORMATOS.has(partes[1]):
			erros.append("{%s}: formato %s fora da lista" % [corpo, partes[1]])
			continue
		var msg := _resolver(campo, efeitos, status_tuning, registros)
		if msg != "":
			erros.append("{%s}: %s" % [corpo, msg])
	return erros


static func _resolver(campo: String, efeitos: Array[EffectDef], status_tuning: StatusTuning, registros: RegistrosDeChaves) -> String:
	if campo.begins_with("status."):
		var p := campo.split(".")
		if p.size() != 3:
			return "marcador de status malformado"
		if registros != null and registros.tem_registro(&"status") and not registros.resolve(&"status", StringName(p[1])):
			return "status %s fora do registro" % p[1]
		if status_tuning == null or not (StringName(p[2]) in status_tuning):
			return "%s não é campo do StatusTuning" % p[2]
		return ""
	if campo.contains("."):
		var tipo := StringName(campo.get_slice(".", 0))
		var nome := campo.get_slice(".", 1)
		for e in efeitos:
			if e.tipo == tipo:
				return "" if _campo_do_efeito(e, nome) else "%s não é params do efeito %s" % [nome, tipo]
		return "efeito %s não existe na definição" % tipo
	if efeitos.size() > 1:
		return "marcador sem tipo numa definição com mais de um efeito"
	if efeitos.is_empty():
		return "definição sem efeito para resolver o marcador"
	return "" if _campo_do_efeito(efeitos[0], campo) else "%s não é params do efeito %s" % [campo, efeitos[0].tipo]


static func _campo_do_efeito(e: EffectDef, nome: String) -> bool:
	return nome == "valor" or e.params.has(StringName(nome))


## Texto exibido de um valor (R7): sempre o absoluto; [code]int[/code] arredonda,
## [code]pct[/code] ×100 com %, [code]num[/code] inteiro ou 1 casa (vírgula PT-BR).
static func formatar(valor: float, formato: String = "num") -> String:
	var v := absf(valor)
	match formato:
		"int":
			return str(roundi(v))
		"pct":
			return "%d%%" % roundi(v * 100.0)
	var uma_casa := snappedf(v, 0.1)
	if is_equal_approx(uma_casa, roundf(uma_casa)):
		return str(roundi(uma_casa))
	return ("%.1f" % uma_casa).replace(".", ",")


## Preenche os marcadores [code]{...}[/code] de [param texto] para a [param escala] de raridade
## (ex.: Comum = 1,0, Rara = 1,5, Épica = 2,0; AC-41).
static func preencher(
	texto: String,
	efeitos: Array[EffectDef],
	escala: float = 1.0,
	status_tuning: StatusTuning = null
) -> String:
	_preparar()
	var resultado := texto
	var matches := _re_marcador.search_all(texto)
	for i in range(matches.size() - 1, -1, -1):
		var m := matches[i]
		var corpo := m.get_string(1)
		var partes := corpo.split(":")
		var campo := partes[0]
		var fmt := partes[1] if partes.size() > 1 else "num"
		var val := _obter_valor_marcador(campo, efeitos, escala, status_tuning)
		var subst := formatar(val, fmt)
		resultado = resultado.substr(0, m.get_start()) + subst + resultado.substr(m.get_end())
	return resultado


static func _obter_valor_marcador(
	campo: String,
	efeitos: Array[EffectDef],
	escala: float,
	status_tuning: StatusTuning
) -> float:
	if campo.begins_with("status."):
		var p := campo.split(".")
		if p.size() == 3 and status_tuning != null and (StringName(p[2]) in status_tuning):
			return float(status_tuning.get(StringName(p[2])))
		return 0.0
	if campo.contains("."):
		var tipo := StringName(campo.get_slice(".", 0))
		var nome := campo.get_slice(".", 1)
		for e in efeitos:
			if e.tipo == tipo:
				if nome == "valor":
					return e.valor * (escala if e.escala_com_raridade else 1.0)
				return float(e.params.get(StringName(nome), 0.0))
		return 0.0
	if efeitos.is_empty():
		return 0.0
	var ef := efeitos[0]
	if campo == "valor":
		return ef.valor * (escala if ef.escala_com_raridade else 1.0)
	return float(ef.params.get(StringName(campo), 0.0))


static func _preparar() -> void:
	if _re_marcador == null:
		_re_marcador = RegEx.create_from_string("\\{([^{}]*)\\}")
		_re_digito = RegEx.create_from_string("[0-9]+")
