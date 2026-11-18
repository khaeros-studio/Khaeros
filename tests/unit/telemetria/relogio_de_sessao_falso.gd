## Dublê determinístico de `RelogioDeSessao` para os testes unitários da Telemetria local.
## Permite avançar `ms`, `us`, alterar `data_utc_iso` e simular custo fixo em microssegundos
## a cada consulta de `agora_us()` (para testar orçamentos de linha e passo, F4 / AC-TL-25).
class_name RelogioDeSessaoFalso
extends RelogioDeSessao

var ms_atual: int = 0
var us_atual: int = 0
var data_utc: String = "2026-11-18T12:00:00Z"
var os_familia: String = "windows"
## Avanço automático de `us_atual` a cada chamada de `agora_us()` (útil para simular escrita lenta).
var passo_auto_us: int = 0


func _init(p_data_utc: String = "2026-11-18T12:00:00Z", p_os: String = "windows") -> void:
	data_utc = p_data_utc
	os_familia = p_os


func agora_ms() -> int:
	return ms_atual


func agora_us() -> int:
	var v := us_atual
	us_atual += passo_auto_us
	return v


func data_utc_iso() -> String:
	return data_utc


func familia_os() -> String:
	return os_familia


func avancar_ms(delta_ms: int) -> void:
	ms_atual += delta_ms
	us_atual += delta_ms * 1000
