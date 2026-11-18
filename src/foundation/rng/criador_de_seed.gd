## Nascimento da seed da run (GDD rng-com-seed.md R2, R2-P, Edge Cases "Seed";
## ADR-0005 "Ciclo de vida"; ADR-0015 para o momento).
##
## Recebe por injeção a entropia, o tipo de build e os argumentos de linha de
## comando (R9). Em debug, `--seed=` (ou o campo do menu de debug) informa a
## seed; texto inválido impede a run e nunca cai em entropia em silêncio. Em
## release, `--seed=` é ignorado e registrado. A seed sai mascarada em u32.
class_name CriadorDeSeed
extends RefCounted

## Prefixo do argumento de linha de comando.
const PREFIXO_DO_ARGUMENTO: String = "--seed="
## Texto do aviso em release (R2).
const AVISO_RELEASE: String = "seed ignorada em release"
## Doutrina cuja seed nasce em `dupla_confirmada` (R2-P).
const DOUTRINA_PACTOS: StringName = &"pactos"


## Resultado da criação: `criada` com `seed` u32, ou `mensagem` de erro.
class ResultadoDaSeed:
	extends RefCounted
	## Verdadeiro se a seed existe e a run pode ser criada.
	var criada: bool = false
	## Seed u32 (só vale com `criada`).
	var seed: int = 0
	## Erro para mostrar ao jogador/desenvolvedor (vazio quando criada).
	var mensagem: String = ""


var _entropia: FonteDeEntropia
var _eh_debug: bool = false
var _argumentos: PackedStringArray
var _relator: RelatorDeErrosRng


## `eh_debug` e `argumentos` vêm do ponto de composição (OS/build lidos só lá).
func _init(entropia: FonteDeEntropia, eh_debug: bool, argumentos: PackedStringArray, relator: RelatorDeErrosRng) -> void:
	_entropia = entropia
	_eh_debug = eh_debug
	_argumentos = argumentos
	_relator = relator


## R2-P: verdadeiro se, com esta Doutrina, a seed nasce em `dupla_confirmada`
## em vez de ao confirmar a arma.
static func seed_nasce_na_dupla(doutrina: StringName) -> bool:
	return doutrina == DOUTRINA_PACTOS


## Cria a seed uma única vez por run. `texto_do_campo_debug` é o campo do menu
## de debug (vazio quando não usado); tem precedência sobre `--seed=`.
func criar_seed(texto_do_campo_debug: String = "") -> ResultadoDaSeed:
	var resultado := ResultadoDaSeed.new()
	var informado: String = texto_do_campo_debug
	var tem_informado: bool = not informado.is_empty()
	if not tem_informado:
		for argumento: String in _argumentos:
			if argumento.begins_with(PREFIXO_DO_ARGUMENTO):
				informado = argumento.substr(PREFIXO_DO_ARGUMENTO.length())
				tem_informado = true
				break
	if tem_informado and _eh_debug:
		var parse: TextoDaSeed.ResultadoDoParse = TextoDaSeed.interpretar(informado)
		if not parse.aceito:
			resultado.mensagem = parse.mensagem
			return resultado
		resultado.criada = true
		resultado.seed = parse.valor
		return resultado
	if tem_informado:
		_relator.registrar_aviso("%s: \"%s\"" % [AVISO_RELEASE, informado])
	resultado.criada = true
	resultado.seed = RngAritmetica.mascarar_u32(_entropia.sortear_u32())
	return resultado
