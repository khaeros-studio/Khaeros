class_name EscopoDaRun
extends RefCounted
## Escopo de vida de uma única run (ADR-0015 §2, §3; GDD run-e-regioes.md R8, R8-P).
##
## Contém todos os objetos que nascem ao iniciar a run e morrem juntos em [method SessaoDeJogo.nova_run]:
## - [GeradorDeIds], [FonteDeFluxos] da run, [Portador] do jogador, [RegistroDeBencaos],
##   [Bencaos], [Portas], [Camaras], estado de combate/selo/status/maldições da run.
## - **Recriar, não zerar**: nenhum módulo aqui tem método `reset()`; ao chamar `nova_run()`,
##   este objeto tem [method desligar] chamado e sua referência é descartada (coletada por `RefCounted`).

var gerador_ids: GeradorDeIds
var fonte_fluxos: FonteDeFluxos
var portador_jogador: Portador
var jogador_ref: JogadorRef
var arma_def: WeaponDef
var dupla_ids: Array[StringName] = []
var registro_bencaos: RegistroDeBencaos
var bencaos: Bencaos
var portas: Portas
var camaras: Camaras

# Contadores e estado volátil da run (que morrem com o escopo em nova_run — AC-RN-19, AC-RN-36)
var fluxo_selo: float = 100.0
var fluxo_max_selo: float = 100.0
var selos_ativos: Array = []
var status_ativos: Array = []
var estado_maldicoes_run: Dictionary = {}
var chefe_presente: bool = false
var desligado: bool = false


func _init() -> void:
	gerador_ids = GeradorDeIds.new()


## Remove assinaturas e referências cruzadas antes de a [SessaoDeJogo] soltar este escopo (ADR-0015 §2).
func desligar() -> void:
	if desligado:
		return
	desligado = true
	if fonte_fluxos != null:
		fonte_fluxos.descartar_run()
	if portador_jogador != null:
		portador_jogador.definir_ouvinte(null)
	if camaras != null:
		camaras.configurar_portas_e_run(Callable(), Callable())
		camaras.configurar_orquestrador(null)
		camaras.configurar_jogador(null, Callable(), Callable(), Callable(), Callable())
		camaras.configurar_combate(Callable(), Callable(), Callable(), Callable())
		camaras.configurar_ia(Callable(), Callable())
		camaras.configurar_pactos(Callable(), Callable(), Callable(), Callable(), Callable())
	if portas != null:
		portas.configurar_run(null)
		portas.configurar_camaras(null)
		portas.configurar_vinculo(null, Callable())
		portas.configurar_orquestrador(null)
		portas.configurar_jogador(null, Callable(), Callable())
	selos_ativos.clear()
	status_ativos.clear()
	estado_maldicoes_run.clear()
	chefe_presente = false
