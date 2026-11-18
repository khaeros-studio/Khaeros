class_name MovimentoDoJogador
extends Passo
## Movimento e esquiva de um jogador — item 4 do passo vivo (GDD movimento-e-esquiva R1–R12; ADR-0008;
## ADR-0001). Único escritor da posição física do jogador. Lógica pura: sem SceneTree, Autoload, Timer,
## física da engine ou consulta de hitstop (quem decide [method passo] × [method passo_congelado] é o
## orquestrador). Substitui a forma de [code]src/gameplay/movement.gd[/code] (legado da fatia, removido
## quando o Main migrar).
##
## Ordem interna do passo vivo (R3): 0 sincronizar máximo · 1 recarga · 2 largada da esquiva (pedidos
## síncronos ao Combate antes de deslocar) · 3 um deslocamento (investida > esquiva > andar) · 4 Corte
## antes da colisão, na posição provisória · 5 colisão. Chamadas externas: [method deslocar] (Combate, depois
## do Movimento) e [method teleportar] (Câmaras).
##
## Exemplo:
## [codeblock]
## var mov := MovimentoDoJogador.new(0, tuning, portador, combate, fonte_de_comandos, geometria, eventos)
## mov.iniciar(Vector2(960, 540), epoca_run)
## modulos[OrdemDoPasso.MOVIMENTO] = mov
## [/codeblock]

## Aviso de depuração: investida informada durante esquiva (violação de contrato do Combate, R3).
const AVISO_INVESTIDA_NA_ESQUIVA: String = "Movimento: investida ativa durante esquiva (player %d); esquiva vence"
## Tipo do gatilho do Corte (Modificadores R5) e nomes dos params do dado (FP-Corte).
const GATILHO_CORTE: StringName = &"corte_da_esquiva"
const PARAM_ALCANCE_EXTRA: StringName = &"alcance_extra_px"
const PARAM_EMPURRAO: StringName = &"empurrao"
const PARAM_SANGRAMENTO: StringName = &"sangramento"

var _estado: EstadoDoMovimento
var _p: ParametrosDoMovimento
var _atributos: ConsultaDeAtributos
var _combate: CombateParaMovimento
var _comandos: FonteDeComandos
var _geometria: GeometriaDeMovimento
var _eventos: EventosDoPasso
var _jogador: JogadorRef = null
var _alvos: AlvosDoCorte = null
var _teleportes: int = 0


## Todas as dependências injetadas (R12). [param atributos]: portador do jogador ([Portador] real ou dublê).
## [param alvos]: lista de atingíveis do Corte (null = sem Corte, ex. testes de andar).
func _init(player_id: int, tuning: MovementTuning, atributos: ConsultaDeAtributos,
		combate: CombateParaMovimento, comandos: FonteDeComandos, geometria: GeometriaDeMovimento,
		eventos: EventosDoPasso, alvos: AlvosDoCorte = null) -> void:
	_alvos = alvos
	_estado = EstadoDoMovimento.new(player_id)
	_p = ParametrosDoMovimento.de(tuning)
	_atributos = atributos
	_combate = combate
	_comandos = comandos
	_geometria = geometria
	_eventos = eventos


## Opcional: espelha posição, cargas e esquiva restante no [JogadorRef] (ADR-0003, campos do Movimento).
func publicar_em(jogador: JogadorRef) -> void:
	_jogador = jogador
	_publicar()


## Começo da run: posição (anterior = atual), cargas no máximo do portador (R7), sem esquiva.
func iniciar(pos: Vector2, epoca_run: int = 0) -> void:
	_estado.pos = pos
	_estado.anterior = pos
	_estado.epoca_run = epoca_run
	_estado.esquiva_restante = 0
	_estado.cortados.clear()
	_estado.cargas.iniciar(_atributos.inteiro(Atributos.CARGAS_ESQUIVA))
	_publicar()


## Troca a geometria da câmara (Câmaras, na troca).
func configurar_geometria(geometria: GeometriaDeMovimento) -> void:
	_geometria = geometria


# --- Passo -------------------------------------------------------------------------

## Passo vivo (R2/R3). Só o orquestrador chama, em JOGO e sem hitstop.
func passo(amostra: AmostraDeEntrada) -> void:
	var e := _estado
	e.anterior = e.pos
	var comandos := _comandos.comandos_do_passo(amostra.id_passo)
	# 0. sincronizar máximo
	e.cargas.sincronizar(_atributos.inteiro(Atributos.CARGAS_ESQUIVA))
	# 1. recarga
	e.cargas.avancar(_p.r)
	# 2. toques sem carga (antes de gastar), depois largada
	var toques := _comandos.drenar_esquivas_congeladas()
	if amostra.foi_apertado(Acoes.ESQUIVA):
		toques += 1
	if e.cargas.cargas < 1:
		for _i in toques:
			_eventos.emitir(EvEsquivaSemCarga.new(e.player_id, e.epoca_run))
	var largou := false
	if e.esquiva_restante == 0 and e.cargas.cargas >= 1 and comandos.quer(Acoes.ESQUIVA):
		_largar_esquiva(amostra, comandos)
		largou = true
	# 3. exatamente um deslocamento
	var investida := not largou and _combate.investida_ativa(e.player_id)
	var esquivou := false
	if e.esquiva_restante > 0:
		if investida:
			push_warning(AVISO_INVESTIDA_NA_ESQUIVA % e.player_id)
		e.pos += e.esquiva_direcao * _p.d_passo
		e.esquiva_restante -= 1
		esquivou = true
	elif investida:
		e.pos += _combate.deslocamento_investida(e.player_id)
	else:
		e.pos += _deslocamento_andar(amostra.mover)
	# 4. Corte da esquiva, na posição provisória (antes da colisão), inclusive no último passo.
	if esquivou:
		_cortar()
	# 5. colisão
	e.pos = Colisao.resolver_colisao(e.pos, _p.raio, _geometria)
	_publicar()


## Passo congelado (hitstop, pausa, Bênção, fora de JOGO): somente anterior = atual (R2).
func passo_congelado() -> void:
	_estado.anterior = _estado.pos


## Pedido externo do Combate depois do Movimento (R9): soma [param v] e roda outra passada de colisão.
## Anterior, contadores, esquiva e lista do Corte ficam intactos; não varre Corte.
func deslocar(v: Vector2) -> void:
	_estado.pos = Colisao.resolver_colisao(_estado.pos + v, _p.raio, _geometria)
	_publicar()


## Teleporte (R1; Câmaras no spawn/troca): atual = anterior = [param pos], esquiva e Corte zerados,
## cargas/recarga preservadas, sem tocar a invulnerabilidade do Combate. Não resolve colisão (R10 roda no
## próximo passo vivo). Emite [EvTeleporteDoJogador] e incrementa [method contador_teleportes].
func teleportar(pos: Vector2) -> void:
	var e := _estado
	e.pos = pos
	e.anterior = pos
	e.esquiva_restante = 0
	e.cortados.clear()
	_teleportes += 1
	_eventos.emitir(EvTeleporteDoJogador.new(e.player_id, e.epoca_run, pos))
	_publicar()


# --- Consultas (por valor) ---------------------------------------------------------

## Posição atual.
func posicao() -> Vector2:
	return _estado.pos


## Posição do passo anterior.
func posicao_anterior() -> Vector2:
	return _estado.anterior


## Verdadeiro se a esquiva restante é > 0 ao fim do Movimento deste passo (R6).
func em_esquiva() -> bool:
	return _estado.esquiva_restante > 0


## Passos de esquiva restantes.
func esquiva_restante() -> int:
	return _estado.esquiva_restante


## Cargas atuais.
func cargas() -> int:
	return _estado.cargas.cargas


## Máximo de cargas guardado.
func cargas_max() -> int:
	return _estado.cargas.maximo


## Progresso do contador de recarga (passos).
func progresso_recarga() -> int:
	return _estado.cargas.progresso


## Progresso normalizado 0..1 (0 quando cheio).
func progresso_recarga_normalizado() -> float:
	return _estado.cargas.progresso_normalizado(_p.r)


## Raio do corpo.
func raio() -> float:
	return _p.raio


## Jogador.
func player_id() -> int:
	return _estado.player_id


## Quantos teletransportes já houve (a Apresentação reseta a interpolação quando muda).
func contador_teleportes() -> int:
	return _teleportes


## Ids já cortados nesta esquiva (quantidade).
func cortados_nesta_esquiva() -> int:
	return _estado.cortados.size()


## Derivados do tuning (D, E, R...), somente leitura.
func parametros() -> ParametrosDoMovimento:
	return _p


# --- Interno -----------------------------------------------------------------------

func _largar_esquiva(amostra: AmostraDeEntrada, comandos: ComandosDoPasso) -> void:
	var e := _estado
	e.esquiva_direcao = Esquiva.direcao(amostra.mover, amostra.mirar)
	e.cargas.gastar()
	e.esquiva_restante = _p.d
	_combate.cancelar(e.player_id)
	_combate.garantir_invulneravel(e.player_id, _p.inv_esquiva)
	_combate.esquiva_iniciada(e.player_id)
	e.cortados.clear()
	comandos.consumir(Acoes.ESQUIVA)
	_eventos.emitir(EvEsquiva.new(e.player_id, e.epoca_run, e.pos, e.esquiva_direcao))


## R8/F5/F6: testa os alvos em ordem estável; alcance inclusivo por distância²; um corte por alvo por esquiva;
## teto opcional; dano = total × M(Ataque) com contexto sem apos_esquiva/enesimo_acerto.
func _cortar() -> void:
	if _alvos == null:
		return
	var g := _atributos.gatilhos(GATILHO_CORTE)
	if g.total <= 0.0:
		return
	var e := _estado
	var extra: float = g.params.get(PARAM_ALCANCE_EXTRA, 0.0)
	var empurrao: float = g.params.get(PARAM_EMPURRAO, 0.0)
	var sangramento: float = g.params.get(PARAM_SANGRAMENTO, 0.0)
	var ctx: ContextoDeDano = null
	for a: AlvoDoCorte in _alvos.alvos_atingiveis():
		if _p.alvos_max_corte > 0 and e.cortados.size() >= _p.alvos_max_corte:
			return
		if e.cortados.has(a.id):
			continue
		var alcance := _p.raio + a.raio + extra
		if e.pos.distance_squared_to(a.pos) > alcance * alcance:
			continue
		e.cortados[a.id] = true  # marca antes do pedido síncrono (reentrada)
		if ctx == null:
			ctx = ContextoDeDano.new(_combate.vida_atual(e.player_id), false)
		var m := _atributos.multiplicador_de_dano(Modificador.Slot.ATAQUE, ctx)
		_combate.aplicar_corte(e.player_id, a.id, g.total * m, e.esquiva_direcao, empurrao, sangramento)


## F1: valor(velocidade) × min(1, |mover|) × f_rec / TICK_RATE, na direção de mover normalizado.
func _deslocamento_andar(mover: Vector2) -> Vector2:
	var modulo := mover.length()
	if modulo == 0.0:
		return Vector2.ZERO
	var f_rec := _p.fator_recuperacao if _combate.em_recuperacao(_estado.player_id) else 1.0
	var v := _atributos.valor(Atributos.VELOCIDADE) * minf(1.0, modulo) * f_rec
	return mover.normalized() * (v / float(Unidades.TICK_RATE))


func _publicar() -> void:
	if _jogador == null:
		return
	_jogador.posicao = _estado.pos
	_jogador.cargas = _estado.cargas.cargas
	_jogador.esquiva_passos = _estado.esquiva_restante
