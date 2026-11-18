class_name EvNumeroDeStatus
extends EventoDoPasso
## Evento `numero_de_status(inimigo_id, valor)` (GDD `design/gdd/efeitos-de-status.md` R6, F5;
## ADR-0002 Catálogo de eventos, TR-status-010): emitido a cada janela de agregação
## (`intervalo_numero_s` = `0,5 s` / `30` passos vivos) ou na descarga final quando o
## último status com dano expira, se o valor arredondado for `>= 1`.

const TIPO: StringName = &"numero_de_status"

var inimigo_id: int
var valor: int


func _init(p_inimigo_id: int, p_valor: int) -> void:
	inimigo_id = p_inimigo_id
	valor = p_valor


func tipo() -> StringName:
	return TIPO
