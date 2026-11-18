class_name ArmaDaRun
extends RefCounted
## Estado da arma escolhida na run e injeção no [Portador] e no [Combate]
## (GDD `design/gdd/armas-das-doutrinas.md` R5, R9, States and Transitions;
## Story 004, AC-AR-06, AC-AR-10, AC-AR-14, AC-AR-15, AC-AR-36, AC-AR-51; ADR-0015 §3).
##
## Máquina de estados explícita:
## - `ESCOLHENDO` -> (confirmar na criação da run) `EQUIPADA`
## - `EQUIPADA` -> (fim da run: morte, vitória ou abandono) `ENCERRADA`
## Não existe método para trocar de arma durante `EQUIPADA` (a arma é fixa na run).

enum Estado { ESCOLHENDO, EQUIPADA, ENCERRADA }

var _estado: Estado = Estado.ESCOLHENDO
var _arma: WeaponDef = null
var _eventos: EventosDoPasso = null


func _init(eventos: EventosDoPasso = null) -> void:
	_eventos = eventos


## Estado atual (`ESCOLHENDO`, `EQUIPADA` ou `ENCERRADA`).
func estado() -> Estado:
	return _estado


## Confirma a arma para a run (só válido em `ESCOLHENDO`). Faz cópia profunda do
## [WeaponDef] para garantir que o catálogo nunca seja mutado (ADR-0004, AC-AR-06) e
## emite [EvArmaEquipada] no canal de eventos para a Telemetria local.
func confirmar_para_run(arma_catalogo: WeaponDef, player_id: int = 0) -> bool:
	if _estado != Estado.ESCOLHENDO or arma_catalogo == null:
		return false
	if FabricaDeArmas.validar_esquema_weapon_def(arma_catalogo) != "":
		return false
	_arma = arma_catalogo.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as WeaponDef
	_estado = Estado.EQUIPADA
	if _eventos != null:
		_eventos.emitir(EvArmaEquipada.new(_arma.id, _arma.doutrina, player_id))
	return true


## Encerra a run (`EQUIPADA` -> `ENCERRADA`, no fim da run por morte, vitória ou abandono).
func encerrar_run() -> bool:
	if _estado != Estado.EQUIPADA:
		return false
	_estado = Estado.ENCERRADA
	return true


## Definição da arma equipada (somente leitura; null fora de `EQUIPADA`/`ENCERRADA`).
func arma() -> WeaponDef:
	return _arma


## Id da arma equipada (`&""` antes de confirmar).
func id() -> StringName:
	return _arma.id if _arma != null else &""


## Doutrina da arma equipada (`&""` antes de confirmar; fornecida às Bênçãos, HUD e Telemetria, R5).
func doutrina() -> StringName:
	return _arma.doutrina if _arma != null else &""


## R5 (AC-AR-15): a arma nunca restringe nem filtra o pool de bênçãos. Devolve uma cópia
## intacta do pool recebido e só expõe [method doutrina] para consulta.
func filtrar_pool_bencaos(pool: Array[BoonDef]) -> Array[BoonDef]:
	return pool.duplicate()


## R9 (AC-AR-06): monta o [Portador] do jogador com `vida_max` e `velocidade` base da arma
## equipada (sem modificadores).
func criar_portador_do_jogador(id_combatente: int, player_id: int, tuning_mod: ModifiersTuning,
		relator: RelatorDeErros = null, ouvinte: OuvinteDeAtributos = null) -> Portador:
	if _arma == null:
		return null
	var bases: Dictionary[StringName, float] = {
		Atributos.VIDA_MAX: float(_arma.vida_max),
		Atributos.VELOCIDADE: _arma.velocidade,
	}
	return Portador.new(id_combatente, player_id, Atributos.Especie.JOGADOR, bases, tuning_mod, relator, ouvinte)


## R9 (AC-AR-06): monta a entrada `DependenciasDoCombate.Jogador` com o [Portador] e os
## dois `AttackDef` (`ataque` e `especial`) da arma do catálogo.
static func montar_jogador_para_combate(arma_catalogo: WeaponDef, portador: Portador) -> DependenciasDoCombate.Jogador:
	if arma_catalogo == null or portador == null:
		return null
	return DependenciasDoCombate.Jogador.new(portador, arma_catalogo.ataque, arma_catalogo.especial)
