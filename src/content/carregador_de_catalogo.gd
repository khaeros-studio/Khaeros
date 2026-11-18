class_name CarregadorDeCatalogo
extends RefCounted
## Carregador síncrono do catálogo (GDD de Conteúdo R4, R9; ADR-0004 §Carga e
## publicação; story 009 §Recarga). Roda na thread principal, antes do menu.
## Estados: Não carregado → Carregando → Validando → Pronto ou Falhou. Lê o manifesto
## e as definições na ordem gravada; falha de um arquivo é registrada e a leitura
## segue; coleta todos os erros juntos. Publica o catálogo só com zero erros (avisos
## não bloqueiam).
##
## É o ÚNICO ponto de [code]src/[/code] que abre caminhos de [code]assets/data[/code]
## (AC-24), através de [CarregadorDeCatalogo.Leitor]. Não é thread-safe.
## Calcula a impressão canônica ao publicar ([ImpressaoCanonica]) e suporta recarga
## em debug fora de run com [constant ResourceLoader.CACHE_MODE_IGNORE_DEEP] (story 009).
##
## Exemplo:
## [codeblock]
## var c := CarregadorDeCatalogo.new(validador, RelatorPadrao.new())
## if c.carregar():
##     var catalogo := c.catalogo()
## else:
##     for d in c.diagnosticos(): print(d.texto())
## [/codeblock]

enum Estado { NAO_CARREGADO, CARREGANDO, VALIDANDO, PRONTO, FALHOU }

## Caminho do manifesto real.
const CAMINHO_MANIFESTO := "res://assets/data/content_catalog.tres"
## Regra dos erros de leitura (arquivo/manifesto ausente ou ilegível).
const REGRA_LEITURA := &"LEITURA"
## Regra de avisos de recarga recusada (story 009).
const REGRA_RECARGA := &"RECARGA"


## Acesso a arquivos do catálogo. O padrão usa [ResourceLoader] síncrono
## (EX-0004-NV: modo threaded só se a medição justificar). Testes injetam dublês.
class Leitor:
	extends RefCounted
	## Contador de leituras sem cache (útil para testes de AC-05).
	var leituras_sem_cache: int = 0
	## Último modo de cache usado na leitura sem cache.
	var ultimo_modo_cache: int = -1

	## O recurso existe.
	func existe(caminho: String) -> bool:
		return ResourceLoader.exists(caminho)

	## Carrega o recurso (null se falhar).
	func carregar(caminho: String) -> Resource:
		return ResourceLoader.load(caminho)

	## Carrega o recurso ignorando o cache profundo ([constant ResourceLoader.CACHE_MODE_IGNORE_DEEP]).
	func carregar_sem_cache(caminho: String) -> Resource:
		leituras_sem_cache += 1
		ultimo_modo_cache = ResourceLoader.CACHE_MODE_IGNORE_DEEP
		if get_script() != CarregadorDeCatalogo.Leitor:
			return carregar(caminho)
		return ResourceLoader.load(caminho, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)

	## [code]true[/code] se este leitor sabe quais campos foram gravados (preparo).
	func conhece_presenca() -> bool:
		return false

	## Campos gravados no arquivo de origem (só quando [method conhece_presenca]).
	func campos_gravados(_caminho: String) -> PackedStringArray:
		return PackedStringArray()


var _estado: Estado = Estado.NAO_CARREGADO
var _validador: ValidadorDeCatalogo
var _relator: RelatorDeErros
var _leitor: Leitor
var _segunda_passada: SegundaPassada = null
var _diagnosticos: Array[Diagnostico] = []
var _catalogo: Catalogo = null
var _itens: Array[ItemDoCatalogo] = []
## Passo de física conferido na carga (AC-19); -1 = ler [member Engine.physics_ticks_per_second].
var _ticks_por_segundo: int = -1
var _consumidores: Array[ConsumidorDeAjustes] = []
var _consulta_em_run: Callable = Callable()
var _debug_build: bool = OS.is_debug_build()


## [param validador] roda a primeira passada; [param relator] vai para o catálogo
## publicado; [param leitor] nulo = [ResourceLoader]; [param p_quarto] pode ser
## [SegundaPassada] ou [code]ticks_por_segundo[/code] ([int]); [param p_ticks] é o
## passo de física quando [param p_quarto] é [SegundaPassada].
func _init(
	validador: ValidadorDeCatalogo,
	relator: RelatorDeErros,
	leitor: Leitor = null,
	p_quarto: Variant = -1,
	p_ticks: int = -1
) -> void:
	_validador = validador
	_relator = relator
	_leitor = leitor if leitor != null else Leitor.new()
	if p_quarto is SegundaPassada:
		_segunda_passada = p_quarto as SegundaPassada
		_ticks_por_segundo = p_ticks
	elif typeof(p_quarto) == TYPE_INT:
		_ticks_por_segundo = int(p_quarto)


## Registra a segunda passada dos donos (opcional se já passada no construtor).
func definir_segunda_passada(sp: SegundaPassada) -> void:
	_segunda_passada = sp


## Registra um consumidor persistente de ajustes (ex.: adaptador de [code]InputPorPasso[/code]).
## Se o catálogo já estiver em [code]PRONTO[/code], injeta os ajustes imediatamente.
func registrar_consumidor(consumidor: ConsumidorDeAjustes) -> void:
	if consumidor == null or _consumidores.has(consumidor):
		return
	_consumidores.append(consumidor)
	if _estado == Estado.PRONTO and _catalogo != null:
		consumidor.receber_ajustes(_catalogo)


## Define a consulta booleana [code]func() -> bool[/code] que informa se há run ativa.
func definir_consulta_em_run(consulta: Callable) -> void:
	_consulta_em_run = consulta


## Sobrescreve a detecção de build de debug (para testes de recarga em release).
func definir_debug_build(ativo: bool) -> void:
	_debug_build = ativo


## Carrega e valida o catálogo. [code]true[/code] = Pronto.
func carregar(caminho_manifesto: String = CAMINHO_MANIFESTO) -> bool:
	return _executar_carga(caminho_manifesto, false)


## Recarrega o catálogo do zero usando [constant ResourceLoader.CACHE_MODE_IGNORE_DEEP]
## (story 009, AC-05, AC-06, AC-47). Só opera em build de debug e fora de run;
## em run ou em release, recusa com aviso e preserva o catálogo atual em [code]PRONTO[/code].
func recarregar(caminho_manifesto: String = CAMINHO_MANIFESTO) -> bool:
	if not _debug_build:
		var aviso := Diagnostico.novo(
			REGRA_RECARGA,
			"",
			caminho_manifesto,
			"recarga recusada: indisponível em build de release",
			Diagnostico.Nivel.AVISO
		)
		aviso.arquivo = caminho_manifesto
		_diagnosticos.append(aviso)
		return false
	if _consulta_em_run.is_valid() and bool(_consulta_em_run.call()):
		var aviso := Diagnostico.novo(
			REGRA_RECARGA,
			"",
			caminho_manifesto,
			"recarga recusada: partida em andamento",
			Diagnostico.Nivel.AVISO
		)
		aviso.arquivo = caminho_manifesto
		_diagnosticos.append(aviso)
		return false
	return _executar_carga(caminho_manifesto, true)


func _executar_carga(caminho_manifesto: String, ignorar_cache: bool) -> bool:
	var estava_pronto := (_estado == Estado.PRONTO)
	_estado = Estado.CARREGANDO
	_diagnosticos = []
	_catalogo = null
	_itens = []
	if estava_pronto or ignorar_cache:
		for c in _consumidores:
			c.revogar_ajustes()
	var ticks := _ticks_por_segundo if _ticks_por_segundo >= 0 else Engine.physics_ticks_per_second
	var erro_ticks := Unidades.verificar_tick_rate(ticks)
	if erro_ticks != null:
		_diagnosticos.append(erro_ticks)
	if not _leitor.existe(caminho_manifesto):
		_falha_de_leitura(caminho_manifesto, "manifesto não encontrado: %s" % caminho_manifesto)
		return _concluir([])
	var recurso_manifesto := _ler_recurso(caminho_manifesto, ignorar_cache)
	var manifesto := recurso_manifesto as ManifestoDoCatalogo
	if manifesto == null:
		_falha_de_leitura(caminho_manifesto, "manifesto inválido: %s" % caminho_manifesto)
		return _concluir([])
	var ordem_tipos: Array[StringName] = []
	if manifesto.tipos.size() != manifesto.caminhos.size():
		_falha_de_leitura(
			caminho_manifesto,
			"manifesto com %d tipos e %d caminhos" % [manifesto.tipos.size(), manifesto.caminhos.size()]
		)
	for i in manifesto.tamanho():
		var tipo := manifesto.tipos[i]
		var caminho := manifesto.caminhos[i]
		if not ordem_tipos.has(tipo):
			ordem_tipos.append(tipo)
		if not _leitor.existe(caminho):
			_falha_de_leitura(caminho, "arquivo não encontrado: %s" % caminho, tipo, i)
			continue
		var recurso := _ler_recurso(caminho, ignorar_cache)
		var erro_tipo := V1Estrutura.verificar_tipo(tipo, caminho, i, recurso)
		if erro_tipo != null:
			_diagnosticos.append(erro_tipo)
			continue
		var item := ItemDoCatalogo.new(tipo, caminho, i, recurso as DefinicaoBase)
		if _leitor.conhece_presenca():
			item.definir_campos_gravados(_leitor.campos_gravados(caminho))
		_itens.append(item)
	_estado = Estado.VALIDANDO
	_diagnosticos.append_array(_validador.validar(_itens))
	return _concluir(ordem_tipos)


func _ler_recurso(caminho: String, ignorar_cache: bool) -> Resource:
	if ignorar_cache:
		return _leitor.carregar_sem_cache(caminho)
	return _leitor.carregar(caminho)


## Estado atual.
func estado() -> Estado:
	return _estado


## Diagnósticos da última carga, ordenados (tipo, posição, regra, campo).
func diagnosticos() -> Array[Diagnostico]:
	return _diagnosticos.duplicate()


## Catálogo publicado; [code]null[/code] fora de Pronto.
func catalogo() -> Catalogo:
	return _catalogo if _estado == Estado.PRONTO else null


func _falha_de_leitura(caminho: String, mensagem: String, tipo: StringName = &"", posicao: int = -1) -> void:
	var d := Diagnostico.novo(REGRA_LEITURA, "", caminho, mensagem)
	d.arquivo = caminho
	d.tipo = tipo
	d.posicao = posicao
	_diagnosticos.append(d)


func _concluir(ordem_tipos: Array[StringName]) -> bool:
	_diagnosticos = Diagnostico.ordenar(_diagnosticos, ordem_tipos)
	if Diagnostico.contar_erros(_diagnosticos) > 0:
		_estado = Estado.FALHOU
		_itens = []
		return false
	var cat := Catalogo.new(_relator)
	for item in _itens:
		cat.adicionar(item.tipo, item.definicao)
	if _segunda_passada != null:
		var diags_2a := _segunda_passada.validar(_itens, cat)
		if not diags_2a.is_empty():
			_diagnosticos.append_array(diags_2a)
			_diagnosticos = Diagnostico.ordenar(_diagnosticos, ordem_tipos)
			if Diagnostico.contar_erros(_diagnosticos) > 0:
				_estado = Estado.FALHOU
				_itens = []
				return false
	# Impressão canônica ao fim de toda carga com 0 erros; erro de serialização impede Pronto (story 008).
	var impressao := ImpressaoCanonica.calcular(cat)
	if not impressao.erros.is_empty():
		_diagnosticos.append_array(impressao.erros)
		_estado = Estado.FALHOU
		_itens = []
		return false
	cat.definir_impressao(impressao.completa)
	_catalogo = cat
	_estado = Estado.PRONTO
	for c in _consumidores:
		c.receber_ajustes(_catalogo)
	return true
