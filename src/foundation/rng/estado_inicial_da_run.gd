## Dados de reprodução da run expostos aos sinks de telemetria e de relatório de
## erro (GDD rng-com-seed.md R7, R7-P, R8; ADR-0005 "Seed, telemetria e
## fronteira"; ADR-0013 para o perfil de vínculo, aqui recebido por injeção).
##
## Os seis elementos do contrato: seed, versão, impressão, estado inicial (este
## objeto) e o caminho ([EstadoInicialDaRun.CaminhoDaRun]: escolhas de porta e
## de bênção e usos de "Trocar ofertas"). Só monta dicionários; quem grava é a
## Persistência/Telemetria.
class_name EstadoInicialDaRun
extends RefCounted

## Doutrina que amplia o estado inicial (R7-P).
const DOUTRINA_PACTOS: StringName = &"pactos"


## Perfil de vínculo lido do perfil salvo (Vínculo V40), só em runs de Pactos.
class PerfilDeVinculo:
	extends RefCounted
	## Espécies pactuadas, na ordem do manifesto.
	var especies_pactuadas: Array[StringName] = []
	## `nivel` de cada espécie, mesma ordem de `especies_pactuadas`.
	var niveis: Array[int] = []
	## Há encontro pendente.
	var encontro_pendente: bool = false
	## O primeiro encontro já foi visto.
	var primeiro_encontro_visto: bool = false
	## Runs de Pactos seguidas sem encontro.
	var runs_pactos_sem_encontro: int = 0

	## Forma serializável (ordem das espécies preservada).
	func para_dicionario() -> Dictionary[String, Variant]:
		var especies: Array[Dictionary] = []
		for i: int in especies_pactuadas.size():
			especies.append({"especie": String(especies_pactuadas[i]), "nivel": niveis[i]})
		return {
			"especies_pactuadas": especies,
			"encontro_pendente": encontro_pendente,
			"primeiro_encontro_visto": primeiro_encontro_visto,
			"runs_pactos_sem_encontro": runs_pactos_sem_encontro,
		}


## Caminho da run (R7): escolhas de porta e de bênção e usos de troca, em ordem.
class CaminhoDaRun:
	extends RefCounted
	var _escolhas: Array[Dictionary] = []
	var _trocas: Array[Dictionary] = []

	## Registra a porta escolhida na profundidade.
	func registrar_porta(profundidade: int, indice_da_porta: int) -> void:
		_escolhas.append({"tipo": "porta", "profundidade": profundidade, "indice": indice_da_porta})

	## Registra a bênção escolhida na profundidade.
	func registrar_bencao(profundidade: int, id_da_bencao: StringName) -> void:
		_escolhas.append({"tipo": "bencao", "profundidade": profundidade, "id": String(id_da_bencao)})

	## Registra uma carga de "Trocar ofertas" gasta na oferta da profundidade.
	func registrar_troca(profundidade: int) -> void:
		_trocas.append({"profundidade": profundidade})

	## Forma serializável do caminho.
	func para_dicionario() -> Dictionary[String, Variant]:
		return {"escolhas": _escolhas.duplicate(true), "trocas": _trocas.duplicate(true)}


var _seed: int = 0
var _versao: String = ""
var _impressao_completa: String = ""
var _impressao_curta: String = ""
var _arma: StringName = &""
var _doutrina: StringName = &""
var _melhorias_ids: Array[StringName] = []
var _melhorias_niveis: Array[int] = []
var _dupla: Array[StringName] = []
var _perfil: PerfilDeVinculo = null


## `melhorias_ids`/`melhorias_niveis`: melhorias da Oficina na ordem do manifesto.
func _init(seed_da_run: int, versao: String, impressao_completa: String, impressao_curta: String,
		arma: StringName, doutrina: StringName, melhorias_ids: Array[StringName], melhorias_niveis: Array[int]) -> void:
	_seed = RngAritmetica.mascarar_u32(seed_da_run)
	_versao = versao
	_impressao_completa = impressao_completa
	_impressao_curta = impressao_curta
	_arma = arma
	_doutrina = doutrina
	_melhorias_ids = melhorias_ids.duplicate()
	_melhorias_niveis = melhorias_niveis.duplicate()


## R7-P: só em runs de Pactos. `campo` e `reserva` podem vir vazios (&"").
## Fora de Pactos não faz nada (dupla vazia e nenhum perfil).
func definir_pactos(campo: StringName, reserva: StringName, perfil: PerfilDeVinculo) -> void:
	if _doutrina != DOUTRINA_PACTOS:
		return
	_dupla = [campo, reserva]
	_perfil = perfil


## R8: texto da seed (seed, versão, impressão curta), igual com ou sem Pactos.
func texto_da_seed() -> String:
	return TextoDaSeed.rotulo(_seed, _versao, _impressao_curta)


## Quarto elemento do contrato (R7, R7-P).
func estado_inicial() -> Dictionary[String, Variant]:
	var melhorias: Array[Dictionary] = []
	for i: int in _melhorias_ids.size():
		melhorias.append({"id": String(_melhorias_ids[i]), "nivel": _melhorias_niveis[i]})
	var dupla: Array[String] = []
	for id: StringName in _dupla:
		dupla.append(String(id))
	var dados: Dictionary[String, Variant] = {
		"arma": String(_arma),
		"doutrina": String(_doutrina),
		"melhorias": melhorias,
		"dupla": dupla,
	}
	if _perfil != null:
		dados["perfil_vinculo"] = _perfil.para_dicionario()
	return dados


## Telemetria de início de run: seed, versão, impressão completa e estado inicial.
func para_inicio_de_run() -> Dictionary[String, Variant]:
	return {
		"seed": _seed,
		"seed_texto": TextoDaSeed.formatar(_seed),
		"versao": _versao,
		"impressao": _impressao_completa,
		"estado_inicial": estado_inicial(),
	}


## Telemetria de fim de run: o caminho.
static func para_fim_de_run(caminho: CaminhoDaRun) -> Dictionary[String, Variant]:
	return {"caminho": caminho.para_dicionario()}


## Relatório de erro: os seis elementos (início + caminho).
func para_relatorio_de_erro(caminho: CaminhoDaRun) -> Dictionary[String, Variant]:
	var dados: Dictionary[String, Variant] = para_inicio_de_run()
	dados["caminho"] = caminho.para_dicionario()
	return dados
