class_name TransacaoDeRemapeamento
extends RefCounted
## Remapeamento como transação sobre cópia do mapa (GDD input-e-controle R8 e Edge Cases › Remapeamento;
## ADR-0006 §6). Cada operação trabalha numa cópia, resolve a troca de conflito, valida o mapa inteiro
## (conflitos por contexto, primários, Esc/Start em `pausar`, limite de 3) e só então devolve o mapa novo.
## Recusada, o mapa original fica intacto — nunca se publica um mapa parcial. Quem publica é o chamador
## (`ProvedorDeEntrada.publicar_mapa`, que aplica a barreira de contexto).
##
## A captura da tela de remapeamento (5 s; Esc/Start segurado 1 s cancela; delta real) é `Captura`, abaixo.

## Aviso: dois binds trocaram de lugar (R8).
const AVISO_CONFLITO_TROCA := &"INPUT_CONFLITO_TROCA"
## Recusa genérica: tecla reservada, roda do mouse, 4º bind, ação sem primário ou conflito sem troca válida.
const AVISO_RECUSA_TECLA := &"INPUT_RECUSA_TECLA"
## Recusa que tiraria Esc/Start de `pausar` ou colocaria `pausar` numa troca (R8).
const AVISO_RECUSA_PAUSA := &"INPUT_RECUSA_PAUSA"

## Contextos em que Esc/Start são exclusivos de `pausar` (Edge Cases: Jogo, Pausa e Bênção).
const _CONTEXTOS_DA_PAUSA: Array[StringName] = [&"jogo", &"pausa", &"bencao"]


## Resultado de uma operação: `aceito`, o mapa resultante (o original, se recusado) e o aviso (ou vazio).
class Resultado extends RefCounted:
	## `true` se o mapa mudou e pode ser publicado.
	var aceito: bool = false
	## Mapa resultante (cópia nova); igual ao original quando recusado.
	var mapa: MapaDeBinds
	## Chave `INPUT_*` a mostrar; vazio sem aviso.
	var aviso: StringName = &""

	func _init(p_aceito: bool, p_mapa: MapaDeBinds, p_aviso: StringName = &"") -> void:
		aceito = p_aceito
		mapa = p_mapa
		aviso = p_aviso


## Atribui `bind` (`{tipo, codigo}`) à posição `indice` da `chave` na `familia` (`indice` = tamanho da lista
## acrescenta). Se outra ação de um contexto em comum já usa o bind, as duas trocam (o dono recebe o bind que
## estava na posição); a troca é recusada se deixar alguém sem primário ou se envolver `pausar`.
static func atribuir(mapa: MapaDeBinds, familia: StringName, chave: StringName, indice: int,
		bind: Dictionary) -> Resultado:
	var recusa := _recusa_de_entrada(familia, chave, bind)
	if recusa != &"":
		return _recusar(mapa, recusa)
	var novo := mapa.copia()
	var lista := novo.de(familia, chave)
	if indice < 0 or indice > lista.size():
		return _recusar(mapa, AVISO_RECUSA_TECLA)
	if indice == lista.size() and lista.size() >= MapaDeBinds.MAX_BINDS:
		return _recusar(mapa, AVISO_RECUSA_TECLA)
	var logica := MapaDeBinds.logica(bind)
	var anterior: Dictionary = lista[indice] if indice < lista.size() else {}
	if not anterior.is_empty() and MapaDeBinds.logica(anterior) == logica:
		return Resultado.new(false, mapa)
	if _eh_reservado_da_pausa(anterior) and Acoes.acao_da_chave(chave) == Acoes.PAUSAR:
		return _recusar(mapa, AVISO_RECUSA_PAUSA)

	# A mesma chave já tem o bind em outra posição: troca interna das posições.
	var mesma := _indice_logico(lista, logica)
	if mesma >= 0:
		if anterior.is_empty():
			return _recusar(mapa, AVISO_RECUSA_TECLA)
		lista[mesma] = anterior
		lista[indice] = bind.duplicate()
		novo.definir(familia, chave, lista)
		return _validar(mapa, novo, &"")

	var donos := _donos_em_comum(novo, familia, chave, logica)
	if donos.size() > 1:
		return _recusar(mapa, AVISO_RECUSA_TECLA)
	var aviso := &""
	if donos.size() == 1:
		var dono: StringName = donos[0]
		if Acoes.acao_da_chave(dono) == Acoes.PAUSAR or Acoes.acao_da_chave(chave) == Acoes.PAUSAR:
			return _recusar(mapa, AVISO_RECUSA_PAUSA)
		var lista_dono := novo.de(familia, dono)
		var pos := _indice_logico(lista_dono, logica)
		if anterior.is_empty():
			if pos == 0:
				return _recusar(mapa, AVISO_RECUSA_TECLA) # o dono ficaria sem primário
			lista_dono.remove_at(pos)
		else:
			lista_dono[pos] = anterior
		novo.definir(familia, dono, lista_dono)
		aviso = AVISO_CONFLITO_TROCA
	if indice == lista.size():
		lista.append(bind.duplicate())
	else:
		lista[indice] = bind.duplicate()
	novo.definir(familia, chave, lista)
	return _validar(mapa, novo, aviso)


## Acrescenta um bind ao fim da lista (até 3 por dispositivo; o 4º é recusado com `INPUT_RECUSA_TECLA`).
static func acrescentar(mapa: MapaDeBinds, familia: StringName, chave: StringName, bind: Dictionary) -> Resultado:
	return atribuir(mapa, familia, chave, mapa.de(familia, chave).size(), bind)


## Remove um secundário (`indice` ≥ 1). O primário só pode ser trocado; Esc/Start de `pausar` nunca saem.
static func remover(mapa: MapaDeBinds, familia: StringName, chave: StringName, indice: int) -> Resultado:
	var lista := mapa.de(familia, chave)
	if indice < 0 or indice >= lista.size():
		return _recusar(mapa, AVISO_RECUSA_TECLA)
	if Acoes.acao_da_chave(chave) == Acoes.PAUSAR and _eh_reservado_da_pausa(lista[indice]):
		return _recusar(mapa, AVISO_RECUSA_PAUSA)
	if indice == 0:
		return _recusar(mapa, AVISO_RECUSA_TECLA)
	var novo := mapa.copia()
	lista.remove_at(indice)
	novo.definir(familia, chave, lista)
	return _validar(mapa, novo, &"")


## Validação completa de um mapa (também usada pelo repositório ao carregar): devolve vazio se válido, ou a
## chave do aviso que o recusa. Regras: cada chave do padrão da família tem primário; no máximo 3 binds;
## nenhuma entrada reservada; nenhum conflito por contexto; Esc/Start em `pausar` e em nenhuma outra ação de
## Jogo/Pausa/Bênção.
static func validar(mapa: MapaDeBinds) -> StringName:
	var padrao := BindsPadrao.mapa()
	for familia: StringName in padrao:
		var binds_familia: Dictionary = mapa.binds.get(familia, {})
		for chave: StringName in (padrao[familia] as Dictionary):
			var lista: Array = binds_familia.get(chave, [])
			if lista.is_empty() or lista.size() > MapaDeBinds.MAX_BINDS:
				return AVISO_RECUSA_TECLA
		for chave: StringName in binds_familia:
			var acao := Acoes.acao_da_chave(chave)
			for bind: Dictionary in binds_familia[chave]:
				if DescritorDeEntrada.de_bind(bind).familia() != familia or _eh_proibido(bind):
					return AVISO_RECUSA_TECLA
				if acao != Acoes.PAUSAR and _eh_reservado_da_pausa(bind) and _em_contexto_da_pausa(acao):
					return AVISO_RECUSA_PAUSA
		var reservado: Dictionary = (padrao[familia][Acoes.PAUSAR] as Array)[0]
		if _indice_logico(binds_familia.get(Acoes.PAUSAR, []), MapaDeBinds.logica(reservado)) < 0:
			return AVISO_RECUSA_PAUSA
	if not BindsPadrao.varrer_conflitos(mapa.binds).is_empty():
		return AVISO_RECUSA_TECLA
	return &""


static func _validar(original: MapaDeBinds, novo: MapaDeBinds, aviso: StringName) -> Resultado:
	var recusa := validar(novo)
	if recusa != &"":
		return _recusar(original, recusa)
	return Resultado.new(true, novo, aviso)


static func _recusar(mapa: MapaDeBinds, aviso: StringName) -> Resultado:
	return Resultado.new(false, mapa, aviso)


static func _recusa_de_entrada(familia: StringName, chave: StringName, bind: Dictionary) -> StringName:
	if not (BindsPadrao.mapa().get(familia, {}) as Dictionary).has(chave):
		return AVISO_RECUSA_TECLA # vetores do gamepad e chaves desconhecidas não são remapeáveis
	if DescritorDeEntrada.de_bind(bind).familia() != familia or _eh_proibido(bind):
		return AVISO_RECUSA_TECLA
	var acao := Acoes.acao_da_chave(chave)
	if acao != Acoes.PAUSAR and _eh_reservado_da_pausa(bind) and _em_contexto_da_pausa(acao):
		return AVISO_RECUSA_PAUSA
	return &""


## Windows/Meta, Print Screen e roda do mouse (Edge Cases; AC-29).
static func _eh_proibido(bind: Dictionary) -> bool:
	var tipo := StringName(bind.get("tipo", &""))
	var codigo := int(bind.get("codigo", 0))
	if tipo == DescritorDeEntrada.TECLA_FISICA:
		return codigo == KEY_META or codigo == KEY_PRINT
	if tipo == DescritorDeEntrada.MOUSE:
		return codigo in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT,
				MOUSE_BUTTON_WHEEL_RIGHT]
	return false


## Esc (teclado) e Start (gamepad): o primário fixo de `pausar` no padrão.
static func _eh_reservado_da_pausa(bind: Dictionary) -> bool:
	if bind.is_empty():
		return false
	var tipo := StringName(bind.get("tipo", &""))
	var codigo := int(bind.get("codigo", 0))
	return (tipo == DescritorDeEntrada.TECLA_FISICA and codigo == KEY_ESCAPE) \
			or (tipo == DescritorDeEntrada.BOTAO_GAMEPAD and codigo == JOY_BUTTON_START)


static func _em_contexto_da_pausa(acao: StringName) -> bool:
	for contexto: StringName in Acoes.contextos(acao):
		if _CONTEXTOS_DA_PAUSA.has(contexto):
			return true
	return false


static func _indice_logico(lista: Array, logica: StringName) -> int:
	for i in lista.size():
		if MapaDeBinds.logica(lista[i]) == logica:
			return i
	return -1


## Outras chaves da família, de ações com contexto em comum com `chave`, que já usam `logica`.
static func _donos_em_comum(mapa: MapaDeBinds, familia: StringName, chave: StringName,
		logica: StringName) -> Array[StringName]:
	var contextos := Acoes.contextos(Acoes.acao_da_chave(chave))
	var donos: Array[StringName] = []
	var binds_familia: Dictionary = mapa.binds.get(familia, {})
	for outra: StringName in binds_familia:
		if outra == chave or _indice_logico(binds_familia[outra], logica) < 0:
			continue
		for contexto: StringName in Acoes.contextos(Acoes.acao_da_chave(outra)):
			if contextos.has(contexto):
				donos.append(outra)
				break
	return donos


## Captura de um bind na tela de remapeamento (R8; ADR-0006 §6). Restrita à família escolhida. Uma entrada
## comum é capturada no aperto; Esc/Start viram candidatos e só são capturados na soltura curta (segurar
## `cancelar_s` cancela). Sem entrada por `prazo_s`, cancela. O tempo vem de `avancar(delta_real)`, o delta
## real da fronteira, independente de `t_vivo`/`t_apres` (a tela pode estar pausada). Cancelar não muda o mapa;
## o bind capturado ainda passa pelas recusas da transação.
class Captura extends RefCounted:
	## Duração máxima da captura, em segundos de tempo real (R8: 5 s; constante de regra da tela).
	const PRAZO_S := 5.0
	## Tempo segurando Esc/Start que cancela, em segundos de tempo real (R8: 1 s).
	const CANCELAR_S := 1.0

	enum Estado { CAPTURANDO, CAPTURADO, CANCELADO }

	## Estado atual.
	var estado: Estado = Estado.CAPTURANDO
	## Bind capturado (`{tipo, codigo}`); vazio enquanto não houver.
	var bind: Dictionary = {}

	var _familia: StringName
	var _prazo_s: float
	var _cancelar_s: float
	var _decorrido_s: float = 0.0
	var _candidato: DescritorDeEntrada = null
	var _segurando_s: float = 0.0

	func _init(familia: StringName, prazo_s: float = PRAZO_S, cancelar_s: float = CANCELAR_S) -> void:
		_familia = familia
		_prazo_s = prazo_s
		_cancelar_s = cancelar_s

	## Aperto de uma entrada física.
	func apertar(descritor: DescritorDeEntrada) -> void:
		if estado != Estado.CAPTURANDO or descritor.familia() != _familia or _candidato != null:
			return
		if TransacaoDeRemapeamento._eh_reservado_da_pausa(descritor.como_bind()):
			_candidato = descritor
			_segurando_s = 0.0
			return
		_capturar(descritor)

	## Soltura de uma entrada física: um candidato Esc/Start solto antes de `cancelar_s` é capturado.
	func soltar(descritor: DescritorDeEntrada) -> void:
		if estado != Estado.CAPTURANDO or _candidato == null:
			return
		if descritor.chave_logica() == _candidato.chave_logica():
			_capturar(_candidato)

	## Avança o relógio real da captura.
	func avancar(delta_real_s: float) -> void:
		if estado != Estado.CAPTURANDO:
			return
		if _candidato != null:
			_segurando_s += delta_real_s
			if _segurando_s >= _cancelar_s:
				estado = Estado.CANCELADO
			return
		_decorrido_s += delta_real_s
		if _decorrido_s >= _prazo_s:
			estado = Estado.CANCELADO

	func _capturar(descritor: DescritorDeEntrada) -> void:
		bind = descritor.como_bind()
		estado = Estado.CAPTURADO
