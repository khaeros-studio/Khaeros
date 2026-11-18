## Repositório versionado de [code]user://perfil.cfg[/code] (ADR-0013 §3, §7; save-e-perfil R2–R9).
##
## Lógica pura sobre [ArmazemDeArquivos]: lê o texto, interpreta em memória com
## [code]ConfigFile.parse[/code] e grava [code]encode_to_text()[/code] por
## [method ArmazemDeArquivos.gravar_atomico]. A seção [code][vinculo][/code] é opaca e
## vem de uma [PortaDeSecao]. [method carregar] nunca falha; [method salvar] devolve
## [code]Error[/code] e só toca o disco se o texto mudou (R5.2). Não é thread-safe.
##
## Carga (R4): ler → (o armazém real recupera sobras) → interpretar → versão → validar
## a forma fina ([code][meta][/code], [code]especies[/code] como [code]Dictionary[/code],
## tipos permitidos) → migrar formato e conteúdo → filtrar ids → [method PortaDeSecao.ler].
## Chaves e seções desconhecidas e entradas órfãs de [code]especies[/code] são
## preservadas e regravadas (R9). Arquivo corrompido vai para [code].bak[/code]/[code].bakN[/code]
## (nunca apaga backup); se a cópia falhar, ou se a versão for futura, a sessão fica em
## [constant ModoDoPerfil.Valor.SEM_GRAVACAO].
##
## Avisos: [param avisar] é chamado com a chave ([code]&"PERFIL_CORROMPIDO"[/code],
## [code]&"PERFIL_VERSAO_FUTURA"[/code]) no máximo uma vez por sessão por chave.
##
## Exemplo:
## [codeblock]
## var r := RepositorioDePerfil.new(armazem, CaminhosDePersistencia.de(0),
##         func(chave: StringName) -> void: avisos.append(chave),
##         catalogo.ids_de_especies(), vinculo)
## var modo := r.carregar()     # chama vinculo.ler(...) exatamente uma vez
## var err := r.salvar()        # OK sem tocar o disco se nada mudou
## [/codeblock]
class_name RepositorioDePerfil
extends PerfilDaSessao

## Aviso de arquivo corrompido (UI Requirements).
const AVISO_CORROMPIDO: StringName = &"PERFIL_CORROMPIDO"
## Aviso de arquivo de versão futura (UI Requirements).
const AVISO_VERSAO_FUTURA: StringName = &"PERFIL_VERSAO_FUTURA"

const _SECAO_META: String = "meta"
const _SECAO_VINCULO: String = "vinculo"
const _CHAVE_VERSAO: String = "schema_version"
const _CHAVE_GRAVADO_POR: String = "gravado_por"
const _CHAVE_ESPECIES: String = "especies"
const _SUFIXO_BAK: String = ".bak"
const _SUFIXO_RESET_BAK: String = ".reset.bak"
# Versão assumida quando [meta] schema_version está ausente (ADR-0013 §3).
const _VERSAO_SE_AUSENTE: int = 1

enum _Resultado { OK, CORROMPIDO, VERSAO_FUTURA }

## Versão do build gravada em [code][meta] gravado_por[/code] (diagnóstico; nunca lida
## como regra). O [code]Main[/code] injeta; nada de caminho, usuário ou hora.
var gravado_por: String = ""

var _armazem: ArmazemDeArquivos
var _caminho: String
var _avisar: Callable
# id de espécie (String) → true
var _ids: Dictionary = {}
var _porta: PortaDeSecao
var _migracao: MigracaoDePerfil

var _modo: ModoDoPerfil.Valor = ModoDoPerfil.Valor.NORMAL
var _avisos_emitidos: Dictionary = {}
var _tem_texto_gravado: bool = false
var _ultimo_texto_gravado: String = ""
# Preservação (R9): órfãs de especies, chaves de [vinculo] fora de escrever(), seções desconhecidas.
var _orfas: Dictionary = {}
var _vinculo_preservado: Dictionary = {}
var _secoes_preservadas: Dictionary = {}


## [param ids_de_especies]: ids de [code]CurseDef[/code] do catálogo Pronto.
## [param migracao]: cadeia de formato; [code]null[/code] = versão do MVP sem passos.
func _init(armazem: ArmazemDeArquivos, caminhos: CaminhosDePersistencia, avisar: Callable,
		ids_de_especies: PackedStringArray, porta: PortaDeSecao,
		migracao: MigracaoDePerfil = null) -> void:
	_armazem = armazem
	_caminho = caminhos.perfil
	_avisar = avisar
	for id in ids_de_especies:
		_ids[id] = true
	_porta = porta
	_migracao = migracao if migracao != null else MigracaoDePerfil.new()


## Modo atual da sessão.
func modo() -> ModoDoPerfil.Valor:
	return _modo


## Carrega o perfil e entrega o resultado a [method PortaDeSecao.ler] exatamente uma
## vez. Nunca falha: qualquer problema vira um dos casos de R8. Não grava nada.
func carregar() -> ModoDoPerfil.Valor:
	_modo = ModoDoPerfil.Valor.NORMAL
	_tem_texto_gravado = false
	_ultimo_texto_gravado = ""
	_limpar_preservacao()
	var leitura: LeituraDeArquivo = _armazem.ler_texto(_caminho)
	if leitura.ok and not leitura.existe:
		_porta.ler({})
		return _modo
	if not leitura.ok:
		_tratar_corrompido()
		return _modo
	var processado: Dictionary = _processar_texto(leitura.texto)
	match processado["resultado"]:
		_Resultado.CORROMPIDO:
			_tratar_corrompido()
		_Resultado.VERSAO_FUTURA:
			_modo = ModoDoPerfil.Valor.SEM_GRAVACAO
			_emitir_aviso(AVISO_VERSAO_FUTURA)
			_porta.ler({})
		_:
			_orfas = processado["orfas"]
			_vinculo_preservado = processado["vinculo_preservado"]
			_secoes_preservadas = processado["secoes_preservadas"]
			_tem_texto_gravado = true
			_ultimo_texto_gravado = leitura.texto
			_porta.ler(processado["dados"])
	return _modo


## Grava o estado atual se o texto mudou desde a última gravação com sucesso (R5.2).
## [constant ERR_UNAVAILABLE] em Sem gravação; [constant ERR_INVALID_DATA] se
## [method PortaDeSecao.escrever] devolveu tipo proibido (nada é gravado); senão o
## [code]Error[/code] de [method ArmazemDeArquivos.gravar_atomico]. Em falha o estado
## em memória continua valendo; sem nova tentativa.
func salvar() -> Error:
	if _modo == ModoDoPerfil.Valor.SEM_GRAVACAO:
		return ERR_UNAVAILABLE
	var dados: Dictionary = _porta.escrever()
	if not _tipos_permitidos(dados):
		return ERR_INVALID_DATA
	var texto: String = _montar_texto(dados)
	if _tem_texto_gravado and texto == _ultimo_texto_gravado:
		return OK
	var err: Error = _armazem.gravar_atomico(_caminho, texto)
	if err == OK:
		_tem_texto_gravado = true
		_ultimo_texto_gravado = texto
	return err


## Texto que seria gravado agora (diagnóstico e testes; não toca o disco).
func texto_atual() -> String:
	return _montar_texto(_porta.escrever())


## Porta de exportar (R12): o texto que seria gravado agora, com órfãs e seções
## preservadas. Não toca o disco. Fragmentos e RNG não entram (ADR-0013 §6).
## Exemplo: [code]var t := repo_a.exportar_texto(); repo_b.importar_texto(t)[/code]
func exportar_texto() -> String:
	return texto_atual()


## Porta de importar (R12): mesma validação da carga (R4–R9). [constant OK] → a porta
## recebe [code]ler(dados)[/code] e as órfãs/seções do texto passam a ser preservadas;
## a próxima gravação regrava se o texto mudou. Texto corrompido →
## [constant ERR_PARSE_ERROR]; versão futura → [constant ERR_FILE_UNRECOGNIZED]; em
## erro nada muda (nem a porta, nem a preservação). Não emite aviso nem toca o disco.
func importar_texto(texto: String) -> Error:
	var processado: Dictionary = _processar_texto(texto)
	match processado["resultado"]:
		_Resultado.CORROMPIDO:
			return ERR_PARSE_ERROR
		_Resultado.VERSAO_FUTURA:
			return ERR_FILE_UNRECOGNIZED
	_orfas = processado["orfas"]
	_vinculo_preservado = processado["vinculo_preservado"]
	_secoes_preservadas = processado["secoes_preservadas"]
	_porta.ler(processado["dados"])
	return OK


## Reset (R11): se [code]perfil.cfg[/code] existe, copia byte a byte para
## [code]perfil.cfg.reset.bak[/code] (ou [code].reset.bak2[/code]…; nunca apaga backup);
## se a cópia falhar devolve o erro e nada muda ([code]ler()[/code] não é chamado).
## Depois descarta órfãs, chaves e seções preservadas e chama [code]ler({})[/code].
## Não grava: quem chama marca o perfil pendente. Só toca [code]perfil.cfg*[/code].
## [constant ERR_UNAVAILABLE] em Sem gravação.
func resetar() -> Error:
	if _modo == ModoDoPerfil.Valor.SEM_GRAVACAO:
		return ERR_UNAVAILABLE
	if _armazem.existe(_caminho):
		var err: Error = _armazem.copiar_bytes(_caminho, _nome_de_backup_livre(_SUFIXO_RESET_BAK))
		if err != OK:
			return err
	_limpar_preservacao()
	_porta.ler({})
	return OK


# --- carga -------------------------------------------------------------------

# Interpreta, valida, migra e filtra. Devolve {resultado, dados, orfas,
# vinculo_preservado, secoes_preservadas}.
func _processar_texto(texto: String) -> Dictionary:
	var saida: Dictionary = {"resultado": _Resultado.CORROMPIDO}
	if texto.strip_edges().is_empty():
		return saida
	var cf := ConfigFile.new()
	if cf.parse(texto) != OK:
		return saida
	var secoes: PackedStringArray = cf.get_sections()
	# ConfigFile.parse aceita lixo sem seções (E-P3, 2026-11-16): "%%lixo" dá OK e
	# nenhuma seção. Chaves fora de seção (seção "") também não são formato nosso.
	if secoes.is_empty() or secoes.has(""):
		return saida
	var documento: Dictionary = {}
	for s in secoes:
		var secao: Dictionary = {}
		for k in cf.get_section_keys(s):
			secao[k] = cf.get_value(s, k)
		documento[s] = secao
	# [meta]
	var versao: int = _VERSAO_SE_AUSENTE
	var meta: Dictionary = documento.get(_SECAO_META, {})
	if meta.has(_CHAVE_VERSAO):
		var v: Variant = meta[_CHAVE_VERSAO]
		if typeof(v) != TYPE_INT or int(v) < 1:
			return saida
		versao = v
	if meta.has(_CHAVE_GRAVADO_POR) and typeof(meta[_CHAVE_GRAVADO_POR]) != TYPE_STRING:
		return saida
	if versao > _migracao.versao_suportada:
		saida["resultado"] = _Resultado.VERSAO_FUTURA
		return saida
	if not _vinculo_valido(documento):
		return saida
	# migração de formato (cadeia do Save) e de conteúdo (dono da seção)
	if versao < _migracao.versao_suportada:
		if not _migracao.pode_migrar(versao):
			return saida
		documento = _migracao.migrar(versao, documento)
		if not _vinculo_valido(documento):
			return saida
	var vinculo: Dictionary = documento.get(_SECAO_VINCULO, {})
	if not vinculo.is_empty():
		vinculo = _porta.migrar_conteudo(versao, vinculo.duplicate(true))
		if not _vinculo_valido({_SECAO_VINCULO: vinculo}):
			return saida
	# preservação e filtro de ids (R9)
	var secoes_preservadas: Dictionary = {}
	for s in documento.keys():
		if s != _SECAO_META and s != _SECAO_VINCULO:
			secoes_preservadas[s] = (documento[s] as Dictionary).duplicate(true)
	var vinculo_preservado: Dictionary = vinculo.duplicate(true)
	vinculo_preservado.erase(_CHAVE_ESPECIES)
	var orfas: Dictionary = {}
	var dados: Dictionary = {}
	if not vinculo.is_empty():
		dados = vinculo.duplicate(true)
		var especies: Dictionary = dados[_CHAVE_ESPECIES]
		for id in especies.keys():
			if not _ids.has(id):
				orfas[id] = especies[id]
				especies.erase(id)
		for campo in _porta.campos_de_ids():
			if dados.has(campo) and typeof(dados[campo]) == TYPE_ARRAY:
				dados[campo] = _filtrar_ids(dados[campo])
	saida["resultado"] = _Resultado.OK
	saida["dados"] = dados
	saida["orfas"] = orfas
	saida["vinculo_preservado"] = vinculo_preservado
	saida["secoes_preservadas"] = secoes_preservadas
	return saida


# [vinculo] ausente é válido; presente exige especies:Dictionary e só tipos permitidos.
func _vinculo_valido(documento: Dictionary) -> bool:
	if not documento.has(_SECAO_VINCULO):
		return true
	var vinculo: Dictionary = documento[_SECAO_VINCULO]
	if vinculo.is_empty():
		return true
	if typeof(vinculo.get(_CHAVE_ESPECIES)) != TYPE_DICTIONARY:
		return false
	return _tipos_permitidos(vinculo)


func _filtrar_ids(ids: Array) -> Array:
	var saida: Array = []
	for item in ids:
		if typeof(item) == TYPE_STRING and item != "" and not _ids.has(item):
			saida.append("")
		else:
			saida.append(item)
	return saida


func _tratar_corrompido() -> void:
	_emitir_aviso(AVISO_CORROMPIDO)
	var destino: String = _nome_de_backup_livre(_SUFIXO_BAK)
	if _armazem.copiar_bytes(_caminho, destino) != OK:
		_modo = ModoDoPerfil.Valor.SEM_GRAVACAO
	_porta.ler({})


# perfil.cfg<sufixo>, depois <sufixo>2, <sufixo>3… (nunca apaga nem sobrescreve backup).
func _nome_de_backup_livre(sufixo: String) -> String:
	var candidato: String = _caminho + sufixo
	var n: int = 1
	while _armazem.existe(candidato):
		n += 1
		candidato = _caminho + sufixo + str(n)
	return candidato


func _emitir_aviso(chave: StringName) -> void:
	if _avisos_emitidos.has(chave):
		return
	_avisos_emitidos[chave] = true
	if _avisar.is_valid():
		_avisar.call(chave)


func _limpar_preservacao() -> void:
	_orfas = {}
	_vinculo_preservado = {}
	_secoes_preservadas = {}


# --- escrita -----------------------------------------------------------------

# [meta] + [vinculo] (preservado ⊕ escrever(); órfãs ⊕ especies) + seções preservadas,
# chaves ordenadas para o texto ser idêntico byte a byte entre gravações iguais.
func _montar_texto(dados: Dictionary) -> String:
	var cf := ConfigFile.new()
	cf.set_value(_SECAO_META, _CHAVE_VERSAO, _migracao.versao_suportada)
	cf.set_value(_SECAO_META, _CHAVE_GRAVADO_POR, gravado_por)
	var vinculo: Dictionary = _vinculo_preservado.duplicate(true)
	for chave in dados.keys():
		vinculo[chave] = dados[chave]
	if not vinculo.is_empty() or not _orfas.is_empty():
		var especies: Dictionary = _orfas.duplicate(true)
		var proprias: Variant = dados.get(_CHAVE_ESPECIES, {})
		if typeof(proprias) == TYPE_DICTIONARY:
			for id in (proprias as Dictionary).keys():
				especies[id] = proprias[id]
		vinculo[_CHAVE_ESPECIES] = especies
		_escrever_secao(cf, _SECAO_VINCULO, vinculo)
	var nomes: Array = _secoes_preservadas.keys()
	nomes.sort()
	for s in nomes:
		_escrever_secao(cf, s, _secoes_preservadas[s])
	return cf.encode_to_text()


func _escrever_secao(cf: ConfigFile, secao: String, valores: Dictionary) -> void:
	var chaves: Array = valores.keys()
	chaves.sort()
	for k in chaves:
		cf.set_value(secao, k, _canonico(valores[k]))


# Cópia com chaves de Dictionary em ordem (determinismo além do var_to_str).
func _canonico(valor: Variant) -> Variant:
	match typeof(valor):
		TYPE_DICTIONARY:
			var d: Dictionary = valor
			var chaves: Array = d.keys()
			chaves.sort()
			var saida: Dictionary = {}
			for k in chaves:
				saida[k] = _canonico(d[k])
			return saida
		TYPE_ARRAY:
			var saida_a: Array = []
			for item in (valor as Array):
				saida_a.append(_canonico(item))
			return saida_a
		_:
			return valor


# bool, int, String e Array/Dictionary (chaves String) desses (R3).
func _tipos_permitidos(valor: Variant) -> bool:
	match typeof(valor):
		TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_ARRAY:
			for item in (valor as Array):
				if not _tipos_permitidos(item):
					return false
			return true
		TYPE_DICTIONARY:
			var d: Dictionary = valor
			for k in d.keys():
				if typeof(k) != TYPE_STRING or not _tipos_permitidos(d[k]):
					return false
			return true
		_:
			return false
