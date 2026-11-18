class_name DescritorDeEntrada
extends RefCounted
## Identidade de uma entrada física, como valor (ADR-0006 §1, §6). Nenhum `InputEvent` atravessa a fronteira:
## o adaptador converte cada evento num descritor destes.
##
## - `chave_fisica()` identifica a peça física (inclui lado esquerdo/direito e o id do gamepad): é a unidade
##   de estado segurado e de bloqueio na troca de contexto.
## - `chave_logica()` identifica o bind (tipo + código): Shift esquerdo e direito são o mesmo bind lógico.

const TECLA_FISICA := &"tecla_fisica"
const MOUSE := &"mouse"
const BOTAO_GAMEPAD := &"botao_gamepad"
const GATILHO := &"gatilho"

const ORIGEM_TECLADO := &"teclado"
const ORIGEM_MOUSE := &"mouse"
const ORIGEM_GAMEPAD := &"gamepad"

## Sem lado conhecido (teclas comuns, mouse, gamepad).
const LOCALIZACAO_NENHUMA := 0
## Sem gamepad (teclado e mouse não usam id de dispositivo; 4.7 mudou `InputEvent.device` deles).
const SEM_DISPOSITIVO := -1

## Tipo do descritor: `tecla_fisica`, `mouse`, `botao_gamepad` ou `gatilho`.
var tipo: StringName
## Código: posição física da tecla, botão do mouse, botão do gamepad ou eixo do gatilho.
var codigo: int
## Lado esquerdo/direito quando a engine informa (valores de `KeyLocation`); 0 sem lado.
var localizacao: int
## Id do gamepad; `SEM_DISPOSITIVO` para teclado e mouse.
var dispositivo: int


func _init(p_tipo: StringName, p_codigo: int, p_localizacao: int = LOCALIZACAO_NENHUMA,
		p_dispositivo: int = SEM_DISPOSITIVO) -> void:
	tipo = p_tipo
	codigo = p_codigo
	localizacao = p_localizacao
	dispositivo = p_dispositivo


## Constrói o descritor de um bind simples `{tipo, codigo}` do mapa (sem lado nem dispositivo).
static func de_bind(bind: Dictionary) -> DescritorDeEntrada:
	return DescritorDeEntrada.new(StringName(bind.get("tipo", &"")), int(bind.get("codigo", 0)))


## Chave do bind lógico: tipo e código, sem lado e sem id de gamepad.
func chave_logica() -> StringName:
	return StringName("%s:%d" % [tipo, codigo])


## Chave da entrada física: tipo, código, lado e id de gamepad.
func chave_fisica() -> StringName:
	return StringName("%s:%d:%d:%d" % [tipo, codigo, localizacao, dispositivo])


## Família do mapa de binds a que o descritor pertence (`teclado` ou `gamepad`).
func familia() -> StringName:
	if tipo == BOTAO_GAMEPAD or tipo == GATILHO:
		return Acoes.DISPOSITIVO_GAMEPAD
	return Acoes.DISPOSITIVO_TECLADO


## Origem da entrada (`teclado`, `mouse` ou `gamepad`), preservada nas bordas (ADR-0006 §1).
func origem() -> StringName:
	if tipo == MOUSE:
		return ORIGEM_MOUSE
	if tipo == TECLA_FISICA:
		return ORIGEM_TECLADO
	return ORIGEM_GAMEPAD


## Representação simples de bind `{tipo, codigo}` (formato do arquivo, ADR-0006 §6).
func como_bind() -> Dictionary:
	return {"tipo": tipo, "codigo": codigo}
