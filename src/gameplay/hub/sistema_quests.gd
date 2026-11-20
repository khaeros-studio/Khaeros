## Sistema de Quests (Contratos da Ordem): acompanhamento determinístico de
## objetivos de combate e progressão de chefes da campanha de Khaeros.
## Módulo puro (RefCounted), 100% determinístico e sem dependências de cena.
class_name SistemaQuests
extends RefCounted

const QUEST_PRIMEIRO_JURAMENTO: StringName = &"primeiro_juramento"
const QUEST_MESTRE_DO_SELO: StringName = &"mestre_do_selo"
const QUEST_QUEDA_SOBERANO: StringName = &"queda_soberano"
const QUEST_ECOS_DO_VEIO: StringName = &"ecos_do_veio"
const QUEST_FORJA_SILENCIADA: StringName = &"forja_silenciada"
const QUEST_SANTUARIO_PARTIDO: StringName = &"santuario_partido"

var _quests: Array[Dictionary] = []


func _init() -> void:
	_quests = _criar_catalogo_inicial()


static func _criar_catalogo_inicial() -> Array[Dictionary]:
	var lista: Array[Dictionary] = [
		{
			"id": QUEST_PRIMEIRO_JURAMENTO,
			"titulo": "O Primeiro Juramento",
			"descricao": "Abata 10 inimigos na Beira.",
			"meta": 10,
			"progresso": 0,
			"recompensa_frag": 35,
			"concluida": false,
			"resgatada": false,
		},
		{
			"id": QUEST_MESTRE_DO_SELO,
			"titulo": "Despertar do Selo",
			"descricao": "Ative o Selo da Doutrina [Q] 3 vezes em combate.",
			"meta": 3,
			"progresso": 0,
			"recompensa_frag": 50,
			"concluida": false,
			"resgatada": false,
		},
		{
			"id": QUEST_QUEDA_SOBERANO,
			"titulo": "Queda do Soberano",
			"descricao": "Derrote o Soberano do Limiar.",
			"meta": 1,
			"progresso": 0,
			"recompensa_frag": 60,
			"concluida": false,
			"resgatada": false,
		},
		{
			"id": QUEST_ECOS_DO_VEIO,
			"titulo": "Ecos do Veio Instável",
			"descricao": "Derrote o Guardião do Rito no Veio Instável.",
			"meta": 1,
			"progresso": 0,
			"recompensa_frag": 90,
			"concluida": false,
			"resgatada": false,
		},
		{
			"id": QUEST_FORJA_SILENCIADA,
			"titulo": "Forja Silenciada",
			"descricao": "Derrube o Colosso de Cinza no Fosso das Cinzas.",
			"meta": 1,
			"progresso": 0,
			"recompensa_frag": 120,
			"concluida": false,
			"resgatada": false,
		},
		{
			"id": QUEST_SANTUARIO_PARTIDO,
			"titulo": "Além da Fenda",
			"descricao": "Derrote o Arconte da Fenda e atravesse o Santuário Partido.",
			"meta": 1,
			"progresso": 0,
			"recompensa_frag": 200,
			"concluida": false,
			"resgatada": false,
		},
	]
	return lista


## Registra o abate de um inimigo pelo seu identificador [param kind].
## Retorna a lista de quests recém-concluídas por este evento.
func registrar_abate(kind: String) -> Array[Dictionary]:
	var recem_concluidas: Array[Dictionary] = []
	_avancar_quest(QUEST_PRIMEIRO_JURAMENTO, 1, recem_concluidas)

	match kind:
		"soberano_do_limiar":
			_avancar_quest(QUEST_QUEDA_SOBERANO, 1, recem_concluidas)
		"guardiao_do_rito":
			_avancar_quest(QUEST_ECOS_DO_VEIO, 1, recem_concluidas)
		"colosso_de_cinza":
			_avancar_quest(QUEST_FORJA_SILENCIADA, 1, recem_concluidas)
		"arconte_da_fenda":
			_avancar_quest(QUEST_SANTUARIO_PARTIDO, 1, recem_concluidas)

	return recem_concluidas


## Registra uma ativação do Selo da Doutrina em combate.
## Retorna a lista de quests recém-concluídas por este evento.
func registrar_selo() -> Array[Dictionary]:
	var recem_concluidas: Array[Dictionary] = []
	_avancar_quest(QUEST_MESTRE_DO_SELO, 1, recem_concluidas)
	return recem_concluidas


## Retorna cópia da primeira quest ainda não concluída, ou {} se todas estiverem completas.
func quest_ativa() -> Dictionary:
	for q: Dictionary in _quests:
		var concluida: bool = bool(q["concluida"])
		if not concluida:
			return q.duplicate(true)
	return {}


## Retorna cópias profundas de todas as quests na ordem canônica da Ordem.
func todas_quests() -> Array[Dictionary]:
	var copia: Array[Dictionary] = []
	for q: Dictionary in _quests:
		copia.append(q.duplicate(true))
	return copia


## Retorna o total de quests já concluídas.
func total_concluidas() -> int:
	var total: int = 0
	for q: Dictionary in _quests:
		if bool(q["concluida"]):
			total += 1
	return total


## Marca uma quest concluída como resgatada e retorna sua recompensa em Fragmentos,
## ou 0 caso não exista, não esteja concluída ou já tenha sido resgatada.
func resgatar(id_quest: StringName) -> int:
	for q: Dictionary in _quests:
		var q_id: StringName = StringName(q["id"])
		if q_id == id_quest:
			var concluida: bool = bool(q["concluida"])
			var resgatada: bool = bool(q["resgatada"])
			if concluida and not resgatada:
				q["resgatada"] = true
				return int(q["recompensa_frag"])
			return 0
	return 0


## Serializa o progresso das quests para persistência determinística.
func para_dicionario() -> Dictionary:
	var estados: Dictionary = {}
	for q: Dictionary in _quests:
		var chave: String = String(q["id"])
		estados[chave] = {
			"progresso": int(q["progresso"]),
			"concluida": bool(q["concluida"]),
			"resgatada": bool(q["resgatada"]),
		}
	return estados


## Restaura o progresso das quests a partir de um dicionário serializado.
func de_dicionario(dados: Dictionary) -> void:
	_quests = _criar_catalogo_inicial()
	for q: Dictionary in _quests:
		var chave: String = String(q["id"])
		if not dados.has(chave):
			continue
		var entrada_var: Variant = dados[chave]
		if not (entrada_var is Dictionary):
			continue
		var entrada: Dictionary = entrada_var as Dictionary
		var meta: int = int(q["meta"])
		var progresso: int = clampi(int(entrada.get("progresso", 0)), 0, meta)
		var concluida: bool = bool(entrada.get("concluida", false)) or progresso >= meta
		if concluida:
			progresso = meta
		var resgatada: bool = bool(entrada.get("resgatada", false)) and concluida
		q["progresso"] = progresso
		q["concluida"] = concluida
		q["resgatada"] = resgatada


func _avancar_quest(id_quest: StringName, incremento: int, recem_concluidas: Array[Dictionary]) -> void:
	if incremento <= 0:
		return
	for q: Dictionary in _quests:
		var q_id: StringName = StringName(q["id"])
		if q_id != id_quest:
			continue
		if bool(q["concluida"]):
			return
		var meta: int = int(q["meta"])
		var progresso_novo: int = mini(int(q["progresso"]) + incremento, meta)
		q["progresso"] = progresso_novo
		if progresso_novo >= meta:
			q["concluida"] = true
			recem_concluidas.append(q.duplicate(true))
		return
