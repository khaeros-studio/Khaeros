class_name SeletorDeTons
extends RefCounted
## Seletor puro dos até 3 tons ascendentes de telégrafo (`ADR-0016 §3`).
## Seleciona apenas telégrafos em `CRESCENDO`, ordena por maior `p` (empate: menor `seq`),
## calcula pitch linear `[tom_pitch_min, tom_pitch_max]` e distingue telégrafo mirado
## no jogador (`FaccaoAlvo.JOGADOR`) vs na Maldição (`FaccaoAlvo.ALIADO` / `ACUADA`).


static func selecionar(
	vistas: Array[VistaDeTelegrafo],
	quantas: int,
	teto: int,
	slots: PackedInt32Array,
	pitches: PackedFloat32Array,
	tuning: AudioTuning = null,
	alvos_faccao: PackedInt32Array = PackedInt32Array()
) -> int:
	var limite_vistas: int = mini(quantas, vistas.size())
	var teto_efetivo: int = clampi(teto, 0, mini(slots.size(), pitches.size()))
	if tuning != null:
		teto_efetivo = mini(teto_efetivo, tuning.teto_tons_telegrafo)
	if limite_vistas <= 0 or teto_efetivo <= 0:
		return 0

	var p_min: float = tuning.tom_pitch_min if tuning != null else 1.0
	var p_max: float = tuning.tom_pitch_max if tuning != null else 2.0
	var fator_maldicao: float = tuning.tom_maldicao_fator_pitch if tuning != null else 0.85

	# Coleta índices candidatos em estado CRESCENDO
	var candidatos: PackedInt32Array = PackedInt32Array()
	for i: int in range(limite_vistas):
		var v: VistaDeTelegrafo = vistas[i]
		if v == null:
			continue
		if v.estado == TelegrafoTipos.Estado.CRESCENDO:
			candidatos.append(i)

	var total_cand: int = candidatos.size()
	if total_cand == 0:
		return 0

	# Ordena candidatos por maior p; empate por menor seq
	for i: int in range(1, total_cand):
		var idx_chave: int = candidatos[i]
		var v_chave: VistaDeTelegrafo = vistas[idx_chave]
		var j: int = i - 1
		while j >= 0:
			var v_j: VistaDeTelegrafo = vistas[candidatos[j]]
			var trocar: bool = false
			if v_chave.p > v_j.p:
				trocar = true
			elif is_equal_approx(v_chave.p, v_j.p) and v_chave.seq < v_j.seq:
				trocar = true
			if not trocar:
				break
			candidatos[j + 1] = candidatos[j]
			j -= 1
		candidatos[j + 1] = idx_chave

	var escolhidos: int = mini(total_cand, teto_efetivo)
	for k: int in range(escolhidos):
		var v_sel: VistaDeTelegrafo = vistas[candidatos[k]]
		slots[k] = v_sel.slot
		var p_clamped: float = clampf(v_sel.p, 0.0, 1.0)
		var pitch_base: float = lerpf(p_min, p_max, p_clamped)
		if v_sel.alvo_faccao != TelegrafoTipos.FaccaoAlvo.JOGADOR:
			pitch_base = maxf(0.25, pitch_base * fator_maldicao)
		pitches[k] = pitch_base
		if k < alvos_faccao.size():
			alvos_faccao[k] = int(v_sel.alvo_faccao)

	return escolhidos
