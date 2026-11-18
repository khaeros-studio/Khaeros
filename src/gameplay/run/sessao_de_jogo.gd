class_name SessaoDeJogo
extends RefCounted
## Fachada de sessão e dona dos quatro escopos de vida (Perfil > Sessão > Run > Câmara)
## (GDD run-e-regioes.md R1–R11-P; ADR-0015 §1, §2, §7; ADR-0013 §7).
##
## Responsabilidades:
## - Guarda os objetos de escopo de **Perfil** ([PerfilVinculo], [RepositorioDePerfil], [Save], [PreferenciasDeArma]);
## - Guarda os objetos de escopo de **Sessão** ([ContaFragmentos], [EventosDoPasso], [OrquestradorDoPasso]);
## - Recria o [EscopoDaRun] a cada run e o solta em [method nova_run] (sem `reset()` em módulos);
## - Coordena a gravação do perfil em [method gravar_se_pendente] (apenas fora de [code]JOGO[/code]/[code]INICIANDO[/code])
##   e na saída do jogo ([method sair_do_jogo]: se a run estiver ativa, encerra como abandono, consolida o
##   Vínculo V20b e grava sincronamente antes de fechar).

var perfil_vinculo: PerfilVinculo
var vinculo: Vinculo
var repositorio_perfil: RepositorioDePerfil
var save: Save
var preferencias_arma: PreferenciasDeArmaEmMemoria

var conta: ContaFragmentos
var eventos: EventosDoPasso
var orquestrador: Object
var run: Run
var escopo_run: EscopoDaRun = null

var _armazem: ArmazemDeArquivos
var _wave_rules: WaveRules
var _room_tuning: RoomTuning
var _reward_table: RewardTable
var _region_def: RegionDef
var _pool_inimigos: Array[EnemyDef] = []
var _chefe_def: EnemyDef = null
var _armas_por_id: Dictionary[StringName, WeaponDef] = {}
var _boon_defs: Array[BoonDef] = []


func _init(armazem: ArmazemDeArquivos = null, entropia: FonteDeEntropia = null,
		eh_debug: bool = true, argumentos: PackedStringArray = PackedStringArray(),
		avisar: Callable = Callable()) -> void:
	_armazem = armazem if armazem != null else ArmazemEmMemoria.new()
	eventos = EventosDoPasso.new()

	var rates := EconomyRates.new()
	rates.saldo_max = 999999
	rates.fragmentos_provacao = 3
	conta = ContaFragmentos.new(rates, eventos)

	perfil_vinculo = PerfilVinculo.new()
	vinculo = Vinculo.new(perfil_vinculo, null, eventos)

	repositorio_perfil = RepositorioDePerfil.new(
		_armazem, CaminhosDePersistencia.de(0), avisar,
		PackedStringArray(["vulto_mudo", "espreitador_da_fenda", "baluarte_de_cinza", "soberano_do_limiar"]),
		perfil_vinculo
	)
	save = Save.new()
	save.configurar(repositorio_perfil, avisar)
	save.carregar(true)
	vinculo.configurar_save(save)

	preferencias_arma = PreferenciasDeArmaEmMemoria.new()

	_wave_rules = _criar_wave_rules_padrao()
	_room_tuning = _criar_room_tuning_padrao()
	_reward_table = _criar_reward_table_padrao()
	_region_def = Run._regiao_limiar_padrao()
	_pool_inimigos = [_criar_eco_padrao()]
	_chefe_def = _criar_chefe_padrao()
	_armas_por_id = _criar_armas_padrao()

	var ent: FonteDeEntropia = entropia if entropia != null else _EntropiaSequencial.new()
	var criador := CriadorDeSeed.new(ent, eh_debug, argumentos, RelatorDeErrosRng.new())

	run = Run.new(null, _region_def, null, criador, conta, eventos, preferencias_arma)
	run.configurar_vinculo(vinculo)
	run.configurar_callbacks(Callable(self, "_montar_novo_escopo_da_run"))


class _EntropiaSequencial:
	extends FonteDeEntropia
	var _atual: int = 0x3F9A07C2

	func sortear_u32() -> int:
		var v: int = _atual
		_atual = RngAritmetica.proximo_estado(_atual)
		return v


func configurar_orquestrador(orq: Object) -> void:
	orquestrador = orq
	run.configurar_orquestrador(orq)
	vinculo.configurar_orquestrador(orq)


func iniciar_escolha() -> bool:
	return run.iniciar_escolha_de_arma()


func confirmar_arma(id_arma: StringName = &"", texto_seed_debug: String = "") -> bool:
	var ok: bool = run.confirmar_arma(id_arma, texto_seed_debug)
	_entregar_eventos_ao_save()
	return ok


func confirmar_dupla(campo: StringName, reserva: StringName = &"", texto_seed_debug: String = "") -> bool:
	var ok: bool = run.confirmar_dupla(campo, reserva, texto_seed_debug)
	_entregar_eventos_ao_save()
	return ok


func abandonar(confirmado: bool = true, veio_de_bencao: bool = false) -> bool:
	var ok: bool = run.abandonar(confirmado, veio_de_bencao)
	_entregar_eventos_ao_save()
	return ok


## Recria a sessão para uma nova run: desliga e solta o [member escopo_run] antigo (ADR-0015 §2).
func nova_run() -> bool:
	if escopo_run != null:
		escopo_run.desligar()
		escopo_run = null
	return run.nova_run()


## Chamado pelo `Main` no fim de cada passo físico: entrega os eventos do passo ao [Save] e grava se pendente
## e fora de `JOGO`/`INICIANDO` (ADR-0015 §7, ADR-0013 §7).
func gravar_se_pendente(estado_de_jogo: EstadoDeJogo.Valor) -> Error:
	_entregar_eventos_ao_save()
	return save.gravar_se_pendente(estado_de_jogo)


## Saída do jogo pelo menu ou `NOTIFICATION_WM_CLOSE_REQUEST` (ADR-0015 §7, Save R10, V20b):
## Se a run estiver ativa, encerra como abandono (emitindo `EvRunEncerrada` e consolidando o Vínculo V20b)
## e grava o perfil sincronamente na hora.
func sair_do_jogo() -> Error:
	if run.ativa():
		run.encerrar_por_saida()
	_entregar_eventos_ao_save()
	var err: Error = save.pedir_saida(Callable(vinculo, "consolidar_abandono"))
	if escopo_run != null:
		escopo_run.desligar()
		escopo_run = null
	return err


func _montar_novo_escopo_da_run(id_arma: StringName, dupla_ids: Array[StringName], seed_da_run: int) -> void:
	if escopo_run != null:
		escopo_run.desligar()
		escopo_run = null
	var arma_def: WeaponDef = _armas_por_id.get(id_arma, _armas_por_id.get(&"lamina", null))
	escopo_run = FabricaDaRun.montar(
		arma_def, dupla_ids, seed_da_run,
		_wave_rules, _room_tuning, _reward_table, _region_def,
		conta, vinculo, eventos, orquestrador,
		_pool_inimigos, _chefe_def, _boon_defs
	)
	escopo_run.portas.configurar_run(run)
	escopo_run.camaras.configurar_portas_e_run(
		Callable(run, "ao_camara_limpa"),
		Callable(escopo_run.portas, "ao_porta_escolhida")
	)
	escopo_run.camaras.configurar_pactos(
		Callable(vinculo, "encontro_na_camara"),
		Callable(vinculo, "ao_montar_camara"),
		Callable(vinculo, "acuada_atingivel")
	)
	run.configurar_camaras(escopo_run.camaras)
	run.configurar_portas(escopo_run.portas, _reward_table.primeira_recompensa)
	run.configurar_bencaos(escopo_run.bencaos)
	vinculo.configurar_portas(escopo_run.portas)


func _entregar_eventos_ao_save() -> void:
	if save != null and eventos != null:
		save.consumir(eventos.todos())


static func _criar_wave_rules_padrao() -> WaveRules:
	var w := WaveRules.new()
	w.id = &"wave_rules"
	w.orcamento_base = 3.0
	w.orcamento_por_prof = 0.9
	w.orcamento_por_regiao = 2.0
	w.ondas_limites = PackedInt64Array([2, 6])
	w.max_inimigos_onda = 9
	return w


static func _criar_room_tuning_padrao() -> RoomTuning:
	var r := RoomTuning.new()
	r.id = &"room_tuning"
	r.camara_largura_px = 1920.0
	r.camara_altura_px = 1080.0
	r.obstaculos_min = 2
	r.obstaculos_var = 3
	r.obstaculo_raio_min_px = 42.0
	r.obstaculo_passos = 26
	r.folga_obstaculo_px = 105.0
	r.obstaculo_tentativas = 10
	r.spawn_candidatos = 14
	r.spawn_dist_jogador_px = 390.0
	r.spawn_margem_px = 111.0
	r.spawn_folga_pedra_px = 12.0
	r.portas_espaco_px = 450.0
	r.portas_y_px = 177.0
	r.porta_raio_px = 69.0
	r.entrada_px = PackedFloat64Array([960.0, 930.0])
	r.interagir_folga_px = 15.0
	r.santuario_cura = 0.40
	r.spawn_dist_acuada_px = 240.0
	return r


static func _criar_reward_table_padrao() -> RewardTable:
	var rt := RewardTable.new()
	rt.id = &"reward_table"
	rt.pesos_portas = {&"bencao": 3.0, &"fragmentos": 2.0, &"cura": 1.0, &"provacao": 0.0}
	rt.chance_tres_portas = 0.30
	rt.primeira_recompensa = &"bencao"
	rt.cura_porta = 0.30
	rt.fragmentos_porta_base = 2
	rt.fragmentos_porta_passo = 3
	return rt


static func _criar_eco_padrao() -> EnemyDef:
	var e := EnemyDef.new()
	e.id = &"eco_perdido"
	e.comportamento = &"corpo_a_corpo"
	e.vida = 30.0
	e.velocidade = 153.0
	e.raio_px = 24.0
	e.dano = 9.0
	e.custo_onda = 1
	return e


static func _criar_chefe_padrao() -> EnemyDef:
	var e := EnemyDef.new()
	e.id = &"soberano_do_limiar"
	e.comportamento = &"chefe"
	e.vida = 700.0
	e.velocidade = 162.0
	e.raio_px = 45.0
	e.dano = 16.0
	e.custo_onda = 9
	return e


static func _criar_armas_padrao() -> Dictionary[StringName, WeaponDef]:
	var d: Dictionary[StringName, WeaponDef] = {}
	for info: Array in [[&"lamina", 100, 387.0], [&"ressonancia", 80, 378.0], [&"pactos", 90, 382.5]]:
		var w := WeaponDef.new()
		w.id = info[0]
		w.doutrina = info[0]
		w.vida_max = info[1]
		w.velocidade = info[2]
		d[w.id] = w
	return d
