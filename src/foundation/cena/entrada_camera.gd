class_name EntradaCamera
extends RefCounted
## Entrada de um quadro de render para `CameraDeApresentacao.atualizar_quadro`
## (ADR-0007 Key Interfaces). Só valores: não retém entidades da simulação.
##
## Exemplo:
## [codeblock]
## var e := EntradaCamera.new()
## e.p_anterior = pos_passo_anterior; e.p_atual = pos_passo_atual
## e.fracao = Engine.get_physics_interpolation_fraction()  # lida no Main
## e.t_apres = relogio.t_apres()
## [/codeblock]

## Fonte de mira resolvida pelo Input (Input R2).
enum FonteMira { MOUSE, ANALOGICO, AUTOMATICA }

## Posição do jogador no passo de física anterior (px de mundo).
var p_anterior: Vector2 = Vector2.ZERO
## Posição do jogador no passo de física atual (px de mundo).
var p_atual: Vector2 = Vector2.ZERO
## Fração de interpolação entre os passos, em [0, 1].
var fracao: float = 0.0
## Relógio de apresentação `t_apres` (s), injetado pelo orquestrador.
var t_apres: float = 0.0
## Fonte de mira da última amostra.
var fonte_mira: FonteMira = FonteMira.MOUSE
## Cursor no espaço Janela (px locais da área de conteúdo), já normalizado.
var cursor_janela: Vector2 = Vector2.ZERO
## Direção do analógico direito (pode ser zero).
var mira_analogico: Vector2 = Vector2.ZERO
## Módulo do analógico depois da zona morta (Input F2), em [0, 1].
var intensidade_mira: float = 0.0
## Opção Redução de movimento (`rm`).
var reducao_movimento: bool = false
## Opção Tremor de câmera (`s_t`), em [0, 1].
var tremor: float = 1.0
## Zoom comandado pela Intro de chefe (1 fora dela).
var zoom_intro: float = 1.0
