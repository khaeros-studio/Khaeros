class_name AttackDef
extends DadoDeConteudo
## Ataque ou Especial de uma arma (sub-recurso embutido no WeaponDef). Params de geometria por forma (Combate R3-R7): arco = alcance_px, meio_angulo_graus; projetil = velocidade_pxs, raio_px, vida_s; avanco = distancia_px, duracao_s, raio_px; circulo = raio_px, deslocamento_px; chamado = nenhum (geometria do MaldicoesTuning).
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var a := AttackDef.new(); a.forma = &"arco"; a.params[&"alcance_px"] = alcance
## [/codeblock]

## Chave de tradução do nome; a descrição é a chave derivada <chave_nome>_DESC.
@export var chave_nome: StringName = &""
## Forma registrada pelo Combate: arco, circulo, projetil, avanco, chamado.
@export var forma: StringName = &""
## Params de geometria da forma (nomes acima).
@export var params: Dictionary[StringName, float] = {}
## Ângulos do leque (projetil), em graus.
@export var leque: PackedFloat64Array = PackedFloat64Array()
## Projétil atravessa alvos.
@export var atravessa: bool = false
@export var dano: float = 0.0
@export var recarga_s: float = 0.0
## Preparo antes do golpe; aceita zero (AC-10).
@export var preparo_s: float = 0.0
## Velocidade inicial do empurrão, px/s (R6).
@export var empurrao: float = 0.0
## Status aplicado (opcional).
@export var status: StringName = &""
## Multiplicadores do combo (opcional).
@export var multiplicadores_combo: PackedFloat64Array = PackedFloat64Array()
## Duração da guarda (opcional; Guardião).
@export var guarda_s: float = 0.0


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	e.regra(&"chave_nome").texto(PackedStringArray(["_DESC"]))
	e.regra(&"forma").referencia_registro(&"formas_de_ataque")
	e.regra(&"params").opcional()
	e.regra(&"leque").opcional()
	e.regra(&"atravessa").opcional()
	e.regra(&"dano").min_excl(0.0)
	e.regra(&"recarga_s").min_excl(0.0)
	e.regra(&"preparo_s").min_incl(0.0).aceita_default()
	e.regra(&"empurrao").min_incl(0.0).aceita_default()
	e.regra(&"status").opcional().referencia_registro(&"status")
	e.regra(&"multiplicadores_combo").opcional().min_excl(0.0)
	e.regra(&"guarda_s").opcional().min_incl(0.0)
