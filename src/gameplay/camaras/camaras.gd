class_name Camaras
extends Passo
## Módulo de Câmaras e ondas: dono de [code]p[/code] e [code]p_max[/code], da consulta
## [method em_combate], da montagem na Transição (R4/R4-P), do item 10 do passo vivo
## (próxima onda e [code]camara_limpa[/code], R9/R11), do Santuário (R12), das portas físicas
## (R13/R13-P) e da câmara do chefe com fase [code]Subjugado[/code] (R8-P, R14-P, R18-P).
##
## Governado por ADR-0001, ADR-0005, ADR-0008, ADR-0010, ADR-0015 e ADR-0018.
## Sem SceneTree, sem Autoload, sem física da engine.

enum Fase { ENTRADA, COMBATE, SUBJUGADO, LIMPA, SAIDA }

const POSICAO_CHEFE_PADRAO: Vector2 = Vector2(960.0, 285.0)
const FASE_INIMIGO_SURGINDO: StringName = &"SURGINDO"
const ERRO_LIMPAR_CHEFE_FORA_DE_SUBJUGADO: String = "Camaras: limpar_camara_chefe() chamado fora da fase SUBJUGADO"


## Ação 3 das seis ações da troca de câmara na metade do wipe (ADR-0001).
class AcaoTrocaDeCamara:
	extends AcaoDeTroca
	var _camaras: Camaras

	func _init(camaras: Camaras) -> void:
		_camaras = camaras

	func executar() -> void:
		_camaras.executar_montagem_na_transicao()


var _wave_rules: WaveRules
var _room_tuning: RoomTuning
var _elite_rules: EliteRules
var _region_def: RegionDef
var _pool: Array[EnemyDef] = []
var _chefe_def: EnemyDef = null
var _fluxos: FluxosDeCamaras
var _fluxos_ia: FluxosDeIa
var _eventos: EventosDoPasso
var _gerador_ids: GeradorDeIds

# Colaboradores injetados (podem ser Callables ou objetos com métodos)
var _orquestrador: Object = null
var _portador_jogador: Portador = null
var _vida_jogador_getter: Callable = Callable()
var _vida_jogador_setter: Callable = Callable()
var _pos_jogador_getter: Callable = Callable()
var _pos_jogador_setter: Callable = Callable()
var _hitstop_ativo_getter: Callable = Callable()
var _jogador_morreu_getter: Callable = Callable()
var _remover_projeteis_inimigos: Callable = Callable()
var _cancelar_telegrafos: Callable = Callable()
var _sorteador_elite_custom: Callable = Callable()
var _ao_nascer_inimigo: Callable = Callable()

# Integração Pactos / Maldições / Chefes / Portas / Run
var _encontro_na_camara_cb: Callable = Callable()
var _nascer_acuada_cb: Callable = Callable()
var _acuada_ativa_cb: Callable = Callable()
var _reposicionar_maldicao_cb: Callable = Callable()
var _maldicao_em_campo_raio_cb: Callable = Callable()
var _distancia_seguir_px: float = 105.0
var _ao_camara_limpa_cb: Callable = Callable()
var _ao_porta_escolhida_cb: Callable = Callable()

var _fase: Fase = Fase.ENTRADA
var _conteudo: ConteudoDaCamara = null
var _indice_pendente: int = 0
var _regiao_idx_pendente: int = 0
var _recompensa_pendente: StringName = &""
var _erros_integracao: Array[String] = []


func _init(wave_rules: WaveRules, room_tuning: RoomTuning, region_def: RegionDef,
		fluxos: FluxosDeCamaras = null, eventos: EventosDoPasso = null,
		pool_inimigos: Array[EnemyDef] = [], chefe_def: EnemyDef = null,
		elite_rules: EliteRules = null, fluxos_ia: FluxosDeIa = null,
		gerador_ids: GeradorDeIds = null) -> void:
	_wave_rules = wave_rules if wave_rules != null else WaveRules.new()
	_room_tuning = room_tuning if room_tuning != null else RoomTuning.new()
	_region_def = region_def if region_def != null else RegionDef.new()
	_fluxos = fluxos
	_eventos = eventos if eventos != null else EventosDoPasso.new()
	_pool = pool_inimigos.duplicate()
	_chefe_def = chefe_def
	_elite_rules = elite_rules
	_fluxos_ia = fluxos_ia
	_gerador_ids = gerador_ids if gerador_ids != null else GeradorDeIds.new()


# --- Configuração de colaboradores (injeção) ---------------------------------

func configurar_orquestrador(orquestrador: Object) -> void:
	_orquestrador = orquestrador


func configurar_jogador(portador: Portador, pos_getter: Callable, pos_setter: Callable,
		vida_getter: Callable = Callable(), vida_setter: Callable = Callable()) -> void:
	_portador_jogador = portador
	_pos_jogador_getter = pos_getter
	_pos_jogador_setter = pos_setter
	_vida_jogador_getter = vida_getter
	_vida_jogador_setter = vida_setter


func configurar_combate(hitstop_getter: Callable, jogador_morreu_getter: Callable,
		remover_projeteis_cb: Callable = Callable(), cancelar_telegrafos_cb: Callable = Callable()) -> void:
	_hitstop_ativo_getter = hitstop_getter
	_jogador_morreu_getter = jogador_morreu_getter
	_remover_projeteis_inimigos = remover_projeteis_cb
	_cancelar_telegrafos = cancelar_telegrafos_cb


func configurar_ia(sorteador_elite_cb: Callable, ao_nascer_cb: Callable = Callable()) -> void:
	_sorteador_elite_custom = sorteador_elite_cb
	_ao_nascer_inimigo = ao_nascer_cb


func configurar_pactos(encontro_na_camara_cb: Callable, nascer_acuada_cb: Callable,
		acuada_ativa_cb: Callable = Callable(), reposicionar_maldicao_cb: Callable = Callable(),
		maldicao_raio_cb: Callable = Callable(), distancia_seguir_px: float = 105.0) -> void:
	_encontro_na_camara_cb = encontro_na_camara_cb
	_nascer_acuada_cb = nascer_acuada_cb
	_acuada_ativa_cb = acuada_ativa_cb
	_reposicionar_maldicao_cb = reposicionar_maldicao_cb
	_maldicao_em_campo_raio_cb = maldicao_raio_cb
	_distancia_seguir_px = distancia_seguir_px


func configurar_portas_e_run(ao_camara_limpa_cb: Callable, ao_porta_escolhida_cb: Callable = Callable()) -> void:
	_ao_camara_limpa_cb = ao_camara_limpa_cb
	_ao_porta_escolhida_cb = ao_porta_escolhida_cb


## Ação de troca para registrar no [OrquestradorDoPasso].
func criar_acao_de_troca() -> AcaoDeTroca:
	return AcaoTrocaDeCamara.new(self)


# --- Consultas de profundidade e estado (R3, R8, R10, R10-P) ------------------

## Dono único de [code]p_max[/code] (R3, AC-CO-01, AC-CO-28).
func p_max(camaras_jogaveis: int = -1) -> int:
	return ProfundidadeCamara.calcular_p_max(_region_def.camaras, camaras_jogaveis)


## Profundidade [code]p[/code] da câmara em [param indice] (R3, R3-P).
func profundidade_para_indice(indice: int) -> int:
	return ProfundidadeCamara.profundidade_no_indice(_region_def.camaras, indice)


## Profundidade [code]p[/code] da câmara atual (0 antes da 1ª montagem).
func profundidade_atual() -> int:
	return _conteudo.profundidade if _conteudo != null else 0


## Índice da câmara atual na região.
func indice_atual() -> int:
	return _conteudo.indice if _conteudo != null else 0


## Tipo da câmara atual ([code]combate[/code], [code]santuario[/code] ou [code]chefe[/code]).
func tipo_atual() -> StringName:
	return _conteudo.tipo if _conteudo != null else ProfundidadeCamara.TIPO_COMBATE


## Fase atual da câmara.
func fase() -> Fase:
	return _fase


## Consulta "em combate" (R10, R10-P, AC-CO-15, AC-CO-31):
## Verdadeira só na fase COMBATE; falsa em ENTRADA, SUBJUGADO, LIMPA, SAIDA e no santuário.
func em_combate() -> bool:
	return _fase == Fase.COMBATE and tipo_atual() != ProfundidadeCamara.TIPO_SANTUARIO


## Conteúdo da câmara atual (escopo de câmara).
func conteudo() -> ConteudoDaCamara:
	return _conteudo


## Retângulo jogável da câmara (R2).
func retangulo_jogavel() -> Rect2:
	return LayoutDaCamara.retangulo_jogavel(_room_tuning)


## Obstáculos circulares da câmara atual (somente leitura).
func obstaculos() -> Array[ObstaculoCircular]:
	if _conteudo == null:
		return []
	return _conteudo.obstaculos.duplicate()


## Lista de inimigos vivos na câmara atual (não inclui Maldição nem acuada — R9-P).
func inimigos_vivos() -> Array[InimigoRef]:
	if _conteudo == null:
		return []
	return _conteudo.inimigos_vivos


## Erros de integração registrados (ex.: AC-CO-33).
func erros_integracao() -> Array[String]:
	return _erros_integracao.duplicate()


# --- Montagem da câmara (R4, R4-P, R12, R14-P) -------------------------------

## Prepara a troca para a câmara [param indice] (e monta imediatamente se [param montar_ja] for true).
func trocar(indice: int, recompensa_pendente: StringName = &"", regiao_idx: int = 0,
		montar_ja: bool = true) -> void:
	_indice_pendente = indice
	_regiao_idx_pendente = regiao_idx
	_recompensa_pendente = recompensa_pendente
	_fase = Fase.ENTRADA
	if montar_ja:
		executar_montagem_na_transicao()


## Executa a montagem completa no quadro da metade do wipe (R4, R4-P):
## 0. Cancela telégrafos anteriores;
## 1. Teleporta o jogador para [code]entrada_px[/code] (960, 930);
## 1b. Reposiciona a Maldição em campo atrás do jogador (F6);
## 2. Gera o layout de pedras (R5 ou fixo) e compõe as ondas (R6);
## 2b. Consulta [code]encontro_na_camara(indice)[/code] e posiciona a acuada sem consumir RNG;
## 3. Entra na fase COMBATE (ou LIMPA no santuário) e faz nascer a 1ª onda no mesmo quadro.
func executar_montagem_na_transicao() -> void:
	if _cancelar_telegrafos.is_valid():
		_cancelar_telegrafos.call()
	var idx: int = _indice_pendente
	var r_idx: int = _regiao_idx_pendente
	var tipo_sala: StringName = ProfundidadeCamara.TIPO_COMBATE
	if idx >= 0 and idx < _region_def.camaras.size():
		tipo_sala = _region_def.camaras[idx]
	var p: int = ProfundidadeCamara.profundidade_no_indice(_region_def.camaras, idx)

	_conteudo = ConteudoDaCamara.new(idx, r_idx, tipo_sala, p, _recompensa_pendente, _room_tuning)

	# 1. Jogador na entrada (960; 930)
	var pos_entrada: Vector2 = LayoutDaCamara.ponto_de_entrada(_room_tuning)
	if _pos_jogador_setter.is_valid():
		_pos_jogador_setter.call(pos_entrada)

	# 1b. Maldição em campo atrás do jogador (R4-P 1b, F6, AC-CO-35)
	if _maldicao_em_campo_raio_cb.is_valid() and _reposicionar_maldicao_cb.is_valid():
		var raio_mald: float = float(_maldicao_em_campo_raio_cb.call())
		if raio_mald > 0.0:
			var pos_mald: Vector2 = LayoutDaCamara.ponto_entrada_maldicao(_room_tuning, _distancia_seguir_px, raio_mald)
			_reposicionar_maldicao_cb.call(pos_mald)

	# Atualiza a fonte de modificador `profundidade` se houver portador
	if _portador_jogador != null:
		pass # O portador do jogador não ganha Vida por p; os inimigos ganham na criação.

	# Caso Santuário (R12, AC-CO-17): sem ondas, sem RNG, cura 40% da Vida máxima e vai direto a LIMPA.
	if tipo_sala == ProfundidadeCamara.TIPO_SANTUARIO:
		_conteudo.obstaculos = LayoutDaCamara.obstaculos_santuario()
		_conteudo.geometria = LayoutDaCamara.construir_geometria(_room_tuning, _conteudo.obstaculos)
		_aplicar_cura_santuario()
		_fase = Fase.LIMPA
		_emitir_camara_limpa()
		return

	# Caso Chefe (R14-P, AC-CO-29): layout fixo de 4 pedras, 1 onda só com o chefe em (960, 285), 0 reais de RNG.
	if tipo_sala == ProfundidadeCamara.TIPO_CHEFE:
		_conteudo.obstaculos = LayoutDaCamara.obstaculos_chefe()
		_conteudo.geometria = LayoutDaCamara.construir_geometria(_room_tuning, _conteudo.obstaculos)
		_conteudo.onda_atual = 0
		_fase = Fase.COMBATE
		_nascer_chefe()
		return

	# Caso Combate normal (R5, R6, R4-P 2b, R7): chave é (regiao_idx, idx), nunca p!
	var f_layout: FluxoRng = _fluxos.layout(r_idx, idx) if _fluxos != null else null
	var f_ondas: FluxoRng = _fluxos.ondas(r_idx, idx) if _fluxos != null else null
	_conteudo.obstaculos = LayoutDaCamara.sortear_obstaculos_combate(_room_tuning, f_layout)
	_conteudo.geometria = LayoutDaCamara.construir_geometria(_room_tuning, _conteudo.obstaculos)
	_conteudo.ondas_compostas = ComposicaoDeOndas.compor_ondas(_wave_rules, _pool, p, r_idx, f_ondas)

	# 2b. Encontro de pacto (R4-P 2b, AC-CO-36): consultado depois de layout e ondas e antes da 1ª onda.
	if _encontro_na_camara_cb.is_valid():
		var esp: StringName = _encontro_na_camara_cb.call(idx)
		if esp != &"":
			_conteudo.especie_encontro = esp
			_conteudo.acuada_presente = true
			if _nascer_acuada_cb.is_valid():
				_conteudo.pos_acuada = _nascer_acuada_cb.call(idx, esp, _conteudo.obstaculos)

	# 3. Fase Combate e nascimento da 1ª onda no mesmo quadro
	_fase = Fase.COMBATE
	if not _conteudo.ondas_compostas.is_empty():
		_nascer_onda(0)


# --- Item 10 do passo vivo: ciclo de ondas, limpeza e portas (R9, R11, R13) ---

func passo(amostra: AmostraDeEntrada) -> void:
	if _conteudo == null:
		return
	# Se em LIMPA e portas abertas, verifica interação com porta (R13, AC-CO-19, AC-CO-20)
	if _fase == Fase.LIMPA:
		if amostra != null and _quer_interagir(amostra):
			interagir_com_porta()
		return

	if _fase != Fase.COMBATE:
		return

	# Item 10 só avalia com hitstop 0 (R9, AC-CO-13)
	if _hitstop_ativo():
		return

	# Morte vence a limpeza (Edge Case / AC-CO-16)
	if _jogador_morreu():
		return

	# Sincroniza estado da acuada caso tenha fugido no meio da câmara
	if _conteudo.acuada_presente and _acuada_ativa_cb.is_valid():
		_conteudo.acuada_presente = bool(_acuada_ativa_cb.call())

	# Filtra inimigos ainda vivos (vida > 0)
	_remover_inimigos_mortos()
	if not _conteudo.inimigos_vivos.is_empty():
		return

	# Sem inimigos vivos: nasce próxima onda no mesmo passo ou limpa a câmara (R9, AC-CO-12, AC-CO-14)
	var prox_onda: int = _conteudo.onda_atual + 1
	if prox_onda < _conteudo.ondas_compostas.size():
		_nascer_onda(prox_onda)
	else:
		_concluir_limpeza_camara()


## Marca a câmara do chefe como [code]SUBJUGADO[/code] (R8-P, R10-P, AC-CO-31).
## Em [code]SUBJUGADO[/code], [method em_combate] é falso e a avaliação da R9 fica suspensa.
func chefe_subjugado(_chefe_id: StringName = &"soberano_do_limiar") -> void:
	if _conteudo == null or _conteudo.tipo != ProfundidadeCamara.TIPO_CHEFE:
		return
	if _jogador_morreu():
		return
	_fase = Fase.SUBJUGADO


## Chamado pelos Chefes após [code]resolver_subjugado(id, escolha)[/code] (R18-P, AC-CO-32, AC-CO-33).
## Emite [code]camara_limpa(4, chefe)[/code] exatamente uma vez. Fora de [code]SUBJUGADO[/code],
## ignora e registra erro de integração.
func limpar_camara_chefe() -> bool:
	if _conteudo == null or _conteudo.tipo != ProfundidadeCamara.TIPO_CHEFE:
		_erros_integracao.append(ERRO_LIMPAR_CHEFE_FORA_DE_SUBJUGADO)
		return false
	if _fase == Fase.LIMPA and _conteudo.limpa_emitida:
		return false
	if _fase != Fase.SUBJUGADO:
		_erros_integracao.append(ERRO_LIMPAR_CHEFE_FORA_DE_SUBJUGADO)
		return false
	if _jogador_morreu():
		return false
	_concluir_limpeza_camara()
	return true


## Adiciona um lacaio invocado pelo chefe na lista de inimigos da câmara, respeitando o teto
## [code]max_inimigos_onda[/code] (9) para chefe + lacaios (R14-P, TR-camaras-014).
func adicionar_lacaio_do_chefe(def: EnemyDef, posicao: Vector2) -> InimigoRef:
	if _conteudo == null:
		return null
	_remover_inimigos_mortos()
	if _conteudo.inimigos_vivos.size() >= _wave_rules.max_inimigos_onda:
		return null
	var ref := InimigoRef.new(_gerador_ids.proximo(), def, false, false)
	ref.fase = FASE_INIMIGO_SURGINDO
	ref.posicao = posicao
	ref.vida = def.vida if def != null else 30.0
	_conteudo.inimigos_vivos.append(ref)
	return ref


## Abre as portas físicas na câmara limpa (chamado pelas Portas e recompensas — R11, R13).
func abrir_portas(tipos: Array[StringName], quantidades: Array[int] = []) -> void:
	if _conteudo == null:
		return
	_conteudo.portas.abrir(tipos, quantidades)


## Tenta interagir com uma porta aberta na posição atual do jogador (R13, AC-CO-19, AC-CO-20).
## Ignora em hitstop, fora de LIMPA ou em Transição.
func interagir_com_porta(pos_override: Variant = null) -> int:
	if _conteudo == null or _fase != Fase.LIMPA:
		return -1
	if _hitstop_ativo():
		return -1
	if _orquestrador != null and _orquestrador.has_method("estado"):
		if _orquestrador.call("estado") != EstadoDeJogo.Valor.JOGO:
			return -1
	var pos_jog: Vector2 = pos_override if pos_override is Vector2 else _obter_pos_jogador()
	var k: int = _conteudo.portas.tentar_interagir(pos_jog, true)
	if k < 0:
		return -1
	var lista: Array[PortasFisicas.PortaFisica] = _conteudo.portas.listar()
	var tipo_p: StringName = lista[k].tipo if k < lista.size() else &""
	_fase = Fase.SAIDA
	_eventos.emitir(EventosDeCamaras.EvPortaInteragida.new(k, tipo_p))
	if _ao_porta_escolhida_cb.is_valid():
		_ao_porta_escolhida_cb.call(k)
	if _orquestrador != null and _orquestrador.has_method("pedir_estado"):
		_orquestrador.call("pedir_estado", EstadoDeJogo.Valor.TRANSICAO)
	return k


# --- Interno -----------------------------------------------------------------

func _nascer_onda(indice_onda: int) -> void:
	_conteudo.onda_atual = indice_onda
	var onda: Array = _conteudo.ondas_compostas[indice_onda]
	var entradas: Array[ComposicaoDeOndas.EntradaDeOnda] = []
	for item in onda:
		if item is ComposicaoDeOndas.EntradaDeOnda:
			entradas.append(item)
	var f_spawn: FluxoRng = _fluxos.spawn(_conteudo.regiao_idx, _conteudo.indice) if _fluxos != null else null
	var pos_jog: Vector2 = _obter_pos_jogador()
	var acuada_ativa: bool = _conteudo.acuada_presente
	if acuada_ativa and _acuada_ativa_cb.is_valid():
		acuada_ativa = bool(_acuada_ativa_cb.call())
	var sorteador: Callable = _obter_sorteador_elite(_conteudo.regiao_idx, _conteudo.indice)
	var mult_raio: float = _elite_rules.mult_raio if (_elite_rules != null and _elite_rules.mult_raio > 0.0) else SpawnCamara.MULT_RAIO_ELITE_PADRAO
	var nascidos: Array[SpawnCamara.NascimentoDeInimigo] = SpawnCamara.instanciar_onda(
		entradas, _conteudo.profundidade, _room_tuning, f_spawn, sorteador,
		pos_jog, _conteudo.obstaculos, acuada_ativa, _conteudo.pos_acuada, mult_raio
	)
	var escala_vida: float = 1.0 + ProfundidadeCamara.ESCALA_VIDA_POR_PROF * float(_conteudo.profundidade)
	var mult_vida_elite: float = _elite_rules.mult_vida if (_elite_rules != null and _elite_rules.mult_vida > 0.0) else 1.6
	for n: SpawnCamara.NascimentoDeInimigo in nascidos:
		var ref := InimigoRef.new(_gerador_ids.proximo(), n.definicao, false, n.elite)
		ref.fase = FASE_INIMIGO_SURGINDO
		ref.posicao = n.posicao
		var vida_base: float = n.definicao.vida if n.definicao != null else 30.0
		ref.vida = float(Unidades.arredondar_meio_longe_do_zero(vida_base * escala_vida * (mult_vida_elite if n.elite else 1.0)))
		ref.set_meta(&"ordem_onda", n.ordem)
		_conteudo.inimigos_vivos.append(ref)
		if _ao_nascer_inimigo.is_valid():
			_ao_nascer_inimigo.call(ref, n.ordem)
	_eventos.emitir(EventosDeCamaras.EvOndaIniciada.new(indice_onda, nascidos.size()))


func _nascer_chefe() -> void:
	var def: EnemyDef = _chefe_def
	if def == null:
		def = EnemyDef.new()
		def.id = &"soberano_do_limiar"
		def.comportamento = &"chefe"
		def.vida = 700.0
		def.raio_px = 45.0
	var ref := InimigoRef.new(_gerador_ids.proximo(), def, true, false)
	ref.fase = FASE_INIMIGO_SURGINDO
	ref.posicao = POSICAO_CHEFE_PADRAO
	ref.vida = def.vida
	ref.set_meta(&"ordem_onda", 0)
	_conteudo.inimigos_vivos.append(ref)
	if _ao_nascer_inimigo.is_valid():
		_ao_nascer_inimigo.call(ref, 0)
	_eventos.emitir(EventosDeCamaras.EvOndaIniciada.new(0, 1))


func _aplicar_cura_santuario() -> void:
	var vida_max: int = 100
	if _portador_jogador != null:
		vida_max = _portador_jogador.inteiro(Atributos.VIDA_MAX)
	var cura: int = Unidades.arredondar_meio_longe_do_zero(float(vida_max) * _room_tuning.santuario_cura)
	if _vida_jogador_getter.is_valid() and _vida_jogador_setter.is_valid():
		var atual: int = int(_vida_jogador_getter.call())
		var nova: int = mini(vida_max, atual + cura)
		_vida_jogador_setter.call(nova)


func _concluir_limpeza_camara() -> void:
	if _conteudo == null or _conteudo.limpa_emitida:
		return
	if _remover_projeteis_inimigos.is_valid():
		_remover_projeteis_inimigos.call()
	_fase = Fase.LIMPA
	_emitir_camara_limpa()


func _emitir_camara_limpa() -> void:
	if _conteudo == null or _conteudo.limpa_emitida:
		return
	_conteudo.limpa_emitida = true
	_eventos.emitir(EventosDeCamaras.EvCamaraLimpa.new(_conteudo.profundidade, _conteudo.tipo, _conteudo.indice))
	if _ao_camara_limpa_cb.is_valid():
		_ao_camara_limpa_cb.call(_conteudo.profundidade, _conteudo.tipo)


func _obter_sorteador_elite(regiao_idx: int, indice_camara: int) -> Callable:
	if _sorteador_elite_custom.is_valid():
		return _sorteador_elite_custom
	if _fluxos_ia == null:
		return func(_p: int, _ja: bool) -> bool: return false
	var f_elites: FluxoRng = _fluxos_ia.elites(regiao_idx, indice_camara)
	return func(p: int, ja_ha_elite: bool) -> bool:
		if f_elites == null:
			return false
		var u: float = f_elites.real_unitario()
		var p_min: int = _elite_rules.profundidade_minima if _elite_rules != null else 3
		if ja_ha_elite or p < p_min:
			return false
		var chance: float = 0.20 + 0.08 * float(p - p_min)
		if _elite_rules != null and _elite_rules.curva_chance != null:
			chance = _elite_rules.curva_chance.base + _elite_rules.curva_chance.slope * float(p - _elite_rules.curva_chance.x_min)
		return u < chance


func _remover_inimigos_mortos() -> void:
	if _conteudo == null:
		return
	var vivos: Array[InimigoRef] = []
	for ini: InimigoRef in _conteudo.inimigos_vivos:
		if ini != null and ini.vida > 0.0:
			vivos.append(ini)
	_conteudo.inimigos_vivos = vivos


func _obter_pos_jogador() -> Vector2:
	if _pos_jogador_getter.is_valid():
		return _pos_jogador_getter.call()
	return LayoutDaCamara.ponto_de_entrada(_room_tuning)


func _hitstop_ativo() -> bool:
	if _hitstop_ativo_getter.is_valid():
		return bool(_hitstop_ativo_getter.call())
	if _orquestrador != null and _orquestrador.has_method("hitstop_ativo"):
		return bool(_orquestrador.call("hitstop_ativo"))
	return false


func _jogador_morreu() -> bool:
	if _jogador_morreu_getter.is_valid():
		return bool(_jogador_morreu_getter.call())
	if _eventos != null and _eventos.ha(&"jogador_morreu"):
		return true
	return false


func _quer_interagir(amostra: AmostraDeEntrada) -> bool:
	if amostra.has_method("pressionou"):
		return bool(amostra.call("pressionou", Acoes.INTERAGIR))
	return false
