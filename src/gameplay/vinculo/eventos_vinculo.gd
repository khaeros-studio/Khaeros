class_name EventosVinculo
extends RefCounted
## Eventos emitidos pelo sistema de Vínculo e pactos no canal do passo (ADR-0002, ADR-0013, ADR-0015;
## GDD vinculo-e-pactos.md V3, V10, V12, V16, V18, V20, V45).


## Gatilho de gravação do Save quando um pacto é firmado ou reafirmado no chefe (V3, V10, V18, V32).
class EvPactoRegistrado:
	extends EventoDoPasso
	const TIPO: StringName = &"pacto_registrado"

	var especie_id: StringName
	var origem: StringName # &"primeiro" | &"encontro" | &"chefe"

	func _init(p_especie_id: StringName, p_origem: StringName = &"encontro") -> void:
		especie_id = p_especie_id
		origem = p_origem

	func tipo() -> StringName:
		return TIPO


## Evento para Telemetria / Áudio quando um pacto é formado (`pacto`, V45, AC-TL-37).
class EvPactoFormado:
	extends EventoDoPasso
	const TIPO: StringName = &"pacto"

	var especie: StringName
	var origem: StringName # &"primeiro" | &"encontro" | &"chefe"

	func _init(p_especie: StringName, p_origem: StringName) -> void:
		especie = p_especie
		origem = p_origem

	func tipo() -> StringName:
		return TIPO


## Emitido ao confirmar a dupla de Maldições no início da run de Pactos (V16b, ADR-0015 §3).
class EvDuplaConfirmada:
	extends EventoDoPasso
	const TIPO: StringName = &"dupla_confirmada"

	var campo: StringName
	var reserva: StringName
	var abriu_tela: bool

	func _init(p_campo: StringName, p_reserva: StringName = &"", p_abriu_tela: bool = false) -> void:
		campo = p_campo
		reserva = p_reserva
		abriu_tela = p_abriu_tela

	func tipo() -> StringName:
		return TIPO


## Emitido quando a acuada perde toda a Vida e foge pela fenda (V12, ADR-0015 §5).
class EvEncontroFalhou:
	extends EventoDoPasso
	const TIPO: StringName = &"encontro_falhou"

	var indice_camara: int
	var especie: StringName

	func _init(p_indice_camara: int, p_especie: StringName) -> void:
		indice_camara = p_indice_camara
		especie = p_especie

	func tipo() -> StringName:
		return TIPO


## Emitido para a Telemetria com o desfecho do encontro de pacto (`encontro_pacto`, V45, AC-TL-36).
class EvEncontroPacto:
	extends EventoDoPasso
	const TIPO: StringName = &"encontro_pacto"

	var indice_camara: int
	var especie: StringName
	var resultado: StringName # &"pactuada" | &"reafirmada" | &"deixada" | &"voltara" | &"fugiu" | &"abandonado"
	var vida_restante: int

	func _init(p_indice: int, p_especie: StringName, p_resultado: StringName, p_vida_restante: int) -> void:
		indice_camara = p_indice
		especie = p_especie
		resultado = p_resultado
		vida_restante = p_vida_restante

	func tipo() -> StringName:
		return TIPO


## Emitido ao fechar a tela de consentimento para liberar as Portas no passo 2b (V9, V41).
class EvPactoResolvido:
	extends EventoDoPasso
	const TIPO: StringName = &"pacto_resolvido"

	var especie: StringName
	var resultado: StringName

	func _init(p_especie: StringName, p_resultado: StringName) -> void:
		especie = p_especie
		resultado = p_resultado

	func tipo() -> StringName:
		return TIPO


## Emitido ao escolher Pactuar ou Exorcizar no chefe Subjugado (V18, V47).
class EvChefeEscolhido:
	extends EventoDoPasso
	const TIPO: StringName = &"chefe_escolhido"

	var chefe_id: StringName
	var escolha: StringName # &"pactuar" | &"exorcizar"

	func _init(p_chefe_id: StringName, p_escolha: StringName) -> void:
		chefe_id = p_chefe_id
		escolha = p_escolha

	func tipo() -> StringName:
		return TIPO


## Emitido na consolidação de fim de run por espécie da dupla (`vinculo_fim_run`, V20, V45, AC-TL-38).
class EvVinculoGanho:
	extends EventoDoPasso
	const TIPO: StringName = &"vinculo_fim_run"

	var especie: StringName
	var pontos_run: int
	var vinculo_pontos: int
	var nivel: int
	var subiu_nivel: bool

	func _init(p_especie: StringName, p_pontos_run: int, p_vinculo_pontos: int,
			p_nivel: int, p_subiu_nivel: bool) -> void:
		especie = p_especie
		pontos_run = p_pontos_run
		vinculo_pontos = p_vinculo_pontos
		nivel = p_nivel
		subiu_nivel = p_subiu_nivel

	func tipo() -> StringName:
		return TIPO


## Emitido após consolidar toda a run no perfil (V20 passo 4).
class EvVinculoAtualizado:
	extends EventoDoPasso
	const TIPO: StringName = &"vinculo_atualizado"

	var registros: Array[EvVinculoGanho] = []

	func _init(p_registros: Array[EvVinculoGanho] = []) -> void:
		registros = p_registros.duplicate()
		registros.make_read_only()

	func tipo() -> StringName:
		return TIPO
