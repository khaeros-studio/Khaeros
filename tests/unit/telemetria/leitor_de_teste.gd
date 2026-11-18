## Leitor de `.jsonl` exclusivo para testes e ferramentas (GDD telemetria-local.md R1, R10, R11, F2;
## stories telemetria-local/005 e 010; AC-TL-22, AC-TL-27, AC-TL-30).
##
## Mora em `tests/unit/telemetria/` (nunca em `src/`), para que o código do jogo nunca tenha
## símbolo de leitura do arquivo `.jsonl` (AC-TL-30).
## Tolera fechamento brusco (R10): ignora qualquer linha que não seja JSON válido (ex.: última
## linha truncada) e informa se a sessão terminou de forma abrupta (sem `sessao_encerrada`).
class_name LeitorDeTesteTelemetria
extends RefCounted


## Resultado da leitura de um arquivo `.jsonl` de sessão.
class ResultadoLeitura extends RefCounted:
	var linhas: Array[Dictionary] = []
	var linhas_truncadas_ignoradas: int = 0
	var sessao_abrupta: bool = true


## Analisa o conteúdo textual de um `.jsonl` de telemetria (R10, AC-TL-22).
static func ler_jsonl(texto: String) -> ResultadoLeitura:
	var res := ResultadoLeitura.new()
	if texto.is_empty():
		return res
	var brutas := texto.split("\n")
	for i in brutas.size():
		var l := brutas[i].strip_edges()
		if l.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(l)
		if parsed is Dictionary:
			res.linhas.append(parsed as Dictionary)
		else:
			res.linhas_truncadas_ignoradas += 1
	if not res.linhas.is_empty():
		var ultima := res.linhas[res.linhas.size() - 1]
		if String(ultima.get("t", "")) == "sessao_encerrada":
			res.sessao_abrupta = false
	return res


## F2 (AC-TL-27): calcula `dano_rel = dano_recebido / vida_max` para cada linha `camara` lida.
static func calcular_dano_rel_por_camara(linhas: Array[Dictionary]) -> Array[float]:
	var saida: Array[float] = []
	for l: Dictionary in linhas:
		if String(l.get("t", "")) != "camara":
			continue
		var vmax := float(l.get("vida_max", 0))
		var dano := float(l.get("dano_recebido", 0))
		saida.append(dano / vmax if vmax > 0.0 else 0.0)
	return saida
