## Relógio e metadados de plataforma injetados na Telemetria local (ADR-0013 §5; GDD R2, R3, F4).
##
## A lógica da Telemetria nunca lê [code]Time[/code] nem [code]OS[/code] diretamente:
## recebe uma subclasse desta porta. Nos testes unitários entra um relógio falso
## determinístico; na composição real (`Main`) entra o adaptador do sistema.
## Não é thread-safe: uso exclusivo na thread principal.
##
## Exemplo:
## [codeblock]
## var r := RelogioDeSessaoFalso.new("2026-11-18T12:00:00Z")
## assert(r.nome_base_sessao() == "sessao-20261118-120000")
## [/codeblock]
@abstract
class_name RelogioDeSessao
extends RefCounted


## Milissegundos monotônicos desde o início da sessão (`ms` comum de toda linha, R3).
@abstract func agora_ms() -> int


## Microssegundos monotônicos para medir o orçamento F4 de cada linha e passo.
@abstract func agora_us() -> int


## Data/hora UTC ISO-8601 terminada em `"Z"` (ex.: `"2026-11-18T12:00:00Z"`, E-P5).
@abstract func data_utc_iso() -> String


## Família do sistema operacional em minúsculas (`"windows"`, `"linux"`, `"macos"`, R4).
@abstract func familia_os() -> String


## Gera o prefixo `"sessao-AAAAMMDD-HHMMSS"` a partir de [method data_utc_iso] (R2).
func nome_base_sessao() -> String:
	var iso := data_utc_iso().strip_edges()
	# Aceita "YYYY-MM-DDTHH:MM:SSZ" ou "YYYY-MM-DD HH:MM:SS"
	var limpo := iso.replace("-", "").replace(":", "").replace("Z", "").replace(" ", "T")
	var partes := limpo.split("T")
	if partes.size() >= 2 and partes[0].length() >= 8 and partes[1].length() >= 6:
		return "sessao-%s-%s" % [partes[0].substr(0, 8), partes[1].substr(0, 6)]
	return "sessao-00000000-000000"
