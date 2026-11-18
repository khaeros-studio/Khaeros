class_name BindsPadrao
extends RefCounted
## Mapa padrão de binds, em dados embarcados independentes do catálogo (GDD input-e-controle R1, R1a, R8;
## ADR-0006 §1, §6 e emenda Pactos). A tela de erros precisa destes padrões mesmo sem catálogo.
##
## Formato: `{familia: {chave_de_bind: [ {tipo, codigo}, ... ]}}`, com no máximo 3 binds por chave e o
## primário primeiro. Ações vetoriais usam uma chave por direção (`mover.cima`, `ui_navegar.esquerda`).
## Vetores de gamepad (analógicos de `mover`, `mirar` e da navegação) não são remapeáveis e não estão aqui.
## Teclas usam a posição física (`physical_keycode`). Os binds de `troca` estão [a confirmar] no GDD.

## Limite de binds por ação por dispositivo (R8).
const MAX_BINDS := 3

const _T := &"tecla_fisica"
const _M := &"mouse"
const _B := &"botao_gamepad"
const _G := &"gatilho"

const _TECLADO: Dictionary = {
	&"mover.cima": [{"tipo": _T, "codigo": KEY_W}, {"tipo": _T, "codigo": KEY_UP}],
	&"mover.baixo": [{"tipo": _T, "codigo": KEY_S}, {"tipo": _T, "codigo": KEY_DOWN}],
	&"mover.esquerda": [{"tipo": _T, "codigo": KEY_A}, {"tipo": _T, "codigo": KEY_LEFT}],
	&"mover.direita": [{"tipo": _T, "codigo": KEY_D}, {"tipo": _T, "codigo": KEY_RIGHT}],
	&"ataque": [{"tipo": _M, "codigo": MOUSE_BUTTON_LEFT}, {"tipo": _T, "codigo": KEY_J}],
	&"especial": [{"tipo": _M, "codigo": MOUSE_BUTTON_RIGHT}, {"tipo": _T, "codigo": KEY_K}],
	&"selo": [{"tipo": _T, "codigo": KEY_Q}, {"tipo": _T, "codigo": KEY_F}],
	&"esquiva": [{"tipo": _T, "codigo": KEY_SPACE}, {"tipo": _T, "codigo": KEY_SHIFT}, {"tipo": _T, "codigo": KEY_L}],
	&"interagir": [{"tipo": _T, "codigo": KEY_E}],
	&"troca": [{"tipo": _T, "codigo": KEY_R}, {"tipo": _T, "codigo": KEY_TAB}],
	&"pausar": [{"tipo": _T, "codigo": KEY_ESCAPE}],
	&"ui_aceitar": [{"tipo": _T, "codigo": KEY_ENTER}, {"tipo": _T, "codigo": KEY_SPACE}, {"tipo": _T, "codigo": KEY_E}],
	&"ui_voltar": [{"tipo": _T, "codigo": KEY_ESCAPE}],
	&"ui_navegar.cima": [{"tipo": _T, "codigo": KEY_UP}, {"tipo": _T, "codigo": KEY_W}],
	&"ui_navegar.baixo": [{"tipo": _T, "codigo": KEY_DOWN}, {"tipo": _T, "codigo": KEY_S}],
	&"ui_navegar.esquerda": [{"tipo": _T, "codigo": KEY_LEFT}, {"tipo": _T, "codigo": KEY_A}],
	&"ui_navegar.direita": [{"tipo": _T, "codigo": KEY_RIGHT}, {"tipo": _T, "codigo": KEY_D}],
	&"ui_carta_1": [{"tipo": _T, "codigo": KEY_1}],
	&"ui_carta_2": [{"tipo": _T, "codigo": KEY_2}],
	&"ui_carta_3": [{"tipo": _T, "codigo": KEY_3}],
	&"ui_trocar_ofertas": [{"tipo": _T, "codigo": KEY_R}],
}

const _GAMEPAD: Dictionary = {
	&"ataque": [{"tipo": _B, "codigo": JOY_BUTTON_X}],
	&"especial": [{"tipo": _B, "codigo": JOY_BUTTON_Y}],
	&"selo": [{"tipo": _B, "codigo": JOY_BUTTON_B}, {"tipo": _B, "codigo": JOY_BUTTON_LEFT_SHOULDER}],
	&"esquiva": [{"tipo": _B, "codigo": JOY_BUTTON_A}, {"tipo": _G, "codigo": JOY_AXIS_TRIGGER_RIGHT}],
	&"interagir": [{"tipo": _B, "codigo": JOY_BUTTON_RIGHT_SHOULDER}],
	&"troca": [{"tipo": _G, "codigo": JOY_AXIS_TRIGGER_LEFT}],
	&"pausar": [{"tipo": _B, "codigo": JOY_BUTTON_START}],
	&"ui_aceitar": [{"tipo": _B, "codigo": JOY_BUTTON_A}],
	&"ui_voltar": [{"tipo": _B, "codigo": JOY_BUTTON_B}],
	&"ui_navegar.cima": [{"tipo": _B, "codigo": JOY_BUTTON_DPAD_UP}],
	&"ui_navegar.baixo": [{"tipo": _B, "codigo": JOY_BUTTON_DPAD_DOWN}],
	&"ui_navegar.esquerda": [{"tipo": _B, "codigo": JOY_BUTTON_DPAD_LEFT}],
	&"ui_navegar.direita": [{"tipo": _B, "codigo": JOY_BUTTON_DPAD_RIGHT}],
	&"ui_trocar_ofertas": [{"tipo": _B, "codigo": JOY_BUTTON_Y}],
}


## Cópia nova e independente do mapa padrão, por família (`teclado`, `gamepad`).
static func mapa() -> Dictionary:
	return {
		Acoes.DISPOSITIVO_TECLADO: _TECLADO.duplicate(true),
		Acoes.DISPOSITIVO_GAMEPAD: _GAMEPAD.duplicate(true),
	}


## Ações públicas presentes num mapa (sem repetição, na ordem em que aparecem).
static func acoes_do_mapa(mapa_binds: Dictionary) -> Array[StringName]:
	var saida: Array[StringName] = []
	for familia: StringName in mapa_binds:
		for chave: StringName in (mapa_binds[familia] as Dictionary):
			var acao := Acoes.acao_da_chave(chave)
			if not saida.has(acao):
				saida.append(acao)
	return saida


## Varredura de conflitos (AC-35, AC-41): devolve uma linha por bind lógico que aparece em duas ações
## diferentes de um mesmo contexto, na mesma família. Lista vazia = mapa sem conflito.
static func varrer_conflitos(mapa_binds: Dictionary) -> Array[String]:
	var conflitos: Array[String] = []
	for familia: StringName in mapa_binds:
		var binds_familia: Dictionary = mapa_binds[familia]
		# contexto -> chave_logica -> ação pública dona
		var donos: Dictionary = {}
		for chave: StringName in binds_familia:
			var acao := Acoes.acao_da_chave(chave)
			for contexto: StringName in Acoes.contextos(acao):
				if not donos.has(contexto):
					donos[contexto] = {}
				var por_bind: Dictionary = donos[contexto]
				for bind: Dictionary in binds_familia[chave]:
					var logica := DescritorDeEntrada.de_bind(bind).chave_logica()
					if por_bind.has(logica) and por_bind[logica] != acao:
						conflitos.append("%s/%s: %s em %s e %s" % [familia, contexto, logica, por_bind[logica], acao])
					else:
						por_bind[logica] = acao
	return conflitos
