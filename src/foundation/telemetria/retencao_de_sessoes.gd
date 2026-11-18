## Retenção das últimas `max_sessoes` (20) sessões, limpeza sob demanda ("Apagar dados")
## e resolução de colisão de nomes no mesmo segundo (`-2`, `-3`) (GDD R2, R6, R9, F5; ADR-0013 §5).
##
## Opera exclusivamente sobre `ArmazemDeArquivos` e toca **somente** arquivos cujo nome
## case com `^sessao-\d{8}-\d{6}(-\d+)?\.jsonl$`. Qualquer outro arquivo na pasta (ex.: `outro.txt`)
## nunca é apagado. Falhas ao apagar um arquivo (ex.: aberto por outra instância) geram `TL1`
## no relator e são ignoradas sem interromper a sessão (AC-TL-32).
##
## Exemplo:
## [codeblock]
## RetencaoDeSessoes.aplicar_retencao_na_abertura(armazem, "user://telemetria", 20, avisos)
## var caminho := RetencaoDeSessoes.escolher_caminho_livre(armazem, "user://telemetria", "sessao-20261118-120000")
## [/codeblock]
class_name RetencaoDeSessoes
extends RefCounted

const PADRAO_ARQUIVO_SESSAO: String = "^sessao-\\d{8}-\\d{6}(-\\d+)?\\.jsonl$"


## Verdadeiro se `nome_arquivo` (sem pasta) é um arquivo de sessão canônico `sessao-AAAAMMDD-HHMMSS[-N].jsonl`.
static func eh_arquivo_de_sessao(nome_arquivo: String) -> bool:
	var re := RegEx.create_from_string(PADRAO_ARQUIVO_SESSAO)
	return re.search(nome_arquivo) != null


## Lista apenas os arquivos `sessao-*.jsonl` da `pasta`, ordenados do mais antigo ao mais recente.
## Quando há sufixo `-2`, `-3` no mesmo segundo, o sem sufixo vem antes de `-2`, que vem antes de `-3`.
static func listar_sessoes_ordenadas(armazem: ArmazemDeArquivos, pasta: String) -> Array[String]:
	var todos: PackedStringArray = armazem.listar_arquivos(pasta)
	var sessoes: Array[String] = []
	for nome: String in todos:
		if eh_arquivo_de_sessao(nome):
			sessoes.append(nome)
	sessoes.sort_custom(_comparar_nomes_sessao)
	return sessoes


## F5: ao iniciar a sessão (antes de abrir o novo arquivo), mantém no máximo `max_sessoes - 1`
## existentes para que, com o novo, a pasta tenha no máximo `max_sessoes`.
## `apagar = max(0, existentes - (max_sessoes - 1))`, apagando os mais antigos primeiro (AC-TL-21).
static func aplicar_retencao_na_abertura(armazem: ArmazemDeArquivos, pasta: String,
		max_sessoes: int, avisos: RelatorDeAvisosTelemetria) -> int:
	if max_sessoes <= 0:
		return 0
	var sessoes := listar_sessoes_ordenadas(armazem, pasta)
	var manter := maxi(0, max_sessoes - 1)
	var apagar_qtd := maxi(0, sessoes.size() - manter)
	var apagados := 0
	for i in apagar_qtd:
		var caminho := _juntar(pasta, sessoes[i])
		var err := armazem.apagar(caminho)
		if err == OK:
			apagados += 1
		elif avisos != null:
			avisos.registrar_tl1("falha ao apagar na retencao: %s (err=%d)" % [sessoes[i], err])
	return apagados


## R6 ("Apagar dados"): depois da confirmação do usuário, apaga apenas `sessao-*.jsonl` da `pasta`,
## preservando o `caminho_aberto_atual` se a sessão estiver com arquivo aberto (AC-TL-26, AC-TL-32).
static func apagar_dados(armazem: ArmazemDeArquivos, pasta: String, caminho_aberto_atual: String,
		confirmado: bool, avisos: RelatorDeAvisosTelemetria) -> int:
	if not confirmado:
		return 0
	var sessoes := listar_sessoes_ordenadas(armazem, pasta)
	var nome_aberto := caminho_aberto_atual.get_file() if not caminho_aberto_atual.is_empty() else ""
	var apagados := 0
	for nome: String in sessoes:
		if nome == nome_aberto:
			continue
		var caminho := _juntar(pasta, nome)
		var err := armazem.apagar(caminho)
		if err == OK:
			apagados += 1
		elif avisos != null:
			avisos.registrar_tl1("falha ao apagar dados: %s (err=%d)" % [nome, err])
	return apagados


## R2 (AC-TL-23): escolhe `sessao-AAAAMMDD-HHMMSS.jsonl` ou ganha sufixo `-2`, `-3` se já existir.
static func escolher_caminho_livre(armazem: ArmazemDeArquivos, pasta: String, nome_base: String) -> String:
	var primeiro := _juntar(pasta, "%s.jsonl" % nome_base)
	if not armazem.existe(primeiro):
		return primeiro
	var sufixo := 2
	while true:
		var candidato := _juntar(pasta, "%s-%d.jsonl" % [nome_base, sufixo])
		if not armazem.existe(candidato):
			return candidato
		sufixo += 1
	return primeiro


static func _juntar(pasta: String, arquivo: String) -> String:
	if pasta.ends_with("/"):
		return pasta + arquivo
	return pasta + "/" + arquivo


static func _comparar_nomes_sessao(a: String, b: String) -> bool:
	var base_a := a.trim_suffix(".jsonl")
	var base_b := b.trim_suffix(".jsonl")
	var prefixo_a := base_a.substr(0, 22) # "sessao-AAAAMMDD-HHMMSS"
	var prefixo_b := base_b.substr(0, 22)
	if prefixo_a != prefixo_b:
		return prefixo_a < prefixo_b
	var suf_a := 1 if base_a.length() <= 22 else int(base_a.substr(23))
	var suf_b := 1 if base_b.length() <= 22 else int(base_b.substr(23))
	return suf_a < suf_b
