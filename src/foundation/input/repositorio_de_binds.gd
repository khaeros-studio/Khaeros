class_name RepositorioDeBinds
extends RefCounted
## Arquivo `user://input_binds.cfg` dos binds do usuário (GDD input-e-controle R8, Edge Cases › Remapeamento e
## emenda Pactos; ADR-0006 §6; ADR-0013). Todo acesso a disco passa pelo `ArmazemDeArquivos` injetado; aqui só
## se usa `ConfigFile.parse`/`encode_to_text` em memória.
##
## Formato: `[meta] schema_version = 1`; seções `[teclado]` e `[gamepad]` com `chave = [{"tipo", "codigo"}, …]`
## (até 3, primário primeiro); `[opcoes] trocar_analogicos = bool`. Nada de `InputEvent`, ids de gamepads
## conectados nem scripts.
##
## Carregar: chave desconhecida é ignorada; chave ausente recebe o padrão (`troca` ausente segue a migração da
## emenda Pactos); entrada conhecida inválida ou mapa que não passa em `TransacaoDeRemapeamento.validar` torna o
## arquivo inválido — padrões, aviso `INPUT_BINDS_CORROMPIDOS` uma vez por sessão e cópia byte a byte em `.bak`
## (ou `.bak2`, `.bak3`… sem apagar backup). Se a cópia falhar, a sessão segue com os padrões e `salvar` recusa,
## para nunca sobrescrever sem guardar. Versão futura: padrões em memória, arquivo preservado e não regravado.
## Gravar só por `salvar`, chamado pelo `Main` fora de JOGO (o gatilho da UI só marca pendência).

## Versão do formato suportada.
const VERSAO := 1
## Aviso de arquivo corrompido (R8).
const AVISO_CORROMPIDO := &"INPUT_BINDS_CORROMPIDOS"
## Aviso de ação nova recebida na migração (emenda Pactos).
const AVISO_ACAO_NOVA := &"INPUT_ACAO_NOVA"

const _SECAO_META := "meta"
const _CHAVE_VERSAO := "schema_version"
const _SECAO_OPCOES := "opcoes"
const _CHAVE_TROCAR := "trocar_analogicos"
const _SUFIXO_BAK := ".bak"

## Lista de binds livres para `troca` num arquivo antigo, por família (Edge Cases, emenda Pactos).
const _CANDIDATOS_TROCA: Dictionary = {
	&"teclado": [{"tipo": &"tecla_fisica", "codigo": KEY_R}, {"tipo": &"tecla_fisica", "codigo": KEY_TAB},
			{"tipo": &"tecla_fisica", "codigo": KEY_G}, {"tipo": &"tecla_fisica", "codigo": KEY_C}],
	&"gamepad": [{"tipo": &"gatilho", "codigo": JOY_AXIS_TRIGGER_LEFT},
			{"tipo": &"botao_gamepad", "codigo": JOY_BUTTON_DPAD_DOWN},
			{"tipo": &"botao_gamepad", "codigo": JOY_BUTTON_DPAD_LEFT}],
}
const _TIPOS_DA_FAMILIA: Dictionary = {
	&"teclado": [&"tecla_fisica", &"mouse"],
	&"gamepad": [&"botao_gamepad", &"gatilho"],
}

var _armazem: ArmazemDeArquivos
var _caminho: String
var _avisar: Callable
var _avisos_emitidos: Dictionary = {}
var _sem_gravacao: bool = false
var _versao_futura: bool = false


## `caminho`: `CaminhosDePersistencia.input_binds`. `avisar(chave: StringName)` mostra os avisos `INPUT_*`.
func _init(armazem: ArmazemDeArquivos, caminho: String, avisar: Callable = Callable()) -> void:
	_armazem = armazem
	_caminho = caminho
	_avisar = avisar


## `true` se a gravação está bloqueada (o `.bak` do arquivo ruim não pôde ser preservado).
func sem_gravacao() -> bool:
	return _sem_gravacao


## `true` se o arquivo é de uma versão futura (padrões em memória; nada é regravado automaticamente).
func versao_futura() -> bool:
	return _versao_futura


## Lê o arquivo e devolve sempre um mapa utilizável (o do usuário ou os padrões).
func carregar() -> MapaDeBinds:
	_versao_futura = false
	var leitura := _armazem.ler_texto(_caminho)
	if not leitura.existe:
		return MapaDeBinds.padrao()
	if not leitura.ok:
		return _tratar_corrompido()
	var cf := ConfigFile.new()
	if leitura.texto.strip_edges().is_empty() or cf.parse(leitura.texto) != OK:
		return _tratar_corrompido()
	if not cf.has_section_key(_SECAO_META, _CHAVE_VERSAO):
		return _tratar_corrompido()
	var versao: Variant = cf.get_value(_SECAO_META, _CHAVE_VERSAO)
	if typeof(versao) != TYPE_INT or int(versao) < 1:
		return _tratar_corrompido()
	if int(versao) > VERSAO:
		_versao_futura = true
		return MapaDeBinds.padrao()

	var trocar: Variant = cf.get_value(_SECAO_OPCOES, _CHAVE_TROCAR, false)
	if typeof(trocar) != TYPE_BOOL:
		return _tratar_corrompido()
	var padrao := BindsPadrao.mapa()
	var binds: Dictionary = {}
	var troca_nova: Array[StringName] = []
	for familia: StringName in padrao:
		var por_chave: Dictionary = {}
		for chave: StringName in (padrao[familia] as Dictionary):
			var secao := String(familia)
			if not cf.has_section_key(secao, String(chave)):
				if chave == Acoes.TROCA:
					troca_nova.append(familia)
				else:
					por_chave[chave] = (padrao[familia][chave] as Array).duplicate(true)
				continue
			var lista: Variant = _lista_valida(familia, cf.get_value(secao, String(chave)))
			if lista == null:
				return _tratar_corrompido()
			por_chave[chave] = lista
		binds[familia] = por_chave
	for familia: StringName in troca_nova:
		(binds[familia] as Dictionary)[Acoes.TROCA] = _binds_da_troca(familia, binds[familia], padrao[familia])
	var mapa := MapaDeBinds.de_dicionario(binds, bool(trocar))
	if TransacaoDeRemapeamento.validar(mapa) != &"":
		return _tratar_corrompido()
	if not troca_nova.is_empty():
		_emitir_aviso(AVISO_ACAO_NOVA)
	return mapa


## Grava o mapa (gravação atômica do armazém). Devolve o `Error`: a UI mostra a mensagem própria de falha,
## sem fingir persistência. Recusa (`ERR_FILE_CANT_WRITE`) quando o `.bak` do arquivo ruim não foi preservado.
func salvar(mapa: MapaDeBinds) -> Error:
	if _sem_gravacao:
		return ERR_FILE_CANT_WRITE
	if TransacaoDeRemapeamento.validar(mapa) != &"":
		return ERR_INVALID_DATA
	return _armazem.gravar_atomico(_caminho, texto_de(mapa))


## Texto do arquivo para um mapa (formato acima).
static func texto_de(mapa: MapaDeBinds) -> String:
	var cf := ConfigFile.new()
	cf.set_value(_SECAO_META, _CHAVE_VERSAO, VERSAO)
	for familia: StringName in mapa.binds:
		var por_chave: Dictionary = mapa.binds[familia]
		for chave: StringName in por_chave:
			var lista: Array = []
			for bind: Dictionary in por_chave[chave]:
				lista.append({"tipo": String(bind.get("tipo", "")), "codigo": int(bind.get("codigo", 0))})
			cf.set_value(String(familia), String(chave), lista)
	cf.set_value(_SECAO_OPCOES, _CHAVE_TROCAR, mapa.trocar_analogicos)
	return cf.encode_to_text()


func _lista_valida(familia: StringName, valor: Variant) -> Variant:
	if typeof(valor) != TYPE_ARRAY:
		return null
	var entrada: Array = valor
	if entrada.is_empty() or entrada.size() > MapaDeBinds.MAX_BINDS:
		return null
	var saida: Array = []
	for item: Variant in entrada:
		if typeof(item) != TYPE_DICTIONARY:
			return null
		var tipo: Variant = (item as Dictionary).get("tipo")
		var codigo: Variant = (item as Dictionary).get("codigo")
		if (typeof(tipo) != TYPE_STRING and typeof(tipo) != TYPE_STRING_NAME) or typeof(codigo) != TYPE_INT:
			return null
		if not (_TIPOS_DA_FAMILIA[familia] as Array).has(StringName(tipo)):
			return null
		saida.append({"tipo": StringName(tipo), "codigo": int(codigo)})
	return saida


## `troca` ausente num arquivo antigo: o padrão, se o primário estiver livre no contexto Jogo; senão o primeiro
## livre da lista do GDD, sem tirar bind de ninguém.
func _binds_da_troca(familia: StringName, por_chave: Dictionary, padrao_familia: Dictionary) -> Array:
	var ocupados: Dictionary = {}
	for chave: StringName in por_chave:
		if Acoes.existe_no_contexto(Acoes.acao_da_chave(chave), Acoes.CONTEXTO_JOGO):
			for bind: Dictionary in por_chave[chave]:
				ocupados[MapaDeBinds.logica(bind)] = true
	var padrao_troca: Array = padrao_familia.get(Acoes.TROCA, [])
	if not padrao_troca.is_empty() and not ocupados.has(MapaDeBinds.logica(padrao_troca[0])):
		var livres: Array = []
		for bind: Dictionary in padrao_troca:
			if not ocupados.has(MapaDeBinds.logica(bind)):
				livres.append(bind.duplicate())
		return livres
	for bind: Dictionary in _CANDIDATOS_TROCA.get(familia, []):
		if not ocupados.has(MapaDeBinds.logica(bind)):
			return [bind.duplicate()]
	return []


func _tratar_corrompido() -> MapaDeBinds:
	_emitir_aviso(AVISO_CORROMPIDO)
	if _armazem.copiar_bytes(_caminho, _nome_de_backup_livre()) != OK:
		_sem_gravacao = true
	return MapaDeBinds.padrao()


func _nome_de_backup_livre() -> String:
	var candidato := _caminho + _SUFIXO_BAK
	var n := 1
	while _armazem.existe(candidato):
		n += 1
		candidato = _caminho + _SUFIXO_BAK + str(n)
	return candidato


func _emitir_aviso(chave: StringName) -> void:
	if _avisos_emitidos.has(chave):
		return
	_avisos_emitidos[chave] = true
	if _avisar.is_valid():
		_avisar.call(chave)
