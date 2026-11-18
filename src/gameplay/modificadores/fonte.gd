class_name FonteDeModificador
extends RefCounted
## Fonte de modificadores e gatilhos (GDD modificadores-e-atributos R3/R6; ADR-0009 §3).
##
## [member id] tem prefixo de espécie: [code]bencao:<id>[/code], [code]oficina:<id>[/code],
## [code]status:abalo[/code], [code]elite[/code], [code]chefe[/code], [code]profundidade[/code]
## (e, na Maldição, [code]vinculo:[/code], [code]especie:[/code], [code]espelho:[/code]).
## A fonte é um valor imutável e pode ser compartilhada entre portadores: o estado vivo
## (duração restante) fica em cada [Portador] (AC-15).
##
## Exemplo:
## [codeblock]
## var muro := FonteDeModificador.new(&"bencao:muro_de_pedras",
##         [Modificador.new(Atributos.VIDA_MAX, Modificador.Operacao.PLANO, 25.0)])
## portador.aplicar_fonte(muro)
## [/codeblock]

## Duração de fonte permanente na run.
const PERMANENTE: int = -1

## Id da fonte (chave de substituição e da ordem canônica).
var id: StringName
## Modificadores, na ordem dos efeitos do dado.
var modificadores: Array[Modificador]
## Gatilhos, na ordem dos efeitos do dado.
var gatilhos: Array[GatilhoAtivo]
## Duração em passos inteiros ([constant PERMANENTE] = permanente).
var duracao_passos: int


func _init(p_id: StringName, p_modificadores: Array[Modificador] = [],
		p_gatilhos: Array[GatilhoAtivo] = [], p_duracao_passos: int = PERMANENTE) -> void:
	id = p_id
	modificadores = p_modificadores.duplicate()
	modificadores.make_read_only()
	gatilhos = p_gatilhos.duplicate()
	gatilhos.make_read_only()
	duracao_passos = p_duracao_passos
