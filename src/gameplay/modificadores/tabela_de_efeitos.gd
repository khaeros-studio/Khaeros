class_name TabelaDeEfeitos
extends RefCounted
## Tabela fechada dos 21 tipos de efeito (GDD modificadores-e-atributos R5; ADR-0009 §3,
## "TabelaDeTiposDeEfeito"). É esquema em código, não tuning: tipo → chave do cânone,
## espécie, atributo, operação, condição (com o nome do param), slots e executor.
## Nenhum número de jogo mora aqui: [code]limiar_vida[/code], [code]a_cada[/code],
## [code]janela_s[/code] e os demais vêm dos [code]params[/code] do [EffectDef].
##
## O validador de conteúdo (ADR-0004, V4) recebe a lista por [method registrar_em]:
## o registro [code]tipos_de_efeito[/code] (21 chaves) e o registro dos atributos do
## portador da Maldição (R2, emenda Pactos).
##
## Exemplo:
## [codeblock]
## var linha := TabelaDeEfeitos.linha(&"dano_vida_baixa_pct")
## assert(linha.condicao == Modificador.Condicao.VIDA_ABAIXO)
## TabelaDeEfeitos.registrar_em(registros)
## [/codeblock]

## Espécie do tipo de efeito (R5).
enum Especie { ATRIBUTO, ATRIBUTO_CONDICIONAL, GATILHO, ATRIBUTO_E_GATILHO }

## Nome do registro de tipos de efeito no validador (referenciado por [EffectDef]).
const REGISTRO_TIPOS: StringName = &"tipos_de_efeito"
## Nome do registro dos atributos aceitos pelo portador da Maldição (V4 ampliada).
const REGISTRO_ATRIBUTOS_MALDICAO: StringName = &"atributos_portador_maldicao"

## Uma linha da tabela R5. Imutável (convenção).
class Linha:
	extends RefCounted
	## Tipo de efeito (chave do dado).
	var tipo: StringName
	## Chave de [code]PlayerMods[/code] no cânone (AC-27).
	var chave_canon: StringName
	## Espécie (atributo, condicional, gatilho, atributo + gatilho).
	var especie: Especie
	## Atributo R2 do modificador gerado (vazio em gatilho puro).
	var atributo: StringName
	## Operação do modificador gerado.
	var operacao: Modificador.Operacao
	## Condição R4 (só em condicional).
	var condicao: Modificador.Condicao
	## Nome do param do [EffectDef] que alimenta a condição (vazio se sem condição).
	var param_condicao: StringName
	## Máscara de slots (0 = todos).
	var slots: int
	## Sistema dono da execução do gatilho (vazio em atributo puro).
	var executor: StringName

	func _init(p_tipo: StringName, p_canon: StringName, p_especie: Especie, p_atributo: StringName,
			p_operacao: Modificador.Operacao, p_condicao: Modificador.Condicao = Modificador.Condicao.NENHUMA,
			p_param: StringName = &"", p_slots: int = 0, p_executor: StringName = &"") -> void:
		tipo = p_tipo
		chave_canon = p_canon
		especie = p_especie
		atributo = p_atributo
		operacao = p_operacao
		condicao = p_condicao
		param_condicao = p_param
		slots = p_slots
		executor = p_executor

	## Verdadeiro se o tipo gera modificador.
	func gera_modificador() -> bool:
		return especie != Especie.GATILHO

	## Verdadeiro se o tipo registra gatilho.
	func gera_gatilho() -> bool:
		return especie == Especie.GATILHO or especie == Especie.ATRIBUTO_E_GATILHO

	## Verdadeiro se o valor do dado entra como (1 + valor) num multiplicador (R5).
	func multiplicador_um_mais() -> bool:
		return especie == Especie.ATRIBUTO_CONDICIONAL and operacao == Modificador.Operacao.MULTIPLICADOR


static var _linhas: Array[Linha] = []
static var _por_tipo: Dictionary[StringName, Linha] = {}


## Os 21 tipos, na ordem da tabela R5 (cópia).
static func tipos() -> Array[StringName]:
	var out: Array[StringName] = []
	for l: Linha in _todas():
		out.append(l.tipo)
	return out


## Os 8 tipos que registram gatilho (R5/R11), na ordem da tabela.
static func tipos_de_gatilho() -> Array[StringName]:
	var out: Array[StringName] = []
	for l: Linha in _todas():
		if l.gera_gatilho():
			out.append(l.tipo)
	return out


## Linha do [param tipo]; null se o tipo não existe.
static func linha(tipo: StringName) -> Linha:
	_todas()
	return _por_tipo.get(tipo, null)


## Verdadeiro se [param tipo] está na lista fechada.
static func existe(tipo: StringName) -> bool:
	return linha(tipo) != null


## Tipo de efeito que gera [param m] (atributo, operação e condição); vazio se nenhum
## (ex.: Abalo, elite). Usado pelo espelho da Maldição (R14, F6).
static func tipo_do_modificador(m: Modificador) -> StringName:
	for l: Linha in _todas():
		if l.gera_modificador() and l.atributo == m.atributo and l.operacao == m.operacao \
				and l.condicao == m.condicao:
			return l.tipo
	return &""


## Entrega ao validador de conteúdo os registros desta tabela (ADR-0004, V4).
static func registrar_em(registros: RegistrosDeChaves) -> void:
	registros.registrar(REGISTRO_TIPOS, tipos())
	registros.registrar(REGISTRO_ATRIBUTOS_MALDICAO, Atributos.DA_MALDICAO.duplicate())


static func _todas() -> Array[Linha]:
	if _linhas.is_empty():
		_montar()
	return _linhas


static func _montar() -> void:
	const A := Especie.ATRIBUTO
	const AC := Especie.ATRIBUTO_CONDICIONAL
	const G := Especie.GATILHO
	const AG := Especie.ATRIBUTO_E_GATILHO
	const PL := Modificador.Operacao.PLANO
	const PC := Modificador.Operacao.PERCENTUAL
	const MU := Modificador.Operacao.MULTIPLICADOR
	const C := Modificador.Condicao
	var ae: int = Modificador.MASCARA_ATAQUE | Modificador.MASCARA_ESPECIAL
	var l: Array[Linha] = [
		Linha.new(&"dano_ataque_pct", &"attackDmg", A, Atributos.DANO_ATAQUE, PC),
		Linha.new(&"dano_especial_pct", &"specialDmg", A, Atributos.DANO_ESPECIAL, PC),
		Linha.new(&"dano_selo_pct", &"castDmg", A, Atributos.DANO_SELO, PC),
		Linha.new(&"dano_todo_pct", &"allDmg", A, Atributos.DANO_TODO, PC),
		Linha.new(&"dano_vida_baixa_pct", &"lowHpDmg", AC, Atributos.DANO_TODO, PC, C.VIDA_ABAIXO, &"limiar_vida"),
		Linha.new(&"dano_enesimo_acerto", &"nthHitDouble", AC, Atributos.DANO_TODO, MU, C.ENESIMO_ACERTO, &"a_cada", ae),
		Linha.new(&"dano_apos_esquiva", &"dashEmpower", AC, Atributos.DANO_TODO, MU, C.APOS_ESQUIVA, &"janela_s", ae),
		Linha.new(&"vida_max_plano", &"maxHp", A, Atributos.VIDA_MAX, PL),
		Linha.new(&"velocidade_pct", &"moveSpeed", A, Atributos.VELOCIDADE, PC),
		Linha.new(&"reducao_dano", &"damageReduction", A, Atributos.REDUCAO_DANO, PL),
		Linha.new(&"cargas_esquiva", &"extraDash", A, Atributos.CARGAS_ESQUIVA, PL),
		Linha.new(&"escudo_sala", &"roomShield", A, Atributos.ESCUDO_SALA, PL),
		Linha.new(&"trocas_oferta", &"boonRerolls", A, Atributos.TROCAS_OFERTA, PL),
		Linha.new(&"recusas_morte", &"deathDefiance", AG, Atributos.RECUSAS_MORTE, PL, C.NENHUMA, &"", 0, &"combate"),
		Linha.new(&"golpe_sangramento", &"attackBleed", G, &"", PL, C.NENHUMA, &"", 0, &"efeitos_de_status"),
		Linha.new(&"golpe_queimadura", &"attackBurn", G, &"", PL, C.NENHUMA, &"", 0, &"efeitos_de_status"),
		Linha.new(&"corte_da_esquiva", &"dashDamage", G, &"", PL, C.NENHUMA, &"", 0, &"combate"),
		Linha.new(&"explosao_ao_abater", &"killExplode", G, &"", PL, C.NENHUMA, &"", 0, &"combate"),
		Linha.new(&"cura_ao_abater", &"healOnKill", G, &"", PL, C.NENHUMA, &"", 0, &"combate"),
		Linha.new(&"refletir_dano", &"reflect", G, &"", PL, C.NENHUMA, &"", 0, &"combate"),
		Linha.new(&"selo_abala", &"castWeaken", G, &"", PL, C.NENHUMA, &"", 0, &"selo"),
	]
	_linhas = l
	for x: Linha in l:
		_por_tipo[x.tipo] = x
