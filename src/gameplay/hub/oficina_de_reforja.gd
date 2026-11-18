## Oficina de Reforja: melhorias permanentes compradas com Fragmentos entre runs.
## Módulo puro (RefCounted), compatível com serialização para persistência futura e uso
## direto em Main / GameSession.
class_name OficinaDeReforja
extends RefCounted

const MELHORIA_TEMPERA_VITAL: StringName = &"tempera_vital"
const MELHORIA_FIO_AFIADO: StringName = &"fio_afiado"
const MELHORIA_PASSADA_FIRME: StringName = &"passada_firme"
const MELHORIA_RESERVA_ESQUIVA: StringName = &"reserva_esquiva"
const MELHORIA_SELO_AMPLIFICADO: StringName = &"selo_amplificado"

const ORDEM_MELHORIAS: Array[StringName] = [
	MELHORIA_TEMPERA_VITAL,
	MELHORIA_FIO_AFIADO,
	MELHORIA_PASSADA_FIRME,
	MELHORIA_RESERVA_ESQUIVA,
	MELHORIA_SELO_AMPLIFICADO,
]

const DEFINICOES: Dictionary = {
	MELHORIA_TEMPERA_VITAL: {
		"nome": "Têmpera Vital",
		"descricao": "+10 Vida Máxima por nível",
		"nivel_max": 5,
		"custo_base": 10,
		"custo_passo": 5,
	},
	MELHORIA_FIO_AFIADO: {
		"nome": "Fio Afiado",
		"descricao": "+6% Dano por nível",
		"nivel_max": 5,
		"custo_base": 12,
		"custo_passo": 6,
	},
	MELHORIA_PASSADA_FIRME: {
		"nome": "Passada Firme",
		"descricao": "+5% Velocidade por nível",
		"nivel_max": 4,
		"custo_base": 10,
		"custo_passo": 5,
	},
	MELHORIA_RESERVA_ESQUIVA: {
		"nome": "Reserva de Esquiva",
		"descricao": "+1 Carga de Esquiva",
		"nivel_max": 1,
		"custo_base": 25,
		"custo_passo": 0,
	},
	MELHORIA_SELO_AMPLIFICADO: {
		"nome": "Selo Amplificado",
		"descricao": "+15% Alcance/Área por nível",
		"nivel_max": 3,
		"custo_base": 15,
		"custo_passo": 10,
	},
}

var _niveis: Dictionary = {}


func _init() -> void:
	for id_m: StringName in ORDEM_MELHORIAS:
		_niveis[id_m] = 0


## Lista ordenada dos IDs das melhorias disponíveis na Oficina.
static func ids_melhorias() -> Array[StringName]:
	return ORDEM_MELHORIAS.duplicate()


## Metadados estáticos de uma melhoria (nome, descricao, nivel_max, custo_base, custo_passo).
static func info_melhoria(id_melhoria: StringName) -> Dictionary:
	return DEFINICOES.get(id_melhoria, {}).duplicate()


## Nível atual da melhoria (0 se não comprada ou desconhecida).
func nivel(id_melhoria: StringName) -> int:
	return int(_niveis.get(id_melhoria, 0))


## Custo em Fragmentos para o próximo nível, ou 0 se já atingiu o teto ou ID inválido.
func custo_proximo(id_melhoria: StringName) -> int:
	if not DEFINICOES.has(id_melhoria):
		return 0
	var def: Dictionary = DEFINICOES[id_melhoria]
	var atual := nivel(id_melhoria)
	if atual >= int(def["nivel_max"]):
		return 0
	return int(def["custo_base"]) + int(def["custo_passo"]) * atual


## Compra um nível da melhoria descontando da conta. Retorna true se efetivada.
func comprar(id_melhoria: StringName, conta: ContaFragmentos) -> bool:
	if conta == null or not DEFINICOES.has(id_melhoria):
		return false
	var def: Dictionary = DEFINICOES[id_melhoria]
	var atual := nivel(id_melhoria)
	if atual >= int(def["nivel_max"]):
		return false
	var custo := custo_proximo(id_melhoria)
	if custo <= 0:
		return false
	if not conta.gastar(custo, id_melhoria):
		return false
	_niveis[id_melhoria] = atual + 1
	return true


## Reembolsa todas as melhorias compradas, zera os níveis e devolve o total à conta.
func reembolsar_tudo(conta: ContaFragmentos) -> int:
	var total := 0
	for id_m: StringName in ORDEM_MELHORIAS:
		var def: Dictionary = DEFINICOES[id_m]
		var lv := nivel(id_m)
		var base := int(def["custo_base"])
		var passo := int(def["custo_passo"])
		for i: int in range(lv):
			total += base + passo * i
		_niveis[id_m] = 0
	if total > 0 and conta != null:
		conta.importar(conta.saldo() + total)
	return total


## Bônus plano de vida máxima (+10 por nível de tempera_vital).
func bonus_vida_plana() -> float:
	return float(nivel(MELHORIA_TEMPERA_VITAL)) * 10.0


## Multiplicador de dano (+6% por nível de fio_afiado).
func multiplicador_dano() -> float:
	return 1.0 + float(nivel(MELHORIA_FIO_AFIADO)) * 0.06


## Multiplicador de velocidade (+5% por nível de passada_firme).
func multiplicador_velocidade() -> float:
	return 1.0 + float(nivel(MELHORIA_PASSADA_FIRME)) * 0.05


## Cargas extras de esquiva (+1 por nível de reserva_esquiva).
func bonus_cargas_esquiva() -> int:
	return nivel(MELHORIA_RESERVA_ESQUIVA)


## Multiplicador de alcance/área (+15% por nível de selo_amplificado).
func multiplicador_alcance() -> float:
	return 1.0 + float(nivel(MELHORIA_SELO_AMPLIFICADO)) * 0.15


## Exporta os níveis atuais para persistência (compatível com PortaDeSecao).
func serializar() -> Dictionary:
	var niveis_str: Dictionary = {}
	for id_m: StringName in ORDEM_MELHORIAS:
		niveis_str[String(id_m)] = nivel(id_m)
	return {
		"versao": 1,
		"niveis": niveis_str,
	}


## Restaura os níveis a partir de um dicionário serializado, limitando ao teto válido.
func desserializar(dados: Dictionary) -> void:
	for id_m: StringName in ORDEM_MELHORIAS:
		_niveis[id_m] = 0
	var bruto: Variant = dados.get("niveis", {})
	if typeof(bruto) != TYPE_DICTIONARY:
		return
	var mapa: Dictionary = bruto
	for id_m: StringName in ORDEM_MELHORIAS:
		var chave_str := String(id_m)
		var val: Variant = mapa.get(chave_str, mapa.get(id_m, 0))
		if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
			var max_nv := int(DEFINICOES[id_m]["nivel_max"])
			_niveis[id_m] = clampi(int(val), 0, max_nv)
