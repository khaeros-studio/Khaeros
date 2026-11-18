class_name DependenciasDoCombate
extends RefCounted
## Tudo o que o Combate recebe por injeção (GDD combate-nucleo R16; ADR-0010 §1). Os
## testes montam em memória. [member erro] recebe o erro nomeado de [method Combate.criar].
##
## Exemplo:
## [codeblock]
## var d := DependenciasDoCombate.new()
## d.tuning = tuning; d.movimento = mov
## d.jogadores.append(DependenciasDoCombate.Jogador.new(portador, corte, investida))
## var c := Combate.criar(d)   # null se faltar algo; d.erro diz o quê
## [/codeblock]


## Um jogador: portador e os dois AttackDef da arma.
class Jogador:
	extends RefCounted
	var portador: Portador
	var ataque: AttackDef
	var especial: AttackDef

	func _init(p_portador: Portador, p_ataque: AttackDef, p_especial: AttackDef) -> void:
		portador = p_portador
		ataque = p_ataque
		especial = p_especial


var tuning: CombatTuning
## Índice = player_id.
var jogadores: Array[DependenciasDoCombate.Jogador] = []
var movimento: MovimentoParaCombate
## Opcional (null = Chamado indisponível).
var maldicoes: MaldicoesParaCombate
## Colaboradores de combate (dublês ou reais; quando null, usam implementações neutras).
var ia: ContratosDoCombate.IAParaCombate = null
var camaras: ContratosDoCombate.CamarasParaCombate = null
var selo: ContratosDoCombate.SeloParaCombate = null
var status: ContratosDoCombate.StatusParaCombate = null
var telegrafos: ContratosDoCombate.TelegrafosParaCombate = null
var vinculo: ContratosDoCombate.VinculoParaCombate = null
var eventos: EventosDoPasso = null
## Callable opcional: func(EstadoDeJogo.Valor) -> void, chamado com MORTE no fim do item 9.
var pedir_estado: Callable = Callable()
## Teto de redução de dano do ModifiersTuning (F10, F12; padrão 0,6).
var teto_reducao_dano: float = 0.6
## Erro nomeado da última tentativa de [method Combate.criar] ("" = nenhum).
var erro: StringName = &""

