## Story RNG-003, AC-33 (advisory): registra µs/op de 1.000.000 passos e 10.000
## derivações. Sem assert de tempo por decisão do GDD (a medição de orçamento é
## em build de release exportado); regressão > 2× contra a última medição vira
## bug S3. Referência do ADR-0005: ≤ 2 µs por passo, ≤ 5 µs por derivação.
extends GdUnitTestSuite

const PASSOS: int = 1_000_000
const DERIVACOES: int = 10_000


func test_custo_passos_e_derivacoes_registra_us_por_op() -> void:
	var fluxo := FluxoRng.new(0x3F9A07C2, null)
	var inicio: int = Time.get_ticks_usec()
	for i: int in PASSOS:
		fluxo.proximo_u32()
	var us_passo: float = float(Time.get_ticks_usec() - inicio) / PASSOS
	inicio = Time.get_ticks_usec()
	var acumulado: int = 0
	for i: int in DERIVACOES:
		acumulado ^= RngAritmetica.derivar(i, 4, 0, i & 1023)
	var us_derivacao: float = float(Time.get_ticks_usec() - inicio) / DERIVACOES
	print("[AC-33] passo: %.3f us/op | derivacao: %.3f us/op (checksum %08X)" % [us_passo, us_derivacao, acumulado])
	assert_int(fluxo.estado()).is_not_equal(0x3F9A07C2)
