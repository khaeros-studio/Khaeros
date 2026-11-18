class_name ResumoDaRun
extends RefCounted
## Resumo imutável de 12 campos montado uma única vez ao encerrar a run
## (GDD run-e-regioes.md R7, R7-P, F2, F2-P, F3; ADR-0015 §8).
##
## Imutável por construção:
## - Todos os valores são fixados em [method _init] e expostos apenas por métodos getters;
## - Não há setters nem propriedades públicas mutáveis;
## - Os arrays [code]bencaos_tomadas[/code] e [code]dupla[/code] são duplicados em [method _init],
##   marcados com [method Array.make_read_only] e cada getter devolve uma cópia somente leitura;
## - [method total] é derivado e fixo: [code]fragmentos_coletados + bonus_vitoria[/code] (F2/F2-P);
## - [method duracao_s] é derivado de [code]duracao_passos / 60.0[/code] (F3, incluindo passos de hitstop).

const MOTIVO_VITORIA: StringName = &"vitoria"
const MOTIVO_MORTE: StringName = &"morte"
const MOTIVO_ABANDONO: StringName = &"abandono"

const DESFECHO_ABATIDO: StringName = &"abatido"
const DESFECHO_EXORCIZADO: StringName = &"exorcizado"
const DESFECHO_PACTUADO: StringName = &"pactuado"
const DESFECHO_NENHUM: StringName = &"nenhum"

var _motivo: StringName
var _seed_texto: String
var _arma: StringName
var _camaras_limpas: int
var _bencaos_tomadas: Array[StringName] = []
var _fragmentos_coletados: int
var _bonus_vitoria: int
var _total: int
var _abates: int
var _duracao_passos: int
var _desfecho_chefe: StringName
var _dupla: Array[StringName] = []


func _init(p_motivo: StringName, p_seed_texto: String, p_arma: StringName, p_camaras_limpas: int,
		p_bencaos_tomadas: Array[StringName], p_fragmentos_coletados: int, p_bonus_vitoria: int,
		p_abates: int, p_duracao_passos: int, p_desfecho_chefe: StringName = DESFECHO_NENHUM,
		p_dupla: Array[StringName] = []) -> void:
	_motivo = p_motivo
	_seed_texto = p_seed_texto
	_arma = p_arma
	_camaras_limpas = maxi(0, p_camaras_limpas)
	_bencaos_tomadas = p_bencaos_tomadas.duplicate()
	_bencaos_tomadas.make_read_only()
	_fragmentos_coletados = maxi(0, p_fragmentos_coletados)
	_bonus_vitoria = maxi(0, p_bonus_vitoria) if p_motivo == MOTIVO_VITORIA else 0
	_total = _fragmentos_coletados + _bonus_vitoria
	_abates = maxi(0, p_abates)
	_duracao_passos = maxi(0, p_duracao_passos)
	_desfecho_chefe = p_desfecho_chefe if p_desfecho_chefe != &"" else DESFECHO_NENHUM
	_dupla = p_dupla.duplicate()
	_dupla.make_read_only()


## 1. Motivo do encerramento: [code]&"vitoria"[/code], [code]&"morte"[/code] ou [code]&"abandono"[/code].
func motivo() -> StringName:
	return _motivo


## 2. Texto formatado da seed (RNG R8/F9).
func seed_texto() -> String:
	return _seed_texto


## 3. Id da arma escolhida ([code]&"lamina"[/code], [code]&"ressonancia"[/code] ou [code]&"pactos"[/code]).
func arma() -> StringName:
	return _arma


## 4. Quantidade de câmaras limpas (santuário e chefe contam; vitória no Limiar = 7, ou 6 sem chefe).
func camaras_limpas() -> int:
	return _camaras_limpas


## 5. Ids das bênçãos tomadas na ordem de obtenção (cópia somente leitura).
func bencaos_tomadas() -> Array[StringName]:
	var copia: Array[StringName] = _bencaos_tomadas.duplicate()
	copia.make_read_only()
	return copia


## 6. Fragmentos coletados durante a run antes do bônus de vitória (portas + chefe).
func fragmentos_coletados() -> int:
	return _fragmentos_coletados


## 7. Bônus efetivo de Fragmentos pela vitória (15 na vitória, 0 na morte ou abandono).
func bonus_vitoria() -> int:
	return _bonus_vitoria


## 8. Total de Fragmentos da run: [code]fragmentos_coletados() + bonus_vitoria()[/code] (F2/F2-P).
func total() -> int:
	return _total


## 9. Total de inimigos abatidos na run.
func abates() -> int:
	return _abates


## Passos iniciados em estado [code]JOGO[/code] (incluindo hitstop, F3).
func duracao_passos() -> int:
	return _duracao_passos


## 10. Duração em segundos para exibição: [code]duracao_passos / 60.0[/code] (F3).
func duracao_s() -> float:
	return OrquestradorDoPasso.duracao_s(_duracao_passos)


## 11. Desfecho do chefe (R7-P): [code]&"abatido"[/code], [code]&"exorcizado"[/code],
## [code]&"pactuado"[/code] ou [code]&"nenhum"[/code].
func desfecho_chefe() -> StringName:
	return _desfecho_chefe


## 12. Dupla de Maldições inicial [code][campo, reserva][/code] (vazia fora de Pactos; cópia somente leitura, R7-P).
func dupla() -> Array[StringName]:
	var copia: Array[StringName] = _dupla.duplicate()
	copia.make_read_only()
	return copia


## Dicionário serializável com os 12 campos (para Telemetria e inspeção).
func para_dicionario() -> Dictionary[String, Variant]:
	var b_str: Array[String] = []
	for b: StringName in _bencaos_tomadas:
		b_str.append(String(b))
	var d_str: Array[String] = []
	for d: StringName in _dupla:
		d_str.append(String(d))
	return {
		"motivo": String(_motivo),
		"seed_texto": _seed_texto,
		"arma": String(_arma),
		"camaras_limpas": _camaras_limpas,
		"bencaos_tomadas": b_str,
		"fragmentos_coletados": _fragmentos_coletados,
		"bonus_vitoria": _bonus_vitoria,
		"total": _total,
		"abates": _abates,
		"duracao_s": duracao_s(),
		"desfecho_chefe": String(_desfecho_chefe),
		"dupla": d_str,
	}
