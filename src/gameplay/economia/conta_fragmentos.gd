## Conta de Fragmentos de Eco (GDD design/gdd/economia-de-fragmentos.md R1–R9, F1, F2;
## ADR-0015 §6; ADR-0002).
##
## Escopo de **sessão**: criada uma vez pela [code]ComposicaoDaSessao[/code] e injetada
## (sem singleton) com escrita em Portas, Chefes e Run, e como [LeituraDaConta] em
## HUD/Telemetria/tela final. O [code]saldo[/code] atravessa as runs, vive só em
## memória e nunca vai para [code]perfil.cfg[/code] (R7, decisão 21).
##
## A conta não guarda taxa de porta, vitória nem chefe (R2): quem chama passa a
## quantidade. De [EconomyRates] ela só usa [code]saldo_max[/code].
##
## Recusas não travam: saldo intacto, nenhum evento e um registro no [RelatorDaEconomia].
##
## Exemplo:
## [codeblock]
## var conta := ContaFragmentos.new(rates, eventos, RelatorDaEconomiaPadrao.new())
## var efetivo := conta.creditar(ContaFragmentos.PORTA, 2)   # 2; emite saldo_mudou(2, +2, porta)
## conta.nova_run()                                          # coletados_run = 0; saldo fica
## [/codeblock]
## Não é seguro entre threads: só a thread principal a usa.
class_name ContaFragmentos
extends LeituraDaConta

## Origem: porta de Fragmentos (dono da taxa: RewardTable/Portas F1).
const PORTA: StringName = &"porta"
## Origem: vitória da run (dono da taxa: RunTuning.fragmentos_vitoria).
const VITORIA: StringName = &"vitoria"
## Origem: chefe abatido ou exorcizado (dono da taxa: RegionDef.fragmentos_chefe; R2-P).
const CHEFE: StringName = &"chefe"
## Origem reservada: Provação (dono da taxa: EconomyRates.fragmentos_provacao).
const PROVACAO: StringName = &"provacao"
## Origens aceitas por [method creditar] (R2/R2-P). Não há abate nem elite (baseline §56).
const ORIGENS_VALIDAS: Array[StringName] = [PORTA, VITORIA, CHEFE, PROVACAO]

## Recusa de crédito ou gasto: quantidade não inteira, < 1, ou origem desconhecida (R3, R5).
const EC1: StringName = &"EC1"
## [method importar] com valor inválido (negativo ou não [code]int[/code]); saldo mantido (R7).
const EC2: StringName = &"EC2"
## Gasto maior que o saldo; nada muda (R5).
const SALDO_INSUFICIENTE: StringName = &"saldo_insuficiente"
## Aviso: um construtor recebeu [code]null[/code] no lugar da conta e usou a Nula (ADR-0015 §9).
const CONTA_AUSENTE: StringName = &"conta_ausente"
## Aviso: a conta foi criada sem [EconomyRates] ou sem canal de eventos.
const CONFIG_AUSENTE: StringName = &"config_ausente"

var _saldo: int = 0
var _coletados_run: int = 0
var _rates: EconomyRates
var _eventos: EventosDoPasso
var _relator: RelatorDaEconomia


## [param rates]: [EconomyRates] do catálogo validado (só [code]saldo_max[/code] é lido).
## [param eventos]: canal do passo (ADR-0002), onde saem [EvSaldoMudou] e [EvSaldoNoTeto].
## [param relator]: recebe as recusas; [code]null[/code] usa [RelatorDaEconomiaPadrao].
## Começa vazia (saldo 0, coletados 0; R9). Um [param rates] ou [param eventos] nulo é
## trocado por um vazio e avisado com [constant CONFIG_AUSENTE] (com [EconomyRates] vazio,
## o teto é 0 e todo crédito é cortado).
func _init(rates: EconomyRates, eventos: EventosDoPasso, relator: RelatorDaEconomia = null) -> void:
	_relator = relator if relator != null else RelatorDaEconomiaPadrao.new()
	_rates = rates
	_eventos = eventos
	if _rates == null:
		_rates = EconomyRates.new()
		_relator.registrar(CONFIG_AUSENTE, "ContaFragmentos sem EconomyRates")
	if _eventos == null:
		_eventos = EventosDoPasso.new()
		_relator.registrar(CONFIG_AUSENTE, "ContaFragmentos sem canal de eventos")


## Saldo atual (R8).
func saldo() -> int:
	return _saldo


## O que a run atual creditou, vitória incluída (R4, R8).
func coletados_run() -> int:
	return _coletados_run


## Teto do saldo em uso ([code]EconomyRates.saldo_max[/code]).
func saldo_max() -> int:
	return _rates.saldo_max


## Credita [param quantidade] vinda de [param origem] e devolve o **efetivo** (F1):
## [code]efetivo = min(q, saldo_max − saldo)[/code]. Soma o efetivo ao saldo e a
## [method coletados_run]; com efetivo > 0 emite [EvSaldoMudou]; se [code]efetivo < q[/code]
## emite [EvSaldoNoTeto] (com efetivo 0, só ele).[br]
## Recusa com [constant EC1] (devolve 0, nada muda, sem evento) se [param quantidade]
## não é [code]int[/code] (um [code]float[/code], mesmo [code]2.0[/code], ou NaN) ou é < 1,
## ou se [param origem] não está em [constant ORIGENS_VALIDAS].[br]
## Desvio registrado: o ADR tipa [code]quantidade: int[/code]; aqui é [Variant] para que
## a conversão implícita float→int do GDScript não esconda a recusa exigida pela R3.
func creditar(origem: StringName, quantidade: Variant) -> int:
	if typeof(quantidade) != TYPE_INT or int(quantidade) < 1:
		_relator.registrar(EC1, "creditar: quantidade inválida %s (origem %s)" % [str(quantidade), origem])
		return 0
	if not ORIGENS_VALIDAS.has(origem):
		_relator.registrar(EC1, "creditar: origem desconhecida %s" % origem)
		return 0
	var q: int = quantidade
	var efetivo: int = mini(q, maxi(_rates.saldo_max - _saldo, 0))
	_saldo += efetivo
	_coletados_run += efetivo
	if efetivo > 0:
		_eventos.emitir(EvSaldoMudou.new(_saldo, efetivo, origem))
	if efetivo < q:
		_eventos.emitir(EvSaldoNoTeto.new(_saldo, q, efetivo, origem))
	return efetivo


## Gasta [param quantidade] (R5, F2), atômico: se [code]saldo ≥ quantidade[/code], subtrai e
## emite [code]saldo_mudou(saldo, −quantidade, motivo)[/code]; não mexe em
## [method coletados_run]. Devolve [code]true[/code] se gastou.[br]
## Recusas (devolvem [code]false[/code], sem evento): [constant EC1] se não é [code]int[/code]
## ou é < 1; [constant SALDO_INSUFICIENTE] se falta saldo. Ninguém chama no MVP (sem Oficina).[br]
## Desvio registrado: [param motivo] é parâmetro opcional (o ADR tem só a quantidade;
## o GDD pede [code]gastar(custo, motivo)[/code]).
func gastar(quantidade: Variant, motivo: StringName = &"") -> bool:
	if typeof(quantidade) != TYPE_INT or int(quantidade) < 1:
		_relator.registrar(EC1, "gastar: custo inválido %s" % str(quantidade))
		return false
	var custo: int = quantidade
	if _saldo < custo:
		_relator.registrar(SALDO_INSUFICIENTE, "gastar: custo %d, saldo %d" % [custo, _saldo])
		return false
	_saldo -= custo
	_eventos.emitir(EvSaldoMudou.new(_saldo, -custo, motivo))
	return true


## Nova run (R6): zera [method coletados_run]; não toca o saldo. Chamada pela
## [code]SessaoDeJogo.nova_run()[/code] depois de soltar o escopo de run (ADR-0015).
func nova_run() -> void:
	_coletados_run = 0


## Devolve o saldo para quem persistir (R7). Não chamado no MVP (Save R12).
func exportar() -> int:
	return _saldo


## Restaura o saldo (R7). [param valor] tem de ser [code]int[/code] ≥ 0; acima do teto é
## cortado em [code]saldo_max[/code]. Inválido (negativo, [code]float[/code], texto…): mantém
## o saldo e registra [constant EC2]. Não emite evento nem mexe em [method coletados_run].
func importar(valor: Variant) -> void:
	if typeof(valor) != TYPE_INT or int(valor) < 0:
		_relator.registrar(EC2, "importar: valor inválido %s" % str(valor))
		return
	var v: int = valor
	_saldo = mini(v, maxi(_rates.saldo_max, 0))
