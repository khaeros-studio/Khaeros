class_name SeletorDeTonsDosTelegrafosTest
extends GdUnitTestSuite
## Testes unitários do `SeletorDeTons` (ADR-0016 §3, story-003).


func _criar_vista(
	slot: int,
	p: float,
	seq: int,
	estado: TelegrafoTipos.Estado = TelegrafoTipos.Estado.CRESCENDO,
	faccao: TelegrafoTipos.FaccaoAlvo = TelegrafoTipos.FaccaoAlvo.JOGADOR
) -> VistaDeTelegrafo:
	var v: VistaDeTelegrafo = VistaDeTelegrafo.new()
	v.slot = slot
	v.p = p
	v.seq = seq
	v.estado = estado
	v.alvo_faccao = faccao
	return v


func test_seleciona_ate_3_em_crescendo_ordenados_por_p_e_menor_seq() -> void:
	var tuning: AudioTuning = AudioTuning.new()
	var vistas: Array[VistaDeTelegrafo] = [
		_criar_vista(0, 0.30, 10),
		_criar_vista(1, 0.80, 12),
		_criar_vista(2, 0.80, 5), # empate de p com slot 1, mas seq menor -> vem antes
		_criar_vista(3, 0.95, 20, TelegrafoTipos.Estado.DISPARO), # ignorado (não está em CRESCENDO)
		_criar_vista(4, 0.50, 8),
	]
	var slots: PackedInt32Array = PackedInt32Array([0, 0, 0])
	var pitches: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
	var faccoes: PackedInt32Array = PackedInt32Array([0, 0, 0])

	var n: int = SeletorDeTons.selecionar(vistas, vistas.size(), 3, slots, pitches, tuning, faccoes)
	assert_that(n).is_equal(3)
	assert_that(slots[0]).is_equal(2)
	assert_that(slots[1]).is_equal(1)
	assert_that(slots[2]).is_equal(4)
	assert_that(pitches[0]).is_equal_approx(1.80, 0.001)
	assert_that(pitches[2]).is_equal_approx(1.50, 0.001)


func test_distingue_pitch_de_telegrafo_mirado_no_jogador_vs_maldicao() -> void:
	var tuning: AudioTuning = AudioTuning.new()
	tuning.tom_pitch_min = 1.0
	tuning.tom_pitch_max = 2.0
	tuning.tom_maldicao_fator_pitch = 0.80

	var vistas: Array[VistaDeTelegrafo] = [
		_criar_vista(0, 0.50, 1, TelegrafoTipos.Estado.CRESCENDO, TelegrafoTipos.FaccaoAlvo.JOGADOR),
		_criar_vista(1, 0.50, 2, TelegrafoTipos.Estado.CRESCENDO, TelegrafoTipos.FaccaoAlvo.ALIADO),
	]
	var slots: PackedInt32Array = PackedInt32Array([0, 0, 0])
	var pitches: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
	var faccoes: PackedInt32Array = PackedInt32Array([0, 0, 0])

	var n: int = SeletorDeTons.selecionar(vistas, 2, 3, slots, pitches, tuning, faccoes)
	assert_that(n).is_equal(2)
	assert_that(pitches[0]).is_equal_approx(1.50, 0.001)
	assert_that(pitches[1]).is_equal_approx(1.50 * 0.80, 0.001)
	assert_that(faccoes[0]).is_equal(int(TelegrafoTipos.FaccaoAlvo.JOGADOR))
	assert_that(faccoes[1]).is_equal(int(TelegrafoTipos.FaccaoAlvo.ALIADO))
