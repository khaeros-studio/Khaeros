class_name EstadoDoChefe
extends RefCounted
## Estado mutável exclusivo do comportamento `chefe`, guardado dentro do registro do inimigo na IA (ADR-0018 §8).

var padrao: int = 0
var em_furia: bool = false
var transicao_ja_ocorreu: bool = false
var transicao_pendente: bool = false
var avancar_padrao_ao_sair: bool = false
var pulso_pendente: bool = false
var subjugavel: bool = false
var ja_feriu_no_avanco: bool = false
var direcao_avanco: Vector2 = Vector2.RIGHT
