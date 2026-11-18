class_name TecnicaDef
extends DadoDeConteudo
## Definição orientada a dados de uma técnica de Maldição (Saída, Entrada, Efeito no Chamado
## ou Habilidade Única Primordial; GDD maldicoes.md R12, R13.5, R16, R18, F5; ADR-0017 §5).

@export var id: StringName = &""
## circulo, arco, avanco.
@export var forma: StringName = &"circulo"
## maldicao, jogador, avanco_alvo.
@export var ancoragem: StringName = &"maldicao"
@export var raio_px: float = 120.0
@export var alcance_avanco_px: float = 0.0
@export var dano: float = 5.0
@export var empurrao: float = 0.0
@export var pesado: bool = false
@export var bonus_sinergia_pct: float = 0.0
## Controle aplicado aos atingidos: "", "imobilizar", "atrair", "puxar".
@export var controle: StringName = &""
@export var duracao_controle_s: float = 0.0
@export var marca_elites_chefes_na_saida: bool = false
@export var puxao_distancia_px: float = 0.0
@export var puxao_parar_a_px: float = 36.0
## Status aplicado aos atingidos (ex.: &"abalo").
@export var status_id: StringName = &""
@export var duracao_status_s: float = 0.0
## Gatilho por ataques básicos concluídos (ex.: 3 no Pulso de Soberania).
@export var a_cada_n_ataques: int = 0
