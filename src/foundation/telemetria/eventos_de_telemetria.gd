## Eventos tipados do passo consumidos pela Telemetria local (ADR-0002; ADR-0013 §5;
## GDD telemetria-local.md R4, R4-P, R5).
##
## A Telemetria aceita tanto estas classes tipadas quanto as classes dos módulos donos
## (`EvOfertaAberta`, `EvOfertaTrocada`, `EvBencaoTomada`, `EvSaldoMudou`, `EvPassoVivo`)
## ou qualquer subclasse de `EventoDoPasso` com o mesmo `tipo()` (duck-typed por propriedades).
## Todos os payloads guardam apenas valores (sem `Node`, sem referência ao canal).
##
## Exemplo:
## [codeblock]
## eventos.emitir(EventosDeTelemetria.EvCamaraEntrou.new(0, 0, &"combate", 80))
## [/codeblock]
class_name EventosDeTelemetria
extends RefCounted


## Evento `run_iniciada`: emitido quando a seed nasce (ao confirmar a arma, ou em `dupla_confirmada` com Pactos).
class EvRunIniciada extends EventoDoPasso:
	const TIPO: StringName = &"run_iniciada"
	var seed_texto: String
	var impressao: String
	var regiao: String
	var estado_inicial: Dictionary

	func _init(p_seed_texto: String, p_impressao: String, p_regiao: String, p_estado_inicial: Dictionary) -> void:
		seed_texto = p_seed_texto
		impressao = p_impressao
		regiao = p_regiao
		estado_inicial = p_estado_inicial.duplicate(true)

	func tipo() -> StringName:
		return TIPO


## Evento `camara_entrou` (R5): avisa a Telemetria que uma câmara começou e zera os contadores.
class EvCamaraEntrou extends EventoDoPasso:
	const TIPO: StringName = &"camara_entrou"
	var indice: int
	var p: int
	var tipo_camara: StringName
	var vida_max: int
	var vida_atual: int

	func _init(p_indice: int, p_p: int, p_tipo_camara: StringName, p_vida_max: int = 80, p_vida_atual: int = -1) -> void:
		indice = p_indice
		p = p_p
		tipo_camara = p_tipo_camara
		vida_max = p_vida_max
		vida_atual = p_vida_atual if p_vida_atual >= 0 else p_vida_max

	func tipo() -> StringName:
		return TIPO


## Evento `camara_limpa` (R4, R5): fecha a câmara atual com `resultado = "limpa"` (salvo morte no mesmo passo).
class EvCamaraLimpa extends EventoDoPasso:
	const TIPO: StringName = &"camara_limpa"
	var p: int
	var tipo_camara: StringName
	var vida_fim: int

	func _init(p_p: int = 0, p_tipo_camara: StringName = &"combate", p_vida_fim: int = -1) -> void:
		p = p_p
		tipo_camara = p_tipo_camara
		vida_fim = p_vida_fim

	func tipo() -> StringName:
		return TIPO


## Evento `jogador_atingido` (R5): `vida_perdida` soma em `dano_recebido` (o que o escudo absorveu não entra).
class EvJogadorAtingido extends EventoDoPasso:
	const TIPO: StringName = &"jogador_atingido"
	var vida_perdida: int
	var escudo_absorvido: int
	var vida_restante: int
	var recusou_morte: bool

	func _init(p_vida_perdida: int, p_escudo_absorvido: int = 0, p_vida_restante: int = -1, p_recusou_morte: bool = false) -> void:
		vida_perdida = p_vida_perdida
		escudo_absorvido = p_escudo_absorvido
		vida_restante = p_vida_restante
		recusou_morte = p_recusou_morte

	func tipo() -> StringName:
		return TIPO


## Evento `recusou_morte` (R5, AC-TL-10): não é morte; não grava linha `morte` e não desconta a recuperação do `dano_recebido`.
class EvRecusouMorte extends EventoDoPasso:
	const TIPO: StringName = &"recusou_morte"
	var vida_recuperada: int
	var vida_atual: int

	func _init(p_vida_recuperada: int = 0, p_vida_atual: int = -1) -> void:
		vida_recuperada = p_vida_recuperada
		vida_atual = p_vida_atual

	func tipo() -> StringName:
		return TIPO


## Evento `inimigo_morreu` (R5): incrementa `abates` na câmara em curso.
class EvInimigoMorreu extends EventoDoPasso:
	const TIPO: StringName = &"inimigo_morreu"
	var alvo_id: int

	func _init(p_alvo_id: int = 0) -> void:
		alvo_id = p_alvo_id

	func tipo() -> StringName:
		return TIPO


## Evento `porta_escolhida` (R4, AC-TL-09): grava linha `porta` com `indice_camara`, `tipo` e `opcoes`.
class EvPortaEscolhida extends EventoDoPasso:
	const TIPO: StringName = &"porta_escolhida"
	var indice_camara: int
	var tipo_escolhido: StringName
	var opcoes: Array[StringName]

	func _init(p_indice_camara: int, p_tipo_escolhido: StringName, p_opcoes: Array[StringName]) -> void:
		indice_camara = p_indice_camara
		tipo_escolhido = p_tipo_escolhido
		opcoes = p_opcoes.duplicate()

	func tipo() -> StringName:
		return TIPO


## Evento `jogador_morreu` (R4, R5, AC-TL-10, AC-TL-29): fecha a câmara com `resultado = "morte"`
## (vencendo `camara_limpa` no mesmo passo) e grava linha `morte`. Se `causa_tipo_inimigo` e
## `causa_ataque` forem vazios, `causa` sai `null` sem `TL3`.
class EvJogadorMorreu extends EventoDoPasso:
	const TIPO: StringName = &"jogador_morreu"
	var indice_camara: int
	var vida_max: int
	var causa_tipo_inimigo: StringName
	var causa_ataque: StringName

	func _init(p_indice_camara: int = -1, p_vida_max: int = -1,
			p_causa_tipo_inimigo: StringName = &"", p_causa_ataque: StringName = &"") -> void:
		indice_camara = p_indice_camara
		vida_max = p_vida_max
		causa_tipo_inimigo = p_causa_tipo_inimigo
		causa_ataque = p_causa_ataque

	func tipo() -> StringName:
		return TIPO


## Evento `run_encerrada` (R4, R4-P, R12, AC-TL-11, AC-TL-35): fecha a câmara em curso (se ainda aberta
## em abandono) e grava `run_encerrada` com o resumo (10 ou 12 campos), `caminho` e `fragmentos_por_origem`.
class EvRunEncerrada extends EventoDoPasso:
	const TIPO: StringName = &"run_encerrada"
	var resumo: Dictionary
	var caminho: Array

	func _init(p_resumo: Dictionary, p_caminho: Array = []) -> void:
		resumo = p_resumo.duplicate(true)
		caminho = p_caminho.duplicate(true)

	func tipo() -> StringName:
		return TIPO


## Evento `encontro_pacto` (R4-P, AC-TL-36): resultado do encontro de pacto na câmara.
class EvEncontroPacto extends EventoDoPasso:
	const TIPO: StringName = &"encontro_pacto"
	var indice_camara: int
	var especie: StringName
	var resultado: StringName
	var vida_restante: int

	func _init(p_indice_camara: int, p_especie: StringName, p_resultado: StringName, p_vida_restante: int) -> void:
		indice_camara = p_indice_camara
		especie = p_especie
		resultado = p_resultado
		vida_restante = p_vida_restante

	func tipo() -> StringName:
		return TIPO


## Evento `pacto_registrado` (ou `pacto`, R4-P, AC-TL-37): grava linha `pacto` com `especie` e `origem`.
class EvPactoRegistrado extends EventoDoPasso:
	const TIPO: StringName = &"pacto_registrado"
	var especie: StringName
	var origem: StringName

	func _init(p_especie: StringName, p_origem: StringName) -> void:
		especie = p_especie
		origem = p_origem

	func tipo() -> StringName:
		return TIPO


## Evento `vinculo_atualizado` (ou `vinculo_fim_run`, R4-P, AC-TL-38): grava linha `vinculo_fim_run`
## logo após `run_encerrada`, mantendo o mesmo número de `run`.
class EvVinculoAtualizado extends EventoDoPasso:
	const TIPO: StringName = &"vinculo_atualizado"
	var especies: Array[Dictionary]

	func _init(p_especies: Array[Dictionary]) -> void:
		especies = p_especies.duplicate(true)

	func tipo() -> StringName:
		return TIPO
