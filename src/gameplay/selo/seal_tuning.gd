class_name SealTuning
extends DefinicaoBase
## Configuração e constantes do Selo e do Fluxo (GDD `design/gdd/selo-e-fluxo.md` R7;
## ADR-0004). Formato: durações em segundos, taxas por segundo, distâncias em px.
## Único por jogo; entra no manifesto como tipo `&"tuning"`.

@export var fluxo_max: float = 100.0
@export var regen_fluxo_s: float = 3.6
@export var fluxo_por_acerto: float = 3.0
@export var custo_fluxo: float = 40.0
@export var recarga_s: float = 0.5
@export var raio_px: float = 142.5
@export var duracao_s: float = 200.0 / 60.0
@export var dano_selo_s: float = 7.2
@export var fator_lentidao: float = 0.5
@export var distancia_px: float = 180.0
@export var margem_borda_px: float = 30.0


func tipo_do_catalogo() -> StringName:
	return &"tuning"


## Instância com os valores de fábrica do GDD (R7).
static func fabrica() -> SealTuning:
	var s := SealTuning.new()
	s.id = &"seal_tuning"
	s.fluxo_max = 100.0
	s.regen_fluxo_s = 3.6
	s.fluxo_por_acerto = 3.0
	s.custo_fluxo = 40.0
	s.recarga_s = 30.0 / 60.0
	s.raio_px = 142.5
	s.duracao_s = 200.0 / 60.0
	s.dano_selo_s = 7.2
	s.fator_lentidao = 0.5
	s.distancia_px = 180.0
	s.margem_borda_px = 30.0
	return s
