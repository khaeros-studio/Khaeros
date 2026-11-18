class_name Diagnostico
extends RefCounted
## Uma entrada da validação do catálogo (ADR-0004 §Validação e diagnóstico): arquivo,
## campo, regra, valor encontrado e nível. Tipo, id e posição no manifesto dão a
## ordem estável de apresentação ([method ordenar]).
##
## Exemplo:
## [codeblock]
## var d := Diagnostico.novo(&"V2", "ataque.recarga_s", 0.0, "recarga 0 (mín. > 0)")
## d.arquivo = "res://assets/data/weapon/lamina.tres"
## print(d.texto())
## [/codeblock]

enum Nivel { ERRO, AVISO }

var arquivo: String = ""
var tipo: StringName = &""
var id: StringName = &""
## Posição da definição no manifesto (-1 = fora de uma definição, ex.: manifesto).
var posicao: int = -1
var campo: String = ""
## Código da regra (ex.: [code]&"V2"[/code], [code]&"LEITURA"[/code], [code]&"HU15"[/code]).
var regra: StringName = &""
var valor: Variant = null
var nivel: Nivel = Nivel.ERRO
var mensagem: String = ""


## Cria um diagnóstico sem contexto de arquivo.
static func novo(p_regra: StringName, p_campo: String, p_valor: Variant, p_mensagem: String, p_nivel: Nivel = Nivel.ERRO) -> Diagnostico:
	var d := Diagnostico.new()
	d.regra = p_regra
	d.campo = p_campo
	d.valor = p_valor
	d.mensagem = p_mensagem
	d.nivel = p_nivel
	return d


## Cria um diagnóstico com o contexto (arquivo, tipo, id, posição) de um item.
static func de_item(item: ItemDoCatalogo, p_regra: StringName, p_campo: String, p_valor: Variant, p_mensagem: String, p_nivel: Nivel = Nivel.ERRO) -> Diagnostico:
	var d := novo(p_regra, p_campo, p_valor, p_mensagem, p_nivel)
	d.arquivo = item.caminho
	d.tipo = item.tipo
	d.posicao = item.posicao
	if item.definicao != null:
		d.id = item.definicao.id
	return d


## [code]true[/code] se o nível é erro (bloqueia a run).
func eh_erro() -> bool:
	return nivel == Nivel.ERRO


## Alias compatível de [method eh_erro].
func e_erro() -> bool:
	return nivel == Nivel.ERRO


## [code]true[/code] se o nível é aviso.
func eh_aviso() -> bool:
	return nivel == Nivel.AVISO


## Alias compatível de [method eh_aviso].
func e_aviso() -> bool:
	return nivel == Nivel.AVISO


## Linha legível: [code][V2] erro arquivo campo: mensagem (valor: x)[/code].
func texto() -> String:
	var n := "erro" if eh_erro() else "aviso"
	return "[%s] %s %s %s: %s (valor: %s)" % [regra, n, arquivo, campo, mensagem, str(valor)]


## Número de diagnósticos de nível erro.
static func contar_erros(lista: Array[Diagnostico]) -> int:
	var n := 0
	for d in lista:
		if d.eh_erro():
			n += 1
	return n


## Devolve uma cópia ordenada por tipo (na ordem de [param ordem_tipos]), posição no
## manifesto, regra (ordem natural: V2 antes de V10) e campo.
static func ordenar(lista: Array[Diagnostico], ordem_tipos: Array[StringName]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = lista.duplicate()
	out.sort_custom(func(a: Diagnostico, b: Diagnostico) -> bool:
		var ta := ordem_tipos.find(a.tipo)
		var tb := ordem_tipos.find(b.tipo)
		if ta != tb:
			return ta < tb
		if a.posicao != b.posicao:
			return a.posicao < b.posicao
		var ra := _chave_regra(a.regra)
		var rb := _chave_regra(b.regra)
		if ra != rb:
			return ra < rb
		return a.campo < b.campo)
	return out


static func _chave_regra(r: StringName) -> String:
	var s := String(r)
	var i := 0
	while i < s.length() and not s[i].is_valid_int():
		i += 1
	var letras := s.substr(0, i)
	var numero := s.substr(i)
	if numero.is_valid_int():
		return "%s%06d" % [letras, numero.to_int()]
	return s
