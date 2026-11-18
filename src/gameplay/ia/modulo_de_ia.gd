class_name ModuloDeIA
extends ConsultaDeAlvoMaldicao
## Fachada pura da IA de inimigos, elites, lacaios e chefe (*Soberano do Limiar*;
## GDD ia-de-inimigos-e-elites.md R1–R22, chefes.md R1–R8; ADR-0018, ADR-0014, ADR-0010, ADR-0003).

var _tuning: IATuning = null
var _regras_elite: EliteRules = null
var _chefes_tuning: ChefesTuning = null
var _combate: CombateParaIA = null
var _telegrafos: Telegrafos = null
var _geometria: GeometriaDeMovimento = null
var _maldicoes: ConsultaDaMaldicao = null
var _acuada: ConsultaDaAcuada = null
var _vista: ConsultaDeVista = null
var _deslocamentos: DeslocamentosDoChefe = null
var _fluxo_ia: FluxoRng = null
var _modulo_chefes: Object = null
var _eventos: EventosDoPasso = null
var _gerador_ids: GeradorDeIds = null
var _def_lacaio: EnemyDef = null

var _inimigos: Array[EstadoDeInimigoIA] = []
var _por_id: Dictionary[int, EstadoDeInimigoIA] = {}
var _vistas_atingiveis: Array[VistaDeInimigo] = []
var _epoca_campo: Dictionary[int, int] = {0: 0}
var _jogadores_pos: Dictionary[int, Vector2] = {0: Vector2.ZERO}
var _jogadores_raios: Dictionary[int, float] = {0: 27.0}
var _jogador_morto: bool = false
var _invocacoes_pendentes: Array[Vector2] = []
var _max_inimigos_onda: int = 9

var _comp_melee: ComportamentoMelee = ComportamentoMelee.new()
var _comp_ranged: ComportamentoRanged = ComportamentoRanged.new()
var _comp_charger: ComportamentoCharger = ComportamentoCharger.new()
var _comp_chefe: ComportamentoChefe = ComportamentoChefe.new()


func configurar(p_tuning: IATuning = null, p_regras_elite: EliteRules = null,
		p_chefes_tuning: ChefesTuning = null, p_combate: CombateParaIA = null,
		p_telegrafos: Telegrafos = null, p_geometria: GeometriaDeMovimento = null,
		p_maldicoes: ConsultaDaMaldicao = null, p_acuada: ConsultaDaAcuada = null,
		p_vista: ConsultaDeVista = null, p_deslocamentos: DeslocamentosDoChefe = null,
		p_fluxo_ia: FluxoRng = null, p_modulo_chefes: Object = null,
		p_eventos: EventosDoPasso = null, p_gerador_ids: GeradorDeIds = null) -> void:
	_tuning = p_tuning if p_tuning != null else IATuning.de_fabrica()
	_regras_elite = p_regras_elite if p_regras_elite != null else RegrasDeElite.de_fabrica()
	_chefes_tuning = p_chefes_tuning
	_combate = p_combate if p_combate != null else CombateParaIA.Nulo.new()
	_telegrafos = p_telegrafos
	_geometria = p_geometria if p_geometria != null else GeometriaDeMovimento.new(Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0)))
	_maldicoes = p_maldicoes if p_maldicoes != null else ConsultaDaMaldicao.Nula.new()
	_acuada = p_acuada if p_acuada != null else ConsultaDaAcuada.Nula.new()
	_vista = p_vista if p_vista != null else ConsultaDeVista.Fixa.new(_geometria.jogavel)
	_deslocamentos = p_deslocamentos if p_deslocamentos != null else DeslocamentosDoChefe.Nulo.new()
	_fluxo_ia = p_fluxo_ia
	_modulo_chefes = p_modulo_chefes
	_eventos = p_eventos
	_gerador_ids = p_gerador_ids if p_gerador_ids != null else GeradorDeIds.new()
	for idx in 16:
		_vistas_atingiveis.append(VistaDeInimigo.new())


func definir_def_lacaio(def: EnemyDef) -> void:
	_def_lacaio = def


func definir_max_inimigos_onda(max_onda: int) -> void:
	_max_inimigos_onda = maxi(1, max_onda)


func definir_fluxo_ia(fluxo: FluxoRng) -> void:
	_fluxo_ia = fluxo


func definir_geometria(geometria: GeometriaDeMovimento) -> void:
	_geometria = geometria


func definir_vista(vista: ConsultaDeVista) -> void:
	_vista = vista


func definir_jogador(player_id: int, pos: Vector2, raio: float = 27.0) -> void:
	_jogadores_pos[player_id] = pos
	_jogadores_raios[player_id] = raio


func definir_jogador_morto(morto: bool) -> void:
	_jogador_morto = morto


func tuning() -> IATuning:
	return _tuning


func chefes_tuning() -> ChefesTuning:
	return _chefes_tuning


func telegrafos() -> Telegrafos:
	return _telegrafos


# --- Criação, lista estável e troca de câmara (R1, R19, ADR-0018 §1, §9) ------

func criar_inimigo(def: EnemyDef, pos: Vector2, opcoes: OpcoesDeNascimento = null,
		portador: Portador = null) -> int:
	if def == null:
		return -1
	var opt := opcoes if opcoes != null else OpcoesDeNascimento.comum()
	var id_novo := _gerador_ids.proximo()
	var eh_chefe := def.comportamento == &"chefe"
	var eh_elite := opt.elite and not eh_chefe and not opt.invocado_pelo_chefe
	var ref := InimigoRef.new(id_novo, def, eh_chefe, eh_elite)
	ref.portador = portador
	var est := EstadoDeInimigoIA.new()
	est.ref = ref
	est.id = id_novo
	est.def = def
	est.elite = eh_elite
	est.chefe = eh_chefe
	est.invocado_pelo_chefe = opt.invocado_pelo_chefe
	est.ordem = opt.ordem
	est.profundidade = opt.profundidade
	est.posicao = pos
	est.raio = RegrasDeElite.calcular_raio(def.raio_px, eh_elite, _regras_elite)
	est.vida_max = RegrasDeElite.calcular_vida_max(def.vida, opt.profundidade, eh_elite,
		eh_chefe, opt.invocado_pelo_chefe, _regras_elite, _tuning.bonus_vida_por_profundidade)
	est.vida = est.vida_max
	est.dano_base = RegrasDeElite.calcular_dano_base(def.dano, eh_elite, _regras_elite)
	est.velocidade_base = def.velocidade
	est.fator_empurrao = RegrasDeElite.calcular_fator_empurrao(eh_elite, eh_chefe, _regras_elite)
	if portador != null:
		RegrasDeElite.aplicar_fontes_no_portador(portador, opt.profundidade, eh_elite,
			eh_chefe, opt.invocado_pelo_chefe, _regras_elite, _tuning.bonus_vida_por_profundidade)
	est.fase = EstadoDeInimigoIA.Fase.SURGINDO
	est.timer = Unidades.duracao_para_passos(_tuning.surgimento_s)
	if eh_elite or eh_chefe:
		est.armadura_ativa = true
		if opt.armadura_hits > 0:
			est.armadura_permanente = false
			est.armadura_hits_restantes = opt.armadura_hits
		else:
			est.armadura_permanente = true
			est.armadura_hits_restantes = 0
	# R22: alvo_padrao no nascimento (ACUADA se há acuada em Acuada e ordem >= 0 par; senão JOGADOR)
	if not eh_chefe and opt.ordem >= 0 and (opt.ordem % 2) == 0 and _acuada != null and _acuada.acuada_atingivel():
		est.alvo_padrao = TelegrafoTipos.FaccaoAlvo.ACUADA
	else:
		est.alvo_padrao = TelegrafoTipos.FaccaoAlvo.JOGADOR
	if eh_chefe:
		est.estado_chefe = EstadoDoChefe.new()
		est.estado_chefe.subjugavel = opt.subjugavel
	est.sincronizar_ref()

	# Mantém lista ordenada por id crescente
	var idx := _inimigos.size()
	while idx > 0 and _inimigos[idx - 1].id > id_novo:
		idx -= 1
	_inimigos.insert(idx, est)
	_por_id[id_novo] = est
	return id_novo


## Esvazia a lista na troca de câmara; o gerador de ids nunca reinicia na run (R19, AC-IA-41).
func camara_nova() -> void:
	_inimigos.clear()
	_por_id.clear()
	_invocacoes_pendentes.clear()


func ids_na_lista() -> Array[int]:
	var out: Array[int] = []
	for e: EstadoDeInimigoIA in _inimigos:
		out.append(e.id)
	return out


func estado_de(id: int) -> EstadoDeInimigoIA:
	return _por_id.get(id, null)


func ref_de(id: int) -> InimigoRef:
	var e: EstadoDeInimigoIA = _por_id.get(id, null)
	return e.ref if e != null else null


func vivo(inimigo_id: int) -> bool:
	var e: EstadoDeInimigoIA = _por_id.get(inimigo_id, null)
	if e == null:
		return false
	return e.vida > 0.0 and e.fase != EstadoDeInimigoIA.Fase.SUBJUGADO and e.fase != EstadoDeInimigoIA.Fase.MORTO


func atingivel(inimigo_id: int) -> bool:
	var e: EstadoDeInimigoIA = _por_id.get(inimigo_id, null)
	if e == null:
		return false
	return e.vida > 0.0 \
		and e.fase != EstadoDeInimigoIA.Fase.SURGINDO \
		and e.fase != EstadoDeInimigoIA.Fase.SUBJUGADO \
		and e.fase != EstadoDeInimigoIA.Fase.MORTO


# --- Ciclo do item 7 (ADR-0018 §2, §3, §6) -----------------------------------

func inicio_do_item_7() -> void:
	if _modulo_chefes != null and _modulo_chefes.has_method(&"passo_vivo"):
		_modulo_chefes.call(&"passo_vivo")


## Executa o passo completo do item 7 sobre o retrato atual da lista (útil para testes e orquestrador).
func executar_item_7() -> void:
	if _jogador_morto:
		return
	if _telegrafos != null:
		_telegrafos.varrer()
	inicio_do_item_7()
	var retrato_ids := ids_na_lista()
	for id_in: int in retrato_ids:
		if not vivo(id_in):
			continue
		var e: EstadoDeInimigoIA = _por_id[id_in]
		if e.ref != null and e.ref.portador is Portador:
			(e.ref.portador as Portador).avancar(1)
		if _telegrafos != null:
			_telegrafos.avancar(id_in)
		passo(id_in)
	fim_do_item_7()


## Passo individual de um inimigo no item 7 (ADR-0018 §3).
func passo(inimigo_id: int) -> void:
	if _jogador_morto:
		return
	var i: EstadoDeInimigoIA = _por_id.get(inimigo_id, null)
	if i == null:
		return
	# 1. Vida <= 0 ou SUBJUGADO: morto não age (R2, R21)
	if i.vida <= 0.0 or i.fase == EstadoDeInimigoIA.Fase.SUBJUGADO or i.fase == EstadoDeInimigoIA.Fase.MORTO:
		return
	# 2. SURGINDO: só desce timer; ao chegar a 0 passa a APROXIMACAO
	if i.fase == EstadoDeInimigoIA.Fase.SURGINDO:
		i.timer -= 1
		if i.timer <= 0:
			_comportamento_de(i).ao_surgir(i, self)
		i.sincronizar_ref()
		return
	# 3. Lê o alvo efetivo ANTES de descer atração, respiro e imobilização (R16, R17, R18, ADR-0018 §3 passo 3)
	var alvo: AlvoDeInimigo = alvo_efetivo(inimigo_id)
	var imobilizado_neste_passo: bool = i.restante_imob > 0
	if i.restante_atracao > 0:
		i.restante_atracao -= 1
		if i.restante_atracao == 0:
			i.restante_respiro = i.respiro_guardado
			i.maldicao_atracao_id = -1
	elif i.restante_respiro > 0:
		i.restante_respiro -= 1
	if i.restante_imob > 0:
		i.restante_imob -= 1

	# 4. Decisão por comportamento (se estava imobilizado neste passo, comporta-se como imobilizado no passo inteiro, AC-IA-37)
	var imob_apos_decremento: int = i.restante_imob
	if imobilizado_neste_passo:
		i.restante_imob = maxi(1, i.restante_imob)
	var era_avanco: bool = (i.fase == EstadoDeInimigoIA.Fase.EXECUCAO) and (
		i.def.comportamento == &"arremetida" or i.def.comportamento == &"charger" \
		or (i.chefe and i.estado_chefe != null and i.estado_chefe.padrao == 1)
	)
	_comportamento_de(i).decidir(i, alvo, self)
	if imobilizado_neste_passo:
		i.restante_imob = imob_apos_decremento

	# 5. Conter contra obstáculos e retângulo da câmara (R9)
	if not era_avanco:
		i.posicao = conter(i.posicao, i.raio)
	i.sincronizar_ref()

	# Se o chefe pediu invocação de lacaios no Padrão 3, cria no fim do passo() do chefe (ADR-0018 §8)
	if i.chefe and not _invocacoes_pendentes.is_empty():
		_processar_invocacoes_do_chefe()


## Separação par a par no fim do item 7 (R9, ADR-0018 §6: um passe i < j em ordem de id, metade da sobreposição).
func fim_do_item_7() -> void:
	if _jogador_morto:
		return
	var ativos: Array[EstadoDeInimigoIA] = []
	for e: EstadoDeInimigoIA in _inimigos:
		if e.vida > 0.0 and e.fase != EstadoDeInimigoIA.Fase.SURGINDO \
				and e.fase != EstadoDeInimigoIA.Fase.SUBJUGADO \
				and e.fase != EstadoDeInimigoIA.Fase.MORTO:
			ativos.append(e)
	var n := ativos.size()
	var deslocados: Dictionary[int, bool] = {}
	for idx_a in n:
		var a := ativos[idx_a]
		for idx_b in range(idx_a + 1, n):
			var b := ativos[idx_b]
			var r_soma := a.raio + b.raio
			var delta := b.posicao - a.posicao
			var d2 := delta.length_squared()
			if d2 < r_soma * r_soma:
				var d := sqrt(d2)
				var metade := (r_soma - d) * 0.5
				# ADR-0018 §6: com centros iguais, normal (0, -1) para i e (0, 1) para j
				var normal_a := Vector2.UP if d == 0.0 else -(delta / d)
				a.posicao += normal_a * metade
				b.posicao -= normal_a * metade
				deslocados[a.id] = true
				deslocados[b.id] = true
	for e: EstadoDeInimigoIA in ativos:
		if deslocados.has(e.id):
			e.posicao = conter(e.posicao, e.raio)
			e.sincronizar_ref()


# --- Seleção de alvo, atração, imobilização e puxar (R16–R20, R22; ADR-0018 §4, §5) -

func alvo_efetivo(inimigo_id: int) -> AlvoDeInimigo:
	var i: EstadoDeInimigoIA = _por_id.get(inimigo_id, null)
	var out: AlvoDeInimigo = i.alvo_cache if i != null else AlvoDeInimigo.new()
	if i != null and i.restante_atracao > 0 and _maldicoes != null:
		var m_campo: int = _maldicoes.maldicao_em_campo(i.player_atracao_id)
		if m_campo != -1 and (i.maldicao_atracao_id == -1 or m_campo == i.maldicao_atracao_id):
			var pr: Vector3 = _maldicoes.posicao_e_raio(m_campo)
			out.faccao = TelegrafoTipos.FaccaoAlvo.ALIADO
			out.id = m_campo
			out.player_id = i.player_atracao_id
			out.pos = Vector2(pr.x, pr.y)
			out.raio = pr.z if pr.z > 0.0 else 24.0
			return out
	# R22: mesmo sem ter nascido antes, se ordem é par (>= 0) e a acuada está em Acuada, alvo_padrao é ACUADA
	var usa_acuada: bool = i != null and not i.chefe and i.ordem >= 0 and (i.ordem % 2) == 0 \
		and _acuada != null and _acuada.acuada_atingivel()
	if usa_acuada:
		var pa: Vector3 = _acuada.posicao_e_raio_acuada()
		out.faccao = TelegrafoTipos.FaccaoAlvo.ACUADA
		out.id = 0
		out.player_id = 0
		out.pos = Vector2(pa.x, pa.y)
		out.raio = pa.z if pa.z > 0.0 else 22.5
		return out
	out.faccao = TelegrafoTipos.FaccaoAlvo.JOGADOR
	out.id = 0
	out.player_id = 0
	out.pos = _jogadores_pos.get(0, Vector2.ZERO)
	out.raio = _jogadores_raios.get(0, 27.0)
	return out


## R17: Pedido `atrair(id, passos, passos_respiro)` sem renovação e com respiro.
func atrair(id: int, passos: int, passos_respiro: int = 30, player_id: int = 0) -> bool:
	if passos <= 0 or not atingivel(id):
		return false
	var i: EstadoDeInimigoIA = _por_id[id]
	if i.chefe and i.fase == EstadoDeInimigoIA.Fase.TRANSICAO_FASE:
		return false
	if _maldicoes == null:
		return false
	var m_id: int = _maldicoes.maldicao_em_campo(player_id)
	if m_id == -1:
		return false
	if i.restante_atracao > 0 or i.restante_respiro > 0:
		return false
	i.restante_atracao = passos
	i.respiro_guardado = maxi(0, passos_respiro)
	i.maldicao_atracao_id = m_id
	i.player_atracao_id = player_id
	return true


## R16 / R21: Chamado síncrono quando a Maldição sai de campo (Troca, Exaustão ou troca de câmara).
func maldicao_saiu_de_campo(player_id: int = 0) -> void:
	_epoca_campo[player_id] = int(_epoca_campo.get(player_id, 0)) + 1
	for e: EstadoDeInimigoIA in _inimigos:
		if e.restante_atracao > 0 and e.player_atracao_id == player_id:
			e.restante_atracao = 0
			e.restante_respiro = e.respiro_guardado
			e.maldicao_atracao_id = -1


## R18: Pedido `imobilizar(id, passos)` — só aceita comuns atingíveis (inclusive lacaios); elite e chefe recusam.
func imobilizar(id: int, passos: int) -> bool:
	if passos <= 0 or not atingivel(id):
		return false
	var i: EstadoDeInimigoIA = _por_id[id]
	if i.elite or i.chefe or i.armadura_ativa:
		return false
	i.restante_imob = maxi(i.restante_imob, passos)
	return true


## R18b / TR-ia-019 / AC-IA-58: Pedido `puxar(id, centro, distancia_px, parar_a_px)` — aceita comuns e elites, chefe recusa.
func puxar(id: int, centro: Vector2, distancia_px: float, parar_a_px: float) -> bool:
	if distancia_px <= 0.0 or not atingivel(id):
		return false
	var i: EstadoDeInimigoIA = _por_id[id]
	if i.chefe:
		return false
	var d: float = (centro - i.posicao).length()
	if d <= parar_a_px + 1e-6:
		return false
	i.posicao = FormulasDoChefe.calcular_posicao_puxada(
		i.posicao, i.raio, centro, distancia_px, parar_a_px, _geometria)
	i.sincronizar_ref()
	return true


func esta_atraido(id: int) -> bool:
	var i: EstadoDeInimigoIA = _por_id.get(id, null)
	if i == null or i.restante_atracao <= 0:
		return false
	if _maldicoes == null or _maldicoes.maldicao_em_campo(i.player_atracao_id) == -1:
		return false
	return true


func esta_imobilizado(id: int) -> bool:
	var i: EstadoDeInimigoIA = _por_id.get(id, null)
	return i != null and i.restante_imob > 0


## R20: Função de conter contra obstáculos e retângulo da câmara (exposta para as Maldições).
func conter(pos: Vector2, raio: float) -> Vector2:
	if _geometria == null:
		return pos
	return Colisao.resolver_colisao(pos, raio, _geometria)


## R19: Lista somente leitura dos inimigos atingíveis em ordem estável de id (sem Maldição, sem acuada, sem SURGINDO/SUBJUGADO).
func atingiveis() -> Array[VistaDeInimigo]:
	var out: Array[VistaDeInimigo] = []
	var idx_pool := 0
	for e: EstadoDeInimigoIA in _inimigos:
		if not atingivel(e.id):
			continue
		while idx_pool >= _vistas_atingiveis.size():
			_vistas_atingiveis.append(VistaDeInimigo.new())
		var v := _vistas_atingiveis[idx_pool]
		_preencher_vista(e, v)
		out.append(v)
		idx_pool += 1
	return out


## R19 / AC-IA-41: Inimigo atingível de menor `(dist², id)` com `dist <= raio_max` (inclusivo); -1 se nenhum.
func mais_perto(ponto: Vector2, raio_max: float, ignorar_distancia_zero: bool = false) -> int:
	if raio_max < 0.0:
		return -1
	var r2_max := raio_max * raio_max + 1e-4
	var melhor_id := -1
	var melhor_d2 := INF
	for e: EstadoDeInimigoIA in _inimigos:
		if not atingivel(e.id):
			continue
		var d2 := (e.posicao - ponto).length_squared()
		if ignorar_distancia_zero and d2 == 0.0:
			continue
		if d2 <= r2_max and d2 < melhor_d2 - 1e-6:
			melhor_d2 = d2
			melhor_id = e.id
	return melhor_id


func publicar(saida: Array[VistaDeInimigo]) -> int:
	var n := 0
	var limite := saida.size()
	for e: EstadoDeInimigoIA in _inimigos:
		if e.vida <= 0.0 and e.fase != EstadoDeInimigoIA.Fase.SUBJUGADO:
			continue
		if n >= limite:
			break
		if saida[n] == null:
			saida[n] = VistaDeInimigo.new()
		_preencher_vista(e, saida[n])
		n += 1
	return n


func _preencher_vista(e: EstadoDeInimigoIA, v: VistaDeInimigo) -> void:
	v.id = e.id
	v.definicao_id = e.def.id if e.def != null else &""
	v.pos = e.posicao
	v.raio = e.raio
	v.vida = e.vida
	v.vida_max = e.vida_max
	v.elite = e.elite
	v.chefe = e.chefe
	v.armadura_ativa = e.armadura_ativa
	v.invocado_pelo_chefe = e.invocado_pelo_chefe
	v.fase = int(e.fase)
	v.padrao = e.estado_chefe.padrao if e.estado_chefe != null else 0
	v.em_furia = e.estado_chefe.em_furia if e.estado_chefe != null else false
	v.atraido = esta_atraido(e.id)
	v.imobilizado = esta_imobilizado(e.id)
	v.subjugado = e.fase == EstadoDeInimigoIA.Fase.SUBJUGADO


# --- Interface definida pelo Combate (ADR-0010, ADR-0018 §8) ------------------

func remover_morto(id: int) -> void:
	if not _por_id.has(id):
		return
	var e: EstadoDeInimigoIA = _por_id[id]
	e.vida = 0.0
	e.fase = EstadoDeInimigoIA.Fase.MORTO
	e.sincronizar_ref()
	if _telegrafos != null:
		_telegrafos.cancelar(id, TelegrafoTipos.CausaCancelamento.DONO_MORTO)
	_por_id.erase(id)
	_inimigos.erase(e)


## R8: Pedido de quebra ("Quebrou!") quando um golpe pesado acerta um inimigo em Preparo.
## Se for Elite com Armadura de Elite quebrável por hits (`armadura_hits_restantes > 0`), absorve até zerar e então quebra com `"Quebrou!"` + hitstop.
## Elites de armadura permanente e chefes nunca quebram nem cambaleiam (AC-IA-11, AC-IA-18, AC-CH-02).
func pedir_recuperacao(id: int, passos: int = -1, hitstop_quebra: int = 6) -> bool:
	var i: EstadoDeInimigoIA = _por_id.get(id, null)
	if i == null or not vivo(id):
		return false
	if i.chefe:
		return false
	if i.armadura_ativa:
		if i.armadura_permanente:
			return false
		i.armadura_hits_restantes -= 1
		if i.armadura_hits_restantes > 0:
			return false
		i.armadura_ativa = false
	if i.fase != EstadoDeInimigoIA.Fase.PREPARO:
		return false
	var p_rec: int = passos if passos > 0 else Unidades.duracao_para_passos(_tuning.quebrou_recuperacao_s)
	if _telegrafos != null:
		_telegrafos.quebrar(id)
	i.fase = EstadoDeInimigoIA.Fase.RECUPERACAO
	i.timer = p_rec
	i.sincronizar_ref()
	if _combate != null and hitstop_quebra > 0:
		_combate.pedir_hitstop(hitstop_quebra)
	if _eventos != null:
		_eventos.emitir(EventosDeIA.EvQuebrouArmadura.new(id, i.elite))
	return true


## Aplica empurrão/cambaleio de um impacto no inimigo, respeitando Armadura de Elite/Chefe (R8, R9, R10).
func aplicar_impacto_combate(id: int, deslocamento_empurrao: Vector2, passos_cambaleio: int = 0) -> void:
	var i: EstadoDeInimigoIA = _por_id.get(id, null)
	if i == null or not vivo(id) or invulneravel_por_fase(id):
		return
	var desl: Vector2 = deslocamento_empurrao * i.fator_empurrao
	if desl != Vector2.ZERO:
		i.posicao = conter(i.posicao + desl, i.raio)
	if passos_cambaleio > 0 and not i.armadura_ativa and not i.chefe and not i.elite and i.ref != null:
		i.ref.impacto_passos = maxi(i.ref.impacto_passos, passos_cambaleio)
	i.sincronizar_ref()


## R21 / Chefes R9: Põe Vida 0, para a IA do chefe e mantém-no na lista em `SUBJUGADO` (fora de `atingiveis()` e da separação).
func subjugar(inimigo_id: int) -> void:
	var i: EstadoDeInimigoIA = _por_id.get(inimigo_id, null)
	if i == null:
		return
	i.vida = 0.0
	i.fase = EstadoDeInimigoIA.Fase.SUBJUGADO
	i.restante_atracao = 0
	i.restante_imob = 0
	if _telegrafos != null:
		_telegrafos.cancelar(inimigo_id, TelegrafoTipos.CausaCancelamento.QUEDA_CHEFE)
	# Limpa todos os lacaios invocados pelo chefe no mesmo passo (Chefes R8, R9)
	limpar_lacaios_invocados()
	i.sincronizar_ref()


func limpar_lacaios_invocados() -> Array[int]:
	var removidos: Array[int] = []
	var copia: Array[EstadoDeInimigoIA] = _inimigos.duplicate()
	for e: EstadoDeInimigoIA in copia:
		if e.invocado_pelo_chefe:
			removidos.append(e.id)
			if _telegrafos != null:
				_telegrafos.cancelar(e.id, TelegrafoTipos.CausaCancelamento.QUEDA_CHEFE)
			_por_id.erase(e.id)
			_inimigos.erase(e)
	return removidos


## Chefes R7 / F4 / ADR-0018 §8: Chamado pelo Combate sempre que o chefe perde Vida.
func notificar_dano_no_chefe(id: int) -> void:
	var i: EstadoDeInimigoIA = _por_id.get(id, null)
	if i == null or not i.chefe or i.estado_chefe == null:
		return
	var ec: EstadoDoChefe = i.estado_chefe
	if ec.em_furia or ec.transicao_ja_ocorreu or i.fase == EstadoDeInimigoIA.Fase.TRANSICAO_FASE:
		return
	if i.vida <= 0.0:
		# AC-CH-14: dano letal direto de > 350 para <= 0 pula a TransicaoFase!
		return
	var frac: float = _chefes_tuning.limiar_furia_frac if _chefes_tuning != null else 0.50
	var limiar: int = FormulasDoChefe.limiar_vida_furia(i.vida_max, frac)
	if i.vida <= float(limiar) + 1e-5:
		if i.fase == EstadoDeInimigoIA.Fase.EXECUCAO:
			ec.transicao_pendente = true
		else:
			var avancar_padrao: bool = (i.fase == EstadoDeInimigoIA.Fase.PREPARO)
			entrar_em_transicao_fase_chefe(i, avancar_padrao)


func entrar_em_transicao_fase_chefe(i: EstadoDeInimigoIA, avancar_padrao_ao_sair: bool) -> void:
	var ec: EstadoDoChefe = i.estado_chefe
	ec.transicao_ja_ocorreu = true
	ec.avancar_padrao_ao_sair = avancar_padrao_ao_sair
	ec.pulso_pendente = true
	if _telegrafos != null:
		_telegrafos.cancelar(i.id, TelegrafoTipos.CausaCancelamento.TRANSICAO_FASE)
	# Zera atração e abre respiro no mesmo passo (Chefes R7, AC-IA-49)
	if i.restante_atracao > 0:
		i.restante_atracao = 0
		i.restante_respiro = i.respiro_guardado
		i.maldicao_atracao_id = -1
	var dur_s: float = _chefes_tuning.transicao_fase_s if _chefes_tuning != null else 0.50
	i.fase = EstadoDeInimigoIA.Fase.TRANSICAO_FASE
	i.timer = Unidades.duracao_para_passos(dur_s)
	i.sincronizar_ref()


func invulneravel_por_fase(id: int) -> bool:
	var i: EstadoDeInimigoIA = _por_id.get(id, null)
	return i != null and i.fase == EstadoDeInimigoIA.Fase.TRANSICAO_FASE


# --- Apoio interno aos comportamentos ----------------------------------------

func _comportamento_de(i: EstadoDeInimigoIA) -> Comportamento:
	if i.chefe or i.def.comportamento == &"chefe":
		return _comp_chefe
	if i.def.comportamento == &"distancia" or i.def.comportamento == &"ranged":
		return _comp_ranged
	if i.def.comportamento == &"arremetida" or i.def.comportamento == &"charger":
		return _comp_charger
	return _comp_melee


func velocidade_andar_passo(i: EstadoDeInimigoIA) -> float:
	if i.restante_imob > 0:
		return 0.0
	var v_pxs := i.velocidade_base
	if i.chefe and i.estado_chefe != null and i.estado_chefe.em_furia:
		var mult_furia := _chefes_tuning.mult_velocidade_furia if _chefes_tuning != null else 1.15
		v_pxs *= mult_furia
	var f_selo := _tuning.fator_lentidao_selo if (i.ref != null and i.ref.no_selo) else 1.0
	var f_camb := _tuning.fator_cambaleio if (i.ref != null and i.ref.impacto_passos > 0 and not i.elite and not i.chefe) else 1.0
	var f_atr := 1.0
	if esta_atraido(i.id) and _maldicoes != null:
		f_atr = _maldicoes.fator_andar_atraido(i.player_atracao_id)
	return (v_pxs * f_selo * f_camb * f_atr) / float(Unidades.TICK_RATE)


func sortear_espera_inicial() -> int:
	var base := Unidades.duracao_para_passos(_tuning.espera_inicial_base_s)
	var var_n := Unidades.duracao_para_passos(_tuning.espera_inicial_var_s)
	var n := _fluxo_ia.inteiro(maxi(1, var_n)) if _fluxo_ia != null else 0
	return base + n


func sortear_espera_pos_recuperacao() -> int:
	var base := Unidades.duracao_para_passos(_tuning.espera_base_s)
	var var_n := Unidades.duracao_para_passos(_tuning.espera_var_s)
	var n := _fluxo_ia.inteiro(maxi(1, var_n)) if _fluxo_ia != null else 0
	return base + n


func esta_na_vista(pos: Vector2) -> bool:
	if _vista == null:
		return true
	var rect := _vista.retangulo_visivel().grow(_tuning.margem_visivel_px)
	return rect.has_point(pos)


func tentar_iniciar_preparo(i: EstadoDeInimigoIA, alvo: AlvoDeInimigo) -> bool:
	i.alvo_travado_faccao = alvo.faccao
	i.alvo_travado_id = alvo.id
	i.alvo_travado_player_id = alvo.player_id
	i.alvo_travado_raio = alvo.raio
	i.epoca_campo_travada = int(_epoca_campo.get(alvo.player_id, 0))
	if _telegrafos == null:
		return true
	return _telegrafos.iniciar_telegrafo(i.id, i.def, alvo.id, alvo.faccao)


func tentar_iniciar_preparo_chefe(i: EstadoDeInimigoIA, padrao: BossPatternDef, alvo: AlvoDeInimigo) -> bool:
	i.alvo_travado_faccao = alvo.faccao
	i.alvo_travado_id = alvo.id
	i.alvo_travado_player_id = alvo.player_id
	i.alvo_travado_raio = alvo.raio
	i.epoca_campo_travada = int(_epoca_campo.get(alvo.player_id, 0))
	if _telegrafos == null:
		return true
	return _telegrafos.iniciar_telegrafo_chefe(i.id, padrao, i.raio, alvo.id, alvo.faccao)


func _alvo_travado_valido(i: EstadoDeInimigoIA) -> bool:
	match i.alvo_travado_faccao:
		TelegrafoTipos.FaccaoAlvo.ALIADO:
			if int(_epoca_campo.get(i.alvo_travado_player_id, 0)) != i.epoca_campo_travada:
				return false
			return _maldicoes != null and _maldicoes.maldicao_atingivel(i.alvo_travado_id) \
				and _maldicoes.maldicao_em_campo(i.alvo_travado_player_id) == i.alvo_travado_id
		TelegrafoTipos.FaccaoAlvo.ACUADA:
			return _acuada != null and _acuada.acuada_atingivel()
		_:
			return not _jogador_morto


func _multiplicador_dano_inimigo(i: EstadoDeInimigoIA) -> float:
	if i.ref != null and i.ref.portador is Portador:
		var p := i.ref.portador as Portador
		return p.multiplicador_de_dano(Modificador.Slot.NENHUM, ContextoDeDano.new(i.vida, false))
	return 1.0


func _entregar_dano_no_alvo_travado(i: EstadoDeInimigoIA, dano_base: float, ataque_id: StringName) -> void:
	if _combate == null:
		return
	var m := _multiplicador_dano_inimigo(i)
	match i.alvo_travado_faccao:
		TelegrafoTipos.FaccaoAlvo.ALIADO:
			_combate.ferir_maldicao(i.alvo_travado_id, dano_base, m, i.id, ataque_id)
		TelegrafoTipos.FaccaoAlvo.ACUADA:
			_combate.ferir_acuada(dano_base, m, i.id, ataque_id)
		_:
			_combate.ferir_jogador(i.alvo_travado_id, dano_base, m, i.id, ataque_id)


func resolver_golpe_setor_travado(i: EstadoDeInimigoIA, dano_base: float, ataque_id: StringName) -> void:
	if not _alvo_travado_valido(i):
		return
	var acertou := false
	if _telegrafos != null:
		acertou = _telegrafos.acerta_alvo_travado(i.id)
	else:
		var pos_alvo := posicao_alvo(i.alvo_travado_faccao, i.alvo_travado_id)
		var r_setor := i.def.alcance_px + i.alvo_travado_raio + 0.5 * i.raio
		acertou = GeometriaDeAcerto.setor_toca(i.posicao, i.ultima_direcao,
			TelegrafoTipos.COS_MEIO_SETOR_PADRAO, r_setor, pos_alvo, 0.0)
	if acertou:
		_entregar_dano_no_alvo_travado(i, dano_base, ataque_id)


func resolver_golpe_circular_travado(i: EstadoDeInimigoIA, raio_golpe: float,
		dano_base: float, empurrao_pxs: float, ataque_id: StringName) -> void:
	if not _alvo_travado_valido(i):
		return
	var pos_alvo := posicao_alvo(i.alvo_travado_faccao, i.alvo_travado_id)
	var acertou := false
	if _telegrafos != null and _telegrafos.estado_de(i.id) != TelegrafoTipos.Estado.LIVRE:
		acertou = _telegrafos.dentro(i.id, pos_alvo)
	else:
		acertou = GeometriaDeAcerto.circulo_toca(i.posicao, raio_golpe, pos_alvo, 0.0)
	if acertou:
		_entregar_dano_no_alvo_travado(i, dano_base, ataque_id)
		if empurrao_pxs > 0.0 and _combate != null:
			var delta := pos_alvo - i.posicao
			var dir := Vector2.RIGHT if delta.length_squared() == 0.0 else delta.normalized()
			_combate.aplicar_empurrao_no_alvo(i.alvo_travado_faccao, i.alvo_travado_id, dir, empurrao_pxs)


func testar_e_ferir_contato_avanco(i: EstadoDeInimigoIA, dano_base: float, ataque_id: StringName) -> bool:
	if not _alvo_travado_valido(i):
		return false
	var pos_alvo := posicao_alvo(i.alvo_travado_faccao, i.alvo_travado_id)
	var r_c := i.raio + i.alvo_travado_raio
	if GeometriaDeAcerto.circulos_encostam(i.posicao, pos_alvo, r_c):
		_entregar_dano_no_alvo_travado(i, dano_base, ataque_id)
		return true
	return false


func disparar_projetil_travado(i: EstadoDeInimigoIA) -> void:
	if _combate == null:
		return
	var mira := _telegrafos.mira_de(i.id) if _telegrafos != null else i.ultima_direcao
	if mira.length_squared() == 0.0:
		mira = Vector2.RIGHT
	else:
		mira = mira.normalized()
	var saida := i.raio + TelegrafoTipos.SAIDA_OFFSET_PX
	var pos_saida := i.posicao + mira * saida
	var vida_s := float(TelegrafoTipos.VIDA_PROJETIL_PADRAO_PASSOS) / float(Unidades.TICK_RATE)
	var m := _multiplicador_dano_inimigo(i)
	var faccao_alvo := i.alvo_travado_faccao
	var id_alvo := i.alvo_travado_id if _alvo_travado_valido(i) else -999999
	_combate.disparar_projetil(i.id, pos_saida, mira, i.def.velocidade_projetil,
		TelegrafoTipos.RAIO_PROJETIL_PADRAO_PX, vida_s, i.dano_base, m, false,
		faccao_alvo, id_alvo)


func disparar_projetil_radial_chefe(i: EstadoDeInimigoIA, pos_saida: Vector2, dir: Vector2,
		vel_pxs: float, raio_proj: float, vida_s: float, dano_proj: float) -> void:
	if _combate == null:
		return
	var m := _multiplicador_dano_inimigo(i)
	var faccao_alvo := i.alvo_travado_faccao
	var id_alvo := i.alvo_travado_id if _alvo_travado_valido(i) else -999999
	_combate.disparar_projetil(i.id, pos_saida, dir, vel_pxs, raio_proj, vida_s,
		dano_proj, m, false, faccao_alvo, id_alvo)


func aplicar_puxao_convergencia(pos_chefe: Vector2, raio_chefe: float) -> void:
	var raio_puxao: float = _chefes_tuning.raio_puxao_px if _chefes_tuning != null else 420.0
	var passo_puxao: float = _chefes_tuning.puxao_convergencia_px if _chefes_tuning != null else 75.0
	# Puxa o jogador se dentro de raio_puxao e não imune
	var pos_jog: Vector2 = _jogadores_pos.get(0, Vector2.ZERO)
	var r_jog: float = _jogadores_raios.get(0, 27.0)
	var d_jog: float = (pos_jog - pos_chefe).length()
	if d_jog > 0.0 and d_jog <= raio_puxao + 1e-5:
		if _deslocamentos == null or not _deslocamentos.imune(TelegrafoTipos.FaccaoAlvo.JOGADOR, 0):
			var nova_jog: Vector2 = FormulasDoChefe.calcular_posicao_puxada(
				pos_jog, r_jog, pos_chefe, passo_puxao, raio_chefe + r_jog, _geometria)
			var delta_jog: Vector2 = nova_jog - pos_jog
			_jogadores_pos[0] = nova_jog
			if _deslocamentos != null and delta_jog != Vector2.ZERO:
				_deslocamentos.deslocar(TelegrafoTipos.FaccaoAlvo.JOGADOR, 0, delta_jog)

	# Puxa a Maldição em campo se existir, dentro de raio_puxao e não imune (ex.: não Saltando)
	if _maldicoes != null:
		var m_id: int = _maldicoes.maldicao_em_campo(0)
		if m_id != -1 and _maldicoes.maldicao_atingivel(m_id):
			var pr: Vector3 = _maldicoes.posicao_e_raio(m_id)
			var pos_m: Vector2 = Vector2(pr.x, pr.y)
			var r_m: float = pr.z if pr.z > 0.0 else 24.0
			var d_m: float = (pos_m - pos_chefe).length()
			if d_m > 0.0 and d_m <= raio_puxao + 1e-5:
				if _deslocamentos == null or not _deslocamentos.imune(TelegrafoTipos.FaccaoAlvo.ALIADO, m_id):
					var nova_m: Vector2 = FormulasDoChefe.calcular_posicao_puxada(
						pos_m, r_m, pos_chefe, passo_puxao, raio_chefe + r_m, _geometria)
					var delta_m: Vector2 = nova_m - pos_m
					if _deslocamentos != null and delta_m != Vector2.ZERO:
						_deslocamentos.deslocar(TelegrafoTipos.FaccaoAlvo.ALIADO, m_id, delta_m)


func aplicar_pulso_transicao_furia(i: EstadoDeInimigoIA) -> void:
	var raio_pulso: float = _chefes_tuning.raio_pulso_furia_px if _chefes_tuning != null else 240.0
	var emp_pulso: float = _chefes_tuning.empurrao_pulso_furia_px if _chefes_tuning != null else 120.0
	var pos_jog: Vector2 = _jogadores_pos.get(0, Vector2.ZERO)
	var r_jog: float = _jogadores_raios.get(0, 27.0)
	if (pos_jog - i.posicao).length() < raio_pulso:
		if _deslocamentos == null or not _deslocamentos.imune(TelegrafoTipos.FaccaoAlvo.JOGADOR, 0):
			var nova_jog: Vector2 = FormulasDoChefe.calcular_posicao_repelida_furia(
				pos_jog, r_jog, i.posicao, raio_pulso, emp_pulso, _geometria)
			var delta_jog: Vector2 = nova_jog - pos_jog
			_jogadores_pos[0] = nova_jog
			if _deslocamentos != null and delta_jog != Vector2.ZERO:
				_deslocamentos.deslocar(TelegrafoTipos.FaccaoAlvo.JOGADOR, 0, delta_jog)

	if _maldicoes != null:
		var m_id: int = _maldicoes.maldicao_em_campo(0)
		if m_id != -1 and _maldicoes.maldicao_atingivel(m_id):
			var pr: Vector3 = _maldicoes.posicao_e_raio(m_id)
			var pos_m: Vector2 = Vector2(pr.x, pr.y)
			var r_m: float = pr.z if pr.z > 0.0 else 24.0
			if (pos_m - i.posicao).length() < raio_pulso:
				if _deslocamentos == null or not _deslocamentos.imune(TelegrafoTipos.FaccaoAlvo.ALIADO, m_id):
					var nova_m: Vector2 = FormulasDoChefe.calcular_posicao_repelida_furia(
						pos_m, r_m, i.posicao, raio_pulso, emp_pulso, _geometria)
					var delta_m: Vector2 = nova_m - pos_m
					if _deslocamentos != null and delta_m != Vector2.ZERO:
						_deslocamentos.deslocar(TelegrafoTipos.FaccaoAlvo.ALIADO, m_id, delta_m)


func enfileirar_invocacao_convergencia(pos_chefe: Vector2) -> void:
	var max_lac: int = _chefes_tuning.max_lacaios_vivos if _chefes_tuning != null else 3
	var por_conv: int = _chefes_tuning.lacaios_por_convergencia if _chefes_tuning != null else 2
	var dist_sp: float = _chefes_tuning.dist_spawn_lacaio_px if _chefes_tuning != null else 135.0
	var lac_vivos: int = contar_lacaios_vivos()
	var tot_vivos: int = contar_vivos()
	var n_inv: int = FormulasDoChefe.quantidade_lacaios_para_invocar(
		lac_vivos, tot_vivos, max_lac, por_conv, _max_inimigos_onda)
	if n_inv <= 0:
		return
	var r_lac: float = _def_lacaio.raio_px if _def_lacaio != null else 24.0
	var pts: Array[Vector2] = FormulasDoChefe.posicoes_spawn_lacaios(pos_chefe, n_inv, dist_sp, r_lac, 12.0, _geometria)
	for p: Vector2 in pts:
		_invocacoes_pendentes.append(p)


func _processar_invocacoes_do_chefe() -> void:
	if _def_lacaio == null:
		_def_lacaio = _eco_perdido_padrao()
	for pos_sp: Vector2 in _invocacoes_pendentes:
		criar_inimigo(_def_lacaio, pos_sp, OpcoesDeNascimento.lacaio_do_chefe())
	_invocacoes_pendentes.clear()


func contar_lacaios_vivos() -> int:
	var n: int = 0
	for e: EstadoDeInimigoIA in _inimigos:
		if e.invocado_pelo_chefe and vivo(e.id):
			n += 1
	return n


func contar_vivos() -> int:
	var n: int = 0
	for e: EstadoDeInimigoIA in _inimigos:
		if vivo(e.id):
			n += 1
	return n


static func _eco_perdido_padrao() -> EnemyDef:
	var e := EnemyDef.new()
	e.id = &"eco_perdido"
	e.chave_nome = &"ENEMY_ECO_NAME"
	e.comportamento = &"corpo_a_corpo"
	e.vida = 30.0
	e.velocidade = 153.0
	e.raio_px = 24.0
	e.dano = 9.0
	e.alcance_px = 51.0
	e.preparo_s = 26.0 / 60.0
	e.recarga_s = 50.0 / 60.0
	e.custo_onda = 1
	return e


# --- Implementação de ConsultaDeAlvoMaldicao (para injeção direta em Telegrafos) -

func dono_vivo(inimigo_id: int) -> bool:
	return vivo(inimigo_id)


func posicao_dono(inimigo_id: int) -> Vector2:
	var e: EstadoDeInimigoIA = _por_id.get(inimigo_id, null)
	return e.posicao if e != null else Vector2.ZERO


func posicao_alvo(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> Vector2:
	match faccao:
		TelegrafoTipos.FaccaoAlvo.ALIADO:
			if _maldicoes != null:
				var pr := _maldicoes.posicao_e_raio(alvo_id)
				return Vector2(pr.x, pr.y)
			return Vector2.ZERO
		TelegrafoTipos.FaccaoAlvo.ACUADA:
			if _acuada != null:
				var pa := _acuada.posicao_e_raio_acuada()
				return Vector2(pa.x, pa.y)
			return Vector2.ZERO
		_:
			return _jogadores_pos.get(alvo_id, Vector2.ZERO) as Vector2


func raio_alvo(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> float:
	match faccao:
		TelegrafoTipos.FaccaoAlvo.ALIADO:
			if _maldicoes != null:
				var pr: Vector3 = _maldicoes.posicao_e_raio(alvo_id)
				return pr.z if pr.z > 0.0 else 24.0
			return 24.0
		TelegrafoTipos.FaccaoAlvo.ACUADA:
			if _acuada != null:
				var pa: Vector3 = _acuada.posicao_e_raio_acuada()
				return pa.z if pa.z > 0.0 else 22.5
			return 22.5
		_:
			return float(_jogadores_raios.get(alvo_id, 27.0))


func alvo_atingivel(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> bool:
	match faccao:
		TelegrafoTipos.FaccaoAlvo.ALIADO:
			return _maldicoes != null and _maldicoes.maldicao_atingivel(alvo_id)
		TelegrafoTipos.FaccaoAlvo.ACUADA:
			return _acuada != null and _acuada.acuada_atingivel()
		_:
			return not _jogador_morto
