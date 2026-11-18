## Seed como texto: formatação e parse estrito (GDD rng-com-seed.md R8, F9;
## ADR-0005 "Seed, telemetria e fronteira").
##
## O parse não usa `String.hex_to_int()` (leniente, e proibido pelo lint):
## aceita 1 a 8 dígitos hex, com hífen só na forma 4+4, sem diferenciar
## maiúsculas; recusa o resto com mensagem que cita o texto digitado.
class_name TextoDaSeed
extends RefCounted

## Texto exibido quando a fonte está em Sem run.
const TEXTO_SEM_SEED: String = "sem seed"
const _DIGITOS_HEX: String = "0123456789ABCDEF"
const _COMPRIMENTO_COM_HIFEN: int = 9
const _POSICAO_DO_HIFEN: int = 4
const _MAXIMO_DE_DIGITOS: int = 8


## Resultado do parse: `aceito` e `valor` u32, ou `mensagem` citando o texto.
class ResultadoDoParse:
	extends RefCounted
	## Verdadeiro se o texto foi aceito.
	var aceito: bool = false
	## Seed u32 lida (0 quando recusado).
	var valor: int = 0
	## Mensagem de recusa (vazia quando aceito).
	var mensagem: String = ""


## F9: seed u32 → "XXXX-XXXX" (9 caracteres maiúsculos).
static func formatar(seed_da_run: int) -> String:
	var u: int = RngAritmetica.mascarar_u32(seed_da_run)
	return "%04X-%04X" % [u >> 16, u & 0xFFFF]


## R8: "3F9A-07C2 · v0.1.0 · c1B4E". `versao` sem o "v"; `impressao_curta`
## são os 4 hex da impressão do catálogo (Conteúdo R12), injetados.
static func rotulo(seed_da_run: int, versao: String, impressao_curta: String) -> String:
	return "%s · v%s · c%s" % [formatar(seed_da_run), versao, impressao_curta]


## Rótulo da seed da fonte, ou [constant TEXTO_SEM_SEED] em Sem run.
static func rotulo_da_fonte(fonte: FonteDeFluxos, versao: String, impressao_curta: String) -> String:
	if not fonte.tem_seed():
		return TEXTO_SEM_SEED
	return rotulo(fonte.seed(), versao, impressao_curta)


## F9 parse estrito. Nunca corrige o texto em silêncio.
static func interpretar(texto: String) -> ResultadoDoParse:
	var resultado := ResultadoDoParse.new()
	var digitos: String = texto
	if digitos.length() == _COMPRIMENTO_COM_HIFEN and digitos[_POSICAO_DO_HIFEN] == "-":
		digitos = digitos.substr(0, _POSICAO_DO_HIFEN) + digitos.substr(_POSICAO_DO_HIFEN + 1)
	if digitos.is_empty() or digitos.length() > _MAXIMO_DE_DIGITOS:
		resultado.mensagem = "Seed invalida: \"%s\" (use 1 a 8 digitos hex, ex.: 3F9A-07C2)" % texto
		return resultado
	var valor: int = 0
	for caractere: String in digitos.to_upper():
		var digito: int = _DIGITOS_HEX.find(caractere)
		if digito < 0:
			resultado.mensagem = "Seed invalida: \"%s\" (caractere \"%s\" nao e hex)" % [texto, caractere]
			return resultado
		valor = (valor << 4) | digito
	resultado.aceito = true
	resultado.valor = valor
	return resultado
