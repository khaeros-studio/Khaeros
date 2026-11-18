class_name EsquemaDeDefinicao
extends RefCounted
## Esquema declarativo de uma classe de conteúdo (GDD de Conteúdo R9 "Regras por
## campo"; ADR-0004 §Validação). Guarda, por campo: tipo, obrigatoriedade, limites,
## se aceita zero, se o default do script é permitido, referências (a outro tipo do
## catálogo ou a um registro de chaves dos donos), e marcações de chave de texto,
## descrição com marcadores, arte e tabela de peso. Guarda também a lista fixa de
## regras entre campos. Não contém as regras V1–V11: os validadores leem só isto.
##
## Não é thread-safe (cache estático); use na thread principal.
##
## Campo ausente × default do script: depois de materializado, um [Resource] não
## revela se o campo foi gravado. Por isso [method campos_ausentes] compara contra a
## lista de campos efetivamente gravados no arquivo de origem, obtida na etapa de
## preparo ([method campos_gravados_no_texto]).
##
## Exemplo:
## [codeblock]
## var e := EnemyDef.new().esquema()
## var faltando := e.campos_ausentes(EsquemaDeDefinicao.campos_gravados_no_texto(texto_tres))
## [/codeblock]


## Regra declarativa de um campo.
class RegraDeCampo:
	extends RefCounted
	var nome: StringName
	## [enum Variant.Type] do campo.
	var tipo: int = TYPE_NIL
	## Dica de classe/tipo de elemento vinda do [code]@export[/code].
	var dica: String = ""
	var obrigatorio: bool = true
	## Ausente no arquivo, mas o default do script é aceito (não é erro V1).
	var default_permitido: bool = false
	var tem_minimo: bool = false
	var minimo: float = 0.0
	var minimo_exclusivo: bool = false
	var tem_maximo: bool = false
	var maximo: float = 0.0
	var maximo_exclusivo: bool = false
	var aceita_zero: bool = true
	## Tipo do catálogo para o qual o valor (ou cada elemento/chave) aponta (V4).
	var ref_tipo: StringName = &""
	## Registro de chaves de um dono para o qual o valor aponta (V4).
	var ref_registro: StringName = &""
	## Chave de tradução (V6).
	var chave_texto: bool = false
	## Chave cujo texto tem marcadores R7 (V6 + V10).
	var descricao: bool = false
	## Sufixos de chaves derivadas também conferidas na V6 (ex.: [code]"_DESC"[/code]).
	var sufixos_derivados: PackedStringArray = PackedStringArray()
	## Caminho de arte (V7).
	var arte: bool = false
	## Tabela de peso (V8).
	var pesos: bool = false

	## Marca o campo como opcional (pode faltar e pode ficar vazio).
	func opcional() -> RegraDeCampo:
		obrigatorio = false
		default_permitido = true
		return self

	## Obrigatório, mas o default do script é um valor válido quando o campo falta.
	func aceita_default() -> RegraDeCampo:
		default_permitido = true
		return self

	## Faixa inclusiva [mn, mx].
	func faixa(mn: float, mx: float) -> RegraDeCampo:
		tem_minimo = true
		minimo = mn
		tem_maximo = true
		maximo = mx
		return self

	## Alias de [method faixa] usado por classes de áudio.
	func intervalo(mn: float, mx: float) -> RegraDeCampo:
		return faixa(mn, mx)

	## Mínimo inclusivo.
	func min_incl(v: float) -> RegraDeCampo:
		tem_minimo = true
		minimo = v
		minimo_exclusivo = false
		return self

	## Mínimo exclusivo (valor tem de ser > v).
	func min_excl(v: float) -> RegraDeCampo:
		tem_minimo = true
		minimo = v
		minimo_exclusivo = true
		if is_zero_approx(v):
			aceita_zero = false
		return self

	## Máximo exclusivo (valor tem de ser < v).
	func max_excl(v: float) -> RegraDeCampo:
		tem_maximo = true
		maximo = v
		maximo_exclusivo = true
		return self

	## Zero não é aceito mesmo dentro da faixa.
	func sem_zero() -> RegraDeCampo:
		aceita_zero = false
		return self

	## Referência a ids de outro tipo do catálogo.
	func referencia_tipo(t: StringName) -> RegraDeCampo:
		ref_tipo = t
		return self

	## Referência a chaves de um registro de dono.
	func referencia_registro(r: StringName) -> RegraDeCampo:
		ref_registro = r
		return self

	## Chave de tradução, com chaves derivadas opcionais.
	func texto(sufixos: PackedStringArray = PackedStringArray()) -> RegraDeCampo:
		chave_texto = true
		sufixos_derivados = sufixos
		return self

	## Chave de descrição com marcadores (V6 e V10).
	func texto_com_marcadores() -> RegraDeCampo:
		chave_texto = true
		descricao = true
		return self

	## Caminho de arte (V7).
	func caminho_de_arte() -> RegraDeCampo:
		arte = true
		return self

	## Tabela de peso (V8).
	func tabela_de_pesos() -> RegraDeCampo:
		pesos = true
		return self


## Regra entre dois campos numéricos da mesma classe (sai como V2).
class RegraEntreCampos:
	extends RefCounted
	var campo_a: StringName
	## Um de [code]<=[/code], [code]<[/code], [code]>=[/code], [code]>[/code], ou [code]+<[/code].
	var operador: StringName
	var campo_b: StringName
	## Campo bool que, verdadeiro, dispensa a regra (ex.: [code]sem_teto[/code]); vazio = sempre vale.
	var exceto_se: StringName = &""
	## Limite numérico quando [member operador] é [code]&"+<"[/code] (ex.: [code]zm + ze < 1.0[/code]).
	var limite: float = 0.0

	func _init(a: StringName, op: StringName, b: StringName, p_exceto_se: StringName = &"", p_limite: float = 0.0) -> void:
		campo_a = a
		operador = op
		campo_b = b
		exceto_se = p_exceto_se
		limite = p_limite

	## Avalia a regra para os dois valores.
	func vale(va: float, vb: float) -> bool:
		match operador:
			&"<=":
				return va <= vb
			&"<":
				return va < vb
			&">=":
				return va >= vb
			&">":
				return va > vb
			&"+<":
				return (va + vb) < limite
		return false


static var _cache: Dictionary[Script, EsquemaDeDefinicao] = {}

## Nome da classe descrita.
var nome_da_classe: String = ""
var _regras: Array[RegraDeCampo] = []
var _por_nome: Dictionary[StringName, RegraDeCampo] = {}
var _entre: Array[RegraEntreCampos] = []


## Esquema da classe de [param dado], derivado dos [code]@export[/code] e completado
## por [method DadoDeConteudo._declarar_regras]. Cacheado por script.
static func de(dado: DadoDeConteudo) -> EsquemaDeDefinicao:
	var s: Script = dado.get_script()
	if _cache.has(s):
		return _cache[s]
	var e := EsquemaDeDefinicao.new()
	e.nome_da_classe = dado.nome_da_classe()
	for p: Dictionary in dado.get_property_list():
		var uso: int = p["usage"]
		if (uso & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0 or (uso & PROPERTY_USAGE_STORAGE) == 0:
			continue
		var r := RegraDeCampo.new()
		r.nome = StringName(p["name"])
		r.tipo = p["type"]
		r.dica = String(p["hint_string"])
		e._regras.append(r)
		e._por_nome[r.nome] = r
	dado._declarar_regras(e)
	_cache[s] = e
	return e


## Regras de todos os campos, na ordem das propriedades.
func regras() -> Array[RegraDeCampo]:
	return _regras.duplicate()


## Regra de um campo; [code]null[/code] se o campo não existe no esquema.
func regra(nome: StringName) -> RegraDeCampo:
	return _por_nome.get(nome, null)


## Nomes dos campos do esquema.
func nomes() -> PackedStringArray:
	var out := PackedStringArray()
	for r in _regras:
		out.append(String(r.nome))
	return out


## Declara uma regra entre campos ([code]a op b[/code]); [param exceto_se] nomeia um
## campo bool que, verdadeiro, dispensa a regra.
func entre(a: StringName, op: StringName, b: StringName, exceto_se: StringName = &"") -> void:
	_entre.append(RegraEntreCampos.new(a, op, b, exceto_se))


## Declara uma regra de soma entre dois campos ([code]a + b < limite[/code]).
func soma_menor_que(a: StringName, b: StringName, limite: float) -> void:
	_entre.append(RegraEntreCampos.new(a, &"+<", b, &"", limite))


## Regras entre campos declaradas.
func regras_entre_campos() -> Array[RegraEntreCampos]:
	return _entre.duplicate()


## Campos obrigatórios que não estão em [param gravados] e cujo default do script
## não é permitido. Base de V1/AC-09 (campo ausente × default do script).
func campos_ausentes(gravados: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for r in _regras:
		if r.obrigatorio and not r.default_permitido and not gravados.has(String(r.nome)):
			out.append(String(r.nome))
	return out


## Lista os nomes de propriedade gravados na seção [code][resource][/code] de um
## texto [code].tres[/code] (etapa de preparo; não usar em runtime exportado).
static func campos_gravados_no_texto(texto: String) -> PackedStringArray:
	var out := PackedStringArray()
	var na_secao := false
	for linha_bruta in texto.split("\n"):
		var linha := linha_bruta.strip_edges()
		if linha.begins_with("["):
			na_secao = linha.begins_with("[resource")
			continue
		if not na_secao or linha.is_empty():
			continue
		var igual := linha.find("=")
		if igual <= 0:
			continue
		var nome := linha.substr(0, igual).strip_edges()
		if nome.is_valid_identifier() and nome != "script" and nome != "metadata":
			out.append(nome)
	return out


## Percorre os campos de [param dado] (recursivo em sub-recursos embutidos) e chama
## [code]visitante.call(regra: RegraDeCampo, valor: Variant, caminho: String, dono: DadoDeConteudo)[/code].
static func percorrer(dado: DadoDeConteudo, visitante: Callable, prefixo: String = "") -> void:
	var e := dado.esquema()
	for r in e._regras:
		var valor: Variant = dado.get(r.nome)
		var caminho := prefixo + String(r.nome)
		visitante.call(r, valor, caminho, dado)
		if valor is DadoDeConteudo:
			percorrer(valor as DadoDeConteudo, visitante, caminho + ".")
		elif valor is Array:
			var lista: Array = valor
			for i in lista.size():
				if lista[i] is DadoDeConteudo:
					percorrer(lista[i] as DadoDeConteudo, visitante, "%s[%d]." % [caminho, i])
