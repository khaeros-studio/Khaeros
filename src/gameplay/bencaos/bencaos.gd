class_name Bencaos
extends RefCounted
## Módulo de run das Bênçãos (GDD bencaos-tradicoes.md R3–R9, States and Transitions;
## ADR-0015 Key Interfaces §9, ADR-0002, ADR-0005).
##
## Contrato síncrono com as Portas: [method pedir_oferta] responde
## [constant ABERTA], [constant SEM_BENCAO] ou [constant OFERTA_JA_ABERTA].
## Montado em memória pela [code]FabricaDaRun[/code]; sem Autoload, sem SceneTree.
##
## Máquina de estados (transições explícitas):
## [codeblock]
## SEM_OFERTA     --pedir_oferta, pool ≥ 1-->  OFERTA_ABERTA   (emite oferta_aberta)
## SEM_OFERTA     --pedir_oferta, pool 0-->    SEM_OFERTA      (6 reais consumidos, sem_bencao)
## OFERTA_ABERTA  --trocar, trocas ≥ 1-->      OFERTA_ABERTA   (6 reais, emite oferta_trocada)
## OFERTA_ABERTA  --pedir_oferta-->            OFERTA_ABERTA   (oferta_ja_aberta, sem RNG)
## OFERTA_ABERTA  --escolha (story 006)-->     ESCOLHIDA --> SEM_OFERTA
## qualquer       --pedir_oferta fora de run--> igual          (FORA_DE_RUN, sem RNG)
## [/codeblock]
##
## Exemplo:
## [codeblock]
## var b := Bencaos.new(registro, sorteio, fluxos, consulta, tuning, {&"limiar": 0}, eventos)
## if b.pedir_oferta(&"limiar", 2) == Bencaos.ABERTA:
##     estado.pedir_estado(EstadoDeJogo.BENCAO)
## [/codeblock]

## Respostas de [method pedir_oferta].
const ABERTA: StringName = &"aberta"
const SEM_BENCAO: StringName = &"sem_bencao"
const OFERTA_JA_ABERTA: StringName = &"oferta_ja_aberta"
## Pedido fora de uma run ativa (erro de contrato, ignorado, sem consumir RNG).
## Não está no contrato do ADR-0015: as Portas nunca pedem fora de run.
const FORA_DE_RUN: StringName = &"fora_de_run"

## Estados (GDD States and Transitions).
enum Estado { SEM_OFERTA, OFERTA_ABERTA, ESCOLHIDA }

var _registro: RegistroDeBencaos
var _sorteio: SorteioDeOferta
var _fluxos: FluxosDeBencaos
var _consulta: ConsultaDeAtributos
var _tuning: BencaosTuning
var _regioes: Dictionary[StringName, int] = {}
var _eventos: EventosDoPasso
var _estado: Estado = Estado.SEM_OFERTA
var _cartas: Array[CartaDaOferta] = []
var _regiao_aberta: int = -1
var _indice_aberto: int = -1
var _trocas_gastas: int = 0
var _espelho: EspelhoDeFontes = null
var _carta_escolhida: CartaDaOferta = null
var _log_ordem: Array[StringName] = []


## Dependências injetadas (R12). [param regioes] mapeia o id da região ao índice
## de região da chave do RNG (ADR-0005). [param consulta] dá o atributo
## [code]trocas_oferta[/code] do jogador, que soma à base [code]trocas_iniciais[/code];
## se for um [Portador], também recebe a fonte da bênção escolhida.
## [param espelho] opcional: quando presente (runs de Pactos), propaga a fonte para a dupla.
func _init(registro: RegistroDeBencaos, sorteio: SorteioDeOferta, fluxos: FluxosDeBencaos,
		consulta: ConsultaDeAtributos, tuning: BencaosTuning, regioes: Dictionary[StringName, int],
		eventos: EventosDoPasso, espelho: EspelhoDeFontes = null) -> void:
	_registro = registro
	_sorteio = sorteio
	_fluxos = fluxos
	_consulta = consulta
	_tuning = tuning
	_regioes = regioes.duplicate()
	_eventos = eventos
	_espelho = espelho


## Configura o [EspelhoDeFontes] para propagar bênçãos à dupla da Maldição (R14-P).
func definir_espelho(espelho: EspelhoDeFontes) -> void:
	_espelho = espelho


## Pedido das Portas (R3). Sorteia com a chave (região, índice da câmara).
func pedir_oferta(regiao: StringName, indice: int) -> StringName:
	if _estado == Estado.OFERTA_ABERTA:
		return OFERTA_JA_ABERTA
	if not _regioes.has(regiao):
		return FORA_DE_RUN
	var r: int = _regioes[regiao]
	var fb: FluxoRng = _fluxos.bencaos(r, indice)
	var fr: FluxoRng = _fluxos.raridade(r, indice)
	if fb == null or fr == null:
		return FORA_DE_RUN
	var cartas: Array[CartaDaOferta] = _sorteio.sortear(_registro.livres(), fb, fr)
	if cartas.is_empty():
		_estado = Estado.SEM_OFERTA
		return SEM_BENCAO
	_cartas = cartas
	_regiao_aberta = r
	_indice_aberto = indice
	_estado = Estado.OFERTA_ABERTA
	_eventos.emitir(EvOfertaAberta.new(_ids(), _raridades(), trocas_restantes()))
	return ABERTA


## Troca (R6): com trocas ≥ 1 gasta 1 e re-sorteia do pool inteiro com mais 6 reais
## da mesma chave. Sem oferta aberta ou sem trocas: recusa (false) sem consumir real.
func trocar() -> bool:
	if _estado != Estado.OFERTA_ABERTA or trocas_restantes() < 1:
		return false
	var fb: FluxoRng = _fluxos.bencaos(_regiao_aberta, _indice_aberto)
	var fr: FluxoRng = _fluxos.raridade(_regiao_aberta, _indice_aberto)
	if fb == null or fr == null:
		return false
	_trocas_gastas += 1
	_cartas = _sorteio.sortear(_registro.livres(), fb, fr)
	_eventos.emitir(EvOfertaTrocada.new(_ids(), _raridades(), trocas_restantes()))
	return true


## Trocas da run: base [code]trocas_iniciais[/code] (dona: Bênçãos) + atributo
## [code]trocas_oferta[/code] (Modificadores, só soma) − trocas já gastas.
func trocas_restantes() -> int:
	return maxi(_tuning.trocas_iniciais + _consulta.inteiro(Atributos.TROCAS_OFERTA) - _trocas_gastas, 0)


## Estado atual da máquina.
func estado() -> Estado:
	return _estado


## Verdadeiro com uma oferta aberta.
func oferta_aberta() -> bool:
	return _estado == Estado.OFERTA_ABERTA


## Cartas da oferta aberta, na ordem do sorteio (cópia; vazia sem oferta).
func cartas() -> Array[CartaDaOferta]:
	return _cartas.duplicate() if _estado == Estado.OFERTA_ABERTA else [] as Array[CartaDaOferta]


## Tamanho do pool (R8).
func restantes() -> int:
	return _registro.restantes()


## Tomadas na ordem em que foram pegas (R8; cópia somente leitura).
func tomadas() -> Array[Dictionary]:
	return _registro.tomadas()


## Escolha de uma carta pela Tela (R5, AC-BN-08, AC-BN-09, AC-BN-10; ADR-0009, ADR-0012 §5).
## Aplica o efeito no [Portador] (via [EspelhoDeFontes] se houver) e registra no
## [RegistroDeBencaos]. Se [param fechar_imediato] for verdadeiro (padrão para chamadas
## síncronas sem animação de tela), emite [EvBencaoTomada] e [EvBencaoEscolhida] e volta a
## [constant Estado.SEM_OFERTA]; se falso, fica em [constant Estado.ESCOLHIDA] até
## [method notificar_tela_fechada]. Índices fora de [code]0..cartas().size()-1[/code] ou
## sem oferta aberta são ignorados (retorna [code]false[/code]).
func escolher(indice_carta: int, fechar_imediato: bool = true) -> bool:
	if _estado != Estado.OFERTA_ABERTA:
		return false
	if indice_carta < 0 or indice_carta >= _cartas.size():
		return false
	var carta: CartaDaOferta = _cartas[indice_carta]
	var boon: BoonDef = _registro.obter_boon(carta.id)
	_log_ordem.clear()
	if boon != null:
		var escala: float = _sorteio.escala_de(carta.raridade)
		var id_fonte := StringName("bencao:" + String(boon.id))
		var fonte: FonteDeModificador = AplicadorDeEfeitos.fonte_de(id_fonte, boon.efeitos, escala)
		if _espelho != null:
			_espelho.aplicar_fonte_do_jogador(fonte)
		elif _consulta is Portador:
			(_consulta as Portador).aplicar_fonte(fonte)
	_log_ordem.append(&"efeitos_aplicados")
	_registro.registrar(carta.id, carta.raridade)
	_log_ordem.append(&"registrado")
	_carta_escolhida = carta
	_cartas.clear()
	_estado = Estado.ESCOLHIDA
	if fechar_imediato:
		notificar_tela_fechada()
	return true


## Chamado quando a Tela fecha ([code]tela_fechada[/code], ADR-0012 §5): emite
## [EvBencaoTomada] e [EvBencaoEscolhida] em ordem e fecha o ciclo para [constant Estado.SEM_OFERTA].
func notificar_tela_fechada() -> bool:
	if _estado != Estado.ESCOLHIDA or _carta_escolhida == null:
		return false
	var c: CartaDaOferta = _carta_escolhida
	_carta_escolhida = null
	_estado = Estado.SEM_OFERTA
	_eventos.emitir(EvBencaoTomada.new(c.id, c.raridade, trocas_restantes()))
	_log_ordem.append(&"bencao_tomada")
	_eventos.emitir(EvBencaoEscolhida.new(c.id, c.raridade))
	_log_ordem.append(&"bencao_escolhida")
	return true


## Pular a oferta não existe (R5, AC-BN-10): sempre ignorado (retorna [code]false[/code]).
func pular() -> bool:
	return false


## Processa comandos de troca e escolha vindos no mesmo passo (R5, AC-BN-10; ADR-0012 §11):
## se ambos chegarem juntos e houver trocas restantes, a troca vence; sem trocas, vale a escolha.
func processar_comandos_do_passo(quer_trocar: bool, indice_escolha: int, fechar_imediato: bool = true) -> StringName:
	if quer_trocar and trocar():
		return &"trocou"
	if indice_escolha >= 0 and escolher(indice_escolha, fechar_imediato):
		return &"escolheu"
	return &"ignorado"


## Monta a lista de vistas de carta (`CartaView`) da oferta aberta com o texto formatado (R10).
func cartas_view(textos: TabelaDeTextos = null) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _estado != Estado.OFERTA_ABERTA:
		return out
	for c: CartaDaOferta in _cartas:
		var b: BoonDef = _registro.obter_boon(c.id)
		out.append(TextoDaCarta.montar_carta_view(b, c.raridade, _sorteio.tabela(), textos))
	return out


## Registro da ordem interna da última escolha (para verificação do AC-BN-09).
func ordem_da_ultima_escolha() -> Array[StringName]:
	return _log_ordem.duplicate()


func _ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for c: CartaDaOferta in _cartas:
		out.append(c.id)
	return out


func _raridades() -> Array[int]:
	var out: Array[int] = []
	for c: CartaDaOferta in _cartas:
		out.append(c.raridade)
	return out
