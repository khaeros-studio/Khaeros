class_name ImpressaoCanonica
extends RefCounted
## Impressão canônica do catálogo (GDD de Conteúdo R12; ADR-0004 §Impressão canônica).
## Serializa só os campos do esquema ([EsquemaDeDefinicao]), ordenados por nome, na
## ordem do manifesto (tipos e definições), e calcula SHA-256 ([HashingContext]).
## Fora da entrada: metadados do editor, ids de instância, caminhos de script,
## traduções e arquivos canônicos (chaves de tradução e caminhos de arte entram como texto).
##
## Protocolo (versão [constant VERSAO_DO_FORMATO]):
## [codeblock]
## cabeçalho : ASCII "KHAEROS-CATALOG" | u32 versão | u32 nº de tipos
## por tipo  : texto(tipo) | u32 nº de definições | definições...
## definição : TAG_DEFINICAO | texto(tipo) | texto(id) | u32 nº de campos | (texto(nome), valor)*
## sub-recurso: igual a definição, com tipo = nome da classe e id vazio (expande no lugar)
## null=TAG_NULL | bool=TAG_BOOL u8 | int=TAG_INT i64 LE | float=TAG_FLOAT f64 LE (-0→0; NaN/inf erro)
## texto=TAG_TEXTO u32 bytes UTF-8 + bytes | array=TAG_ARRAY u32 n + valores
## dicionário=TAG_DICIONARIO u32 n + (texto(chave), valor)* com chaves ordenadas como texto
## [/codeblock]
## Erros de serialização (ciclo, valor fora do esquema, NaN/infinito, contagem acima de
## uint32) impedem Pronto. Não é thread-safe por instância (estado da serialização).
##
## Exemplo:
## [codeblock]
## var r := ImpressaoCanonica.calcular(catalogo)
## if r.erros.is_empty(): catalogo.definir_impressao(r.completa)
## [/codeblock]

## Versão do protocolo de bytes; muda quando a codificação mudar.
const VERSAO_DO_FORMATO: int = 1
const CABECALHO := "KHAEROS-CATALOG"
const MAX_U32: int = 0xFFFFFFFF
## Regra dos diagnósticos de serialização.
const REGRA := &"IMPRESSAO"

const TAG_NULL: int = 0x00
const TAG_BOOL: int = 0x01
const TAG_INT: int = 0x02
const TAG_FLOAT: int = 0x03
const TAG_TEXTO: int = 0x04
const TAG_ARRAY: int = 0x05
const TAG_DICIONARIO: int = 0x06
const TAG_DEFINICAO: int = 0x07


## Resultado de uma impressão.
class Resultado:
	extends RefCounted
	## Bytes canônicos (vazios se houve erro).
	var bytes: PackedByteArray = PackedByteArray()
	## SHA-256 em 64 hex minúsculos; vazio se houve erro.
	var completa: String = ""
	## 4 primeiros hex em maiúsculas.
	var curta: String = ""
	var erros: Array[Diagnostico] = []


var _buf: StreamPeerBuffer
var _erros: Array[Diagnostico] = []
var _pilha: Array[int] = []
var _contexto: String = ""


## Serializa e calcula a impressão de [param catalogo] (inclui obsoletas).
static func calcular(catalogo: Catalogo) -> Resultado:
	var tipos := catalogo.tipos()
	var listas: Array = []
	for t in tipos:
		listas.append(catalogo.listar(t, true))
	return calcular_de_listas(tipos, listas)


## Igual a [method calcular], a partir de tipos e listas paralelas na ordem do manifesto.
static func calcular_de_listas(tipos: Array[StringName], listas: Array) -> Resultado:
	var s := ImpressaoCanonica.new()
	var r := Resultado.new()
	var bytes := s._serializar(tipos, listas)
	r.erros = s._erros
	if not r.erros.is_empty():
		return r
	r.bytes = bytes
	r.completa = sha256_hex(bytes)
	r.curta = r.completa.substr(0, 4).to_upper()
	return r


## SHA-256 em hex minúsculo.
static func sha256_hex(bytes: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()


## [code]true[/code] se [param n] cabe em uint32 (contagens e tamanhos).
static func cabe_em_u32(n: int) -> bool:
	return n >= 0 and n <= MAX_U32


func _serializar(tipos: Array[StringName], listas: Array) -> PackedByteArray:
	_buf = StreamPeerBuffer.new()
	_buf.big_endian = false
	_buf.put_data(CABECALHO.to_ascii_buffer())
	_u32(VERSAO_DO_FORMATO)
	_u32(tipos.size())
	for i in tipos.size():
		var lista: Array = listas[i]
		_texto(String(tipos[i]))
		_u32(lista.size())
		for d: DefinicaoBase in lista:
			_contexto = "%s %s" % [tipos[i], d.id]
			_dado(d, String(tipos[i]), String(d.id))
	return _buf.data_array


func _u32(n: int) -> void:
	if not cabe_em_u32(n):
		_erro("contagem %d acima de uint32" % n)
		return
	_buf.put_u32(n)


func _texto(s: String) -> void:
	var b := s.to_utf8_buffer()
	_u32(b.size())
	_buf.put_data(b)


func _dado(dado: DadoDeConteudo, tipo: String, id: String) -> void:
	var iid := dado.get_instance_id()
	if _pilha.has(iid):
		_erro("ciclo de sub-recursos em %s" % dado.nome_da_classe())
		return
	_pilha.append(iid)
	_buf.put_u8(TAG_DEFINICAO)
	_texto(tipo)
	_texto(id)
	var nomes := dado.esquema().nomes()
	nomes.sort()
	_u32(nomes.size())
	for n in nomes:
		_texto(n)
		_valor(dado.get(n), n)
	_pilha.pop_back()


func _valor(v: Variant, campo: String) -> void:
	match typeof(v):
		TYPE_NIL:
			_buf.put_u8(TAG_NULL)
		TYPE_BOOL:
			_buf.put_u8(TAG_BOOL)
			_buf.put_u8(1 if v else 0)
		TYPE_INT:
			_buf.put_u8(TAG_INT)
			_buf.put_64(v)
		TYPE_FLOAT:
			var f: float = v
			if is_nan(f) or is_inf(f):
				_erro("%s não finito" % campo)
				return
			if f == 0.0:
				f = 0.0
			_buf.put_u8(TAG_FLOAT)
			_buf.put_double(f)
		TYPE_STRING, TYPE_STRING_NAME:
			_buf.put_u8(TAG_TEXTO)
			_texto(String(v))
		TYPE_DICTIONARY:
			var d: Dictionary = v
			var chaves: Array[String] = []
			var por_texto: Dictionary = {}
			for k: Variant in d.keys():
				chaves.append(str(k))
				por_texto[str(k)] = k
			chaves.sort()
			_buf.put_u8(TAG_DICIONARIO)
			_u32(chaves.size())
			for k in chaves:
				_texto(k)
				_valor(d[por_texto[k]], "%s[%s]" % [campo, k])
		TYPE_OBJECT:
			if v is DadoDeConteudo:
				var sub := v as DadoDeConteudo
				_dado(sub, sub.nome_da_classe(), "")
			else:
				_erro("%s: objeto fora do esquema" % campo)
		_:
			if v is Array or (typeof(v) >= TYPE_PACKED_BYTE_ARRAY and typeof(v) <= TYPE_PACKED_VECTOR4_ARRAY and _packed_escalar(typeof(v))):
				var lista: Array = Array(v)
				_buf.put_u8(TAG_ARRAY)
				_u32(lista.size())
				for i in lista.size():
					_valor(lista[i], "%s[%d]" % [campo, i])
			else:
				_erro("%s: valor de tipo %s fora do esquema" % [campo, type_string(typeof(v))])


static func _packed_escalar(t: int) -> bool:
	return t in [TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY,
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY]


func _erro(msg: String) -> void:
	_erros.append(Diagnostico.novo(REGRA, "", null, "%s: %s" % [_contexto, msg]))
