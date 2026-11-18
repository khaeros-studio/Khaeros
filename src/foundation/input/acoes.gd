class_name Acoes
extends RefCounted
## Lista fechada de ações do jogo e seus contextos (GDD input-e-controle R1, R1a, R10; ADR-0006 §1, §3).
##
## Nenhuma tecla aparece aqui: só nomes de ação (`StringName`), contextos e as direções internas das ações
## vetoriais. Os binds ficam em `BindsPadrao` (dados embarcados) e no mapa do usuário (story 007).

# --- Ações públicas (R1) ---
const MOVER := &"mover"
const MIRAR := &"mirar"
const ATAQUE := &"ataque"
const ESPECIAL := &"especial"
const SELO := &"selo"
const ESQUIVA := &"esquiva"
const INTERAGIR := &"interagir"
const TROCA := &"troca"
const PAUSAR := &"pausar"
const UI_ACEITAR := &"ui_aceitar"
const UI_VOLTAR := &"ui_voltar"
const UI_NAVEGAR := &"ui_navegar"
const UI_CARTA_1 := &"ui_carta_1"
const UI_CARTA_2 := &"ui_carta_2"
const UI_CARTA_3 := &"ui_carta_3"
const UI_TROCAR_OFERTAS := &"ui_trocar_ofertas"

## Todas as ações de release, na ordem da tabela R1. Ações `debug_*` não existem no build de release.
const TODAS: Array[StringName] = [
	&"mover", &"mirar", &"ataque", &"especial", &"selo", &"esquiva", &"interagir", &"troca", &"pausar",
	&"ui_aceitar", &"ui_voltar", &"ui_navegar", &"ui_carta_1", &"ui_carta_2", &"ui_carta_3",
	&"ui_trocar_ofertas",
]

# --- Contextos de entrada (R10, ADR-0006 §3) ---
const CONTEXTO_JOGO := &"jogo"
const CONTEXTO_PAUSA := &"pausa"
const CONTEXTO_BENCAO := &"bencao"
const CONTEXTO_MENU := &"menu"
const CONTEXTO_TEXTO := &"texto"
const CONTEXTO_TRANSICAO := &"transicao"
const CONTEXTO_SEM_FOCO := &"sem_foco"
const CONTEXTO_REMAPEANDO := &"remapeando"

## Contextos em que cada ação existe (R1). Texto, Transição, Sem foco e Remapeando não têm ações.
const CONTEXTOS_DA_ACAO: Dictionary = {
	&"mover": [&"jogo"],
	&"mirar": [&"jogo"],
	&"ataque": [&"jogo"],
	&"especial": [&"jogo"],
	&"selo": [&"jogo"],
	&"esquiva": [&"jogo"],
	&"interagir": [&"jogo"],
	&"troca": [&"jogo"],
	&"pausar": [&"jogo", &"pausa", &"bencao"],
	&"ui_aceitar": [&"pausa", &"bencao", &"menu"],
	&"ui_voltar": [&"menu"],
	&"ui_navegar": [&"pausa", &"bencao", &"menu"],
	&"ui_carta_1": [&"bencao"],
	&"ui_carta_2": [&"bencao"],
	&"ui_carta_3": [&"bencao"],
	&"ui_trocar_ofertas": [&"bencao"],
}

## Ações que entram no buffer, na ordem de prioridade de consumo (R6, F3, emenda Pactos).
const NO_BUFFER: Array[StringName] = [&"esquiva", &"especial", &"ataque", &"selo", &"troca"]

## Ações cujo `quer` aceita segurado além do buffer (R7: segurar repete).
const SEGURAR_REPETE: Array[StringName] = [&"ataque", &"especial"]

## Ações vetoriais com direções digitais remapeáveis (ids internos, não são ações públicas).
const DIRECIONAIS: Array[StringName] = [&"mover", &"ui_navegar"]

const DIRECAO_CIMA := &"cima"
const DIRECAO_BAIXO := &"baixo"
const DIRECAO_ESQUERDA := &"esquerda"
const DIRECAO_DIREITA := &"direita"
## Direções digitais, na ordem usada pelos mapas.
const DIRECOES: Array[StringName] = [&"cima", &"baixo", &"esquerda", &"direita"]

# --- Famílias de dispositivo (seções do mapa de binds, ADR-0006 §6) ---
const DISPOSITIVO_TECLADO := &"teclado"
const DISPOSITIVO_GAMEPAD := &"gamepad"


## Chave de bind de uma direção de ação vetorial, ex.: `mover.cima`.
static func chave_direcional(acao: StringName, direcao: StringName) -> StringName:
	return StringName("%s.%s" % [acao, direcao])


## Ação pública de uma chave de bind (`mover.cima` → `mover`; `ataque` → `ataque`).
static func acao_da_chave(chave: StringName) -> StringName:
	var texto := String(chave)
	var ponto := texto.find(".")
	if ponto < 0:
		return chave
	return StringName(texto.substr(0, ponto))


## Direção de uma chave direcional (`mover.cima` → `cima`); vazio se a chave não for direcional.
static func direcao_da_chave(chave: StringName) -> StringName:
	var texto := String(chave)
	var ponto := texto.find(".")
	if ponto < 0:
		return &""
	return StringName(texto.substr(ponto + 1))


## Verdadeiro se `acao` pertence à lista fechada R1.
static func eh_acao(acao: StringName) -> bool:
	return CONTEXTOS_DA_ACAO.has(acao)


## Contextos em que `acao` existe (cópia); vazio para ação desconhecida.
static func contextos(acao: StringName) -> Array[StringName]:
	var saida: Array[StringName] = []
	if CONTEXTOS_DA_ACAO.has(acao):
		for contexto: StringName in CONTEXTOS_DA_ACAO[acao]:
			saida.append(contexto)
	return saida


## Verdadeiro se `acao` existe em `contexto`.
static func existe_no_contexto(acao: StringName, contexto: StringName) -> bool:
	if not CONTEXTOS_DA_ACAO.has(acao):
		return false
	return (CONTEXTOS_DA_ACAO[acao] as Array).has(contexto)
