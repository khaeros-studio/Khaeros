class_name ApoioCombate
extends RefCounted
## Fixtures e dublês dos testes do Combate núcleo (GDD combate-nucleo, Acceptance Criteria: FP e FP-R).
## Não é suíte de teste.

const FabMod := preload("res://tests/unit/modifiers/fabrica_de_portadores.gd")
const PRAZO_BUFFER: int = 10
const POS_INICIAL_JOGADOR := Vector2(960.0, 540.0)
const RAIO_JOGADOR_FP: float = 27.0


## CombatTuning padrão (R15).
static func tuning_fp() -> CombatTuning:
	var t := CombatTuning.new()
	t.id = &"combat_tuning"
	t.hitstop_leve_s = 0.05
	t.hitstop_pesado_s = 0.1
	t.hitstop_abate_s = 0.0667
	t.hitstop_atingido_s = 0.1
	t.hitstop_abate_chefe_s = 0.6
	t.hitstop_recusa_s = 0.3
	t.empurrao_pesado = 900.0
	t.limiar_finalizador = 1.2
	t.janela_combo_s = 0.5667
	t.recuperacao_max_s = 0.2
	t.fator_recuperacao_golpe = 0.5
	t.passo_apoio_px = 10.5
	t.folga_encostado_px = 6.0
	t.nascimento_projetil_px = 36.0
	t.invuln_extra_investida_s = 0.0333
	t.cambaleio_s = 0.1333
	t.fator_cambaleio = 0.4
	t.quebrou_recuperacao_s = 0.4
	t.parede_vel_min = 630.0
	t.parede_dano = 8.0
	t.queda_empurrao = 0.78
	t.empurrao_zero = 4.5
	t.invuln_atingido_s = 0.6667
	t.passes_varredura = 4
	t.fator_guarda = 0.5
	t.giro_leque_graus = 12.0
	t.fator_raio_obstaculo_projetil = 0.5
	t.flash_acerto_s = 0.0833
	t.extra_inversao_s = 0.0667
	t.impact_chefe_s = 0.2
	return t


## Ataque da Lâmina (Corte: arco, 142,5 px, 69,51°, dano 14, R = 16, empurrão 450, combo [1, 1, 1.8]).
static func ataque_corte() -> AttackDef:
	var a := AttackDef.new()
	a.chave_nome = &"ATK_CORTE"
	a.forma = AtaqueConvertido.FORMA_ARCO
	a.params = {&"alcance_px": 142.5, &"meio_angulo_graus": 69.51}
	a.dano = 14.0
	a.recarga_s = 16.0 / 60.0
	a.empurrao = 450.0
	a.multiplicadores_combo = PackedFloat64Array([1.0, 1.0, 1.8])
	return a


## Especial da Lâmina (Investida: avanco, 330 px em N = 10, raio 69, dano 26, R = 70, empurrão 1080).
static func especial_investida() -> AttackDef:
	var a := AttackDef.new()
	a.chave_nome = &"ESP_INVESTIDA"
	a.forma = AtaqueConvertido.FORMA_AVANCO
	a.params = {&"distancia_px": 330.0, &"duracao_s": 10.0 / 60.0, &"raio_px": 69.0}
	a.dano = 26.0
	a.recarga_s = 70.0 / 60.0
	a.empurrao = 1080.0
	return a


## Ataque da Ressonância na FP-R (Pulso: projetil, 990 px/s, raio 15, L = 50, leque [0], dano 12, R = 14, empurrão 270).
static func ataque_pulso() -> AttackDef:
	var a := AttackDef.new()
	a.chave_nome = &"ATK_PULSO"
	a.forma = AtaqueConvertido.FORMA_PROJETIL
	a.params = {&"velocidade_pxs": 990.0, &"raio_px": 15.0, &"vida_s": 50.0 / 60.0}
	a.leque = PackedFloat64Array([0.0])
	a.atravessa = false
	a.dano = 12.0
	a.recarga_s = 14.0 / 60.0
	a.empurrao = 270.0
	return a


## Especial da Ressonância na FP-R (Onda: circulo, raio 195, deslocamento 0, dano 30, R = 90, empurrão 1260).
static func especial_onda() -> AttackDef:
	var a := AttackDef.new()
	a.chave_nome = &"ESP_ONDA"
	a.forma = AtaqueConvertido.FORMA_CIRCULO
	a.params = {&"raio_px": 195.0, &"deslocamento_px": 0.0}
	a.dano = 30.0
	a.recarga_s = 90.0 / 60.0
	a.empurrao = 1260.0
	return a


## Especial da Besta de Pactos (Chamado: chamado, dano 17, recarga 2,0 s = 120 passos).
static func especial_chamado() -> AttackDef:
	var a := AttackDef.new()
	a.chave_nome = &"ESP_CHAMADO"
	a.forma = AtaqueConvertido.FORMA_CHAMADO
	a.dano = 17.0
	a.recarga_s = 2.0
	a.empurrao = 0.0
	return a


## Portador real de jogador (Vida 100 por padrão).
static func portador_jogador(vida_max: float = 100.0) -> Portador:
	return FabMod.jogador(vida_max, {Atributos.VELOCIDADE: 387.0, Atributos.CARGAS_ESQUIVA: 1.0, Atributos.RAIO: RAIO_JOGADOR_FP})


## Portador real de inimigo com fator_empurrao dado.
static func portador_inimigo(vida_max: float, raio: float, fator_emp: float) -> Portador:
	var bases: Dictionary[StringName, float] = {
		Atributos.VIDA_MAX: vida_max,
		Atributos.RAIO: raio,
		Atributos.FATOR_EMPURRAO: fator_emp,
	}
	return Portador.new(10, -1, Atributos.Especie.INIMIGO, bases, FabMod.tuning())


static func criar_eco(id: int, pos: Vector2, vida: float = 30.0) -> ContratosDoCombate.InimigoCombate:
	var p := portador_inimigo(30.0, 24.0, 1.0)
	var ini := ContratosDoCombate.InimigoCombate.new(id, pos, 24.0, vida, p, false, false)
	ini.vida_max = 30.0
	return ini


static func criar_saco(id: int, pos: Vector2, movel: bool = false, vida: float = 1000.0) -> ContratosDoCombate.InimigoCombate:
	var p := portador_inimigo(vida, 24.0, 1.0 if movel else 0.0)
	return ContratosDoCombate.InimigoCombate.new(id, pos, 24.0, vida, p, false, false)


static func criar_elite(id: int, pos: Vector2, vida: float = 1000.0) -> ContratosDoCombate.InimigoCombate:
	var raio := 24.0 * 1.2
	var p := portador_inimigo(vida, raio, 0.4)
	return ContratosDoCombate.InimigoCombate.new(id, pos, raio, vida, p, true, false)


static func criar_chefe(id: int, pos: Vector2, vida: float = 700.0) -> ContratosDoCombate.InimigoCombate:
	var p := portador_inimigo(vida, 63.0, 0.12)
	return ContratosDoCombate.InimigoCombate.new(id, pos, 63.0, vida, p, false, true)


## Dublê do Movimento para os testes unitários do Combate.
class MovimentoDuble extends MovimentoParaCombate:
	var pos: Vector2 = POS_INICIAL_JOGADOR
	var esquiva: bool = false
	var raio_px: float = RAIO_JOGADOR_FP
	var executa_deslocar: bool = true
	var executa_investida: bool = true
	var usa_colisao: bool = false
	var geometria: GeometriaDeMovimento = GeometriaDeMovimento.new(Rect2(0.0, 0.0, 1920.0, 1080.0))
	var deslocamentos_apoio: Array[Vector2] = []
	var passos_investida_aplicados: Array[int] = []
	var leituras_recuperacao: Array[bool] = []

	func posicao(_player_id: int) -> Vector2:
		return pos

	func em_esquiva(_player_id: int) -> bool:
		return esquiva

	func raio(_player_id: int) -> float:
		return raio_px

	func deslocar(_player_id: int, v: Vector2) -> void:
		deslocamentos_apoio.append(v)
		if executa_deslocar:
			pos += v
			if usa_colisao:
				pos = Colisao.resolver_colisao(pos, raio_px, geometria)

	func passo_no_item_4(combate: Combate, n_passo: int) -> void:
		leituras_recuperacao.append(combate.em_recuperacao(0))
		if not esquiva and combate.investida_ativa(0) and executa_investida:
			pos += combate.deslocamento_investida(0)
			if usa_colisao:
				pos = Colisao.resolver_colisao(pos, raio_px, geometria)
			passos_investida_aplicados.append(n_passo)


## Dublê de IA para os testes do Combate.
class IADuble extends ContratosDoCombate.IAParaCombate:
	var lista: Array[ContratosDoCombate.InimigoCombate] = []
	## [alvo_id, passos] de cada pedir_recuperacao ("Quebrou!").
	var quebras: Array[Array] = []
	## [passo, id, cambaleando] registrados no turno de cada inimigo vivo.
	var turnos: Array[Array] = []
	var subjugados: Array[int] = []
	var notificacoes_chefe: Array[int] = []
	## Callable opcional: func(passo: int, ini: InimigoCombate, combate: Combate) -> void
	var acao_no_turno: Callable = Callable()

	func inimigos() -> Array[ContratosDoCombate.InimigoCombate]:
		return lista

	func pedir_recuperacao(id: int, passos: int) -> void:
		quebras.append([id, passos])

	func remover_morto(id: int) -> void:
		for idx in lista.size():
			if lista[idx].id == id:
				lista.remove_at(idx)
				return

	func subjugar(id: int) -> void:
		subjugados.append(id)

	func notificar_dano_no_chefe(id: int) -> void:
		notificacoes_chefe.append(id)


## Dublê de Câmaras.
class CamarasDuble extends ContratosDoCombate.CamarasParaCombate:
	var combate_ativo: bool = true
	var geo: GeometriaDeMovimento = GeometriaDeMovimento.new(Rect2(0.0, 0.0, 1920.0, 1080.0))
	var avaliacoes_camara_limpa: Array[int] = []

	func em_combate() -> bool:
		return combate_ativo

	func geometria() -> GeometriaDeMovimento:
		return geo


## Dublê do Selo.
class SeloDuble extends ContratosDoCombate.SeloParaCombate:
	var investidas_lidas: Array[bool] = []
	var acertos_tardios: Array[Array] = []
	var acao_no_item_6: Callable = Callable()

	func receber_investida(_player_id: int, ativa: bool) -> void:
		investidas_lidas.append(ativa)

	func creditar_acerto_tardio(player_id: int, alvo_id: int, enesimo: bool, pesado: bool) -> void:
		acertos_tardios.append([player_id, alvo_id, enesimo, pesado])


## Dublê do Status.
class StatusDuble extends ContratosDoCombate.StatusParaCombate:
	var aplicados: Array[Array] = []
	var limpezas: int = 0
	var acao_no_tick: Callable = Callable()

	func tick(_inimigo_id: int) -> void:
		pass

	func limpar_todos() -> void:
		limpezas += 1

	func aplicar_status(alvo_id: int, status_id: StringName, acumulos: float) -> void:
		aplicados.append([alvo_id, status_id, acumulos])


## Dublê de Maldições.
class MaldicoesDuble extends MaldicoesParaCombate:
	var disponivel: bool = false
	var motivo: StringName = &"sem_maldicao"
	var chamados: Array[Array] = []
	var em_campo: bool = true
	var saltando: bool = false
	var atingivel_flag: bool = true
	var pos: Vector2 = Vector2(600.0, 540.0)
	var raio: float = 24.0
	var vida: int = 110
	var portador: Portador = null
	var dono: int = 0
	var exauridas: Array[StringName] = []
	var acao_no_item_6_1: Callable = Callable()

	func chamado_disponivel(_player_id: int) -> bool:
		return disponivel and not saltando

	func motivo_indisponivel(_player_id: int) -> StringName:
		return &"saltando" if saltando else motivo

	func pedir_chamado(player_id: int, ponto: Vector2, dano_golpe: float, m_chamado: float) -> void:
		chamados.append([player_id, ponto, dano_golpe, m_chamado])

	func maldicao_atingivel(_curse_id: StringName) -> bool:
		return em_campo and vida > 0 and not saltando and atingivel_flag

	func maldicao_em_campo(_curse_id: StringName) -> bool:
		return em_campo

	func maldicao_saltando(_curse_id: StringName) -> bool:
		return saltando

	func posicao_maldicao(_curse_id: StringName) -> Vector2:
		return pos

	func raio_maldicao(_curse_id: StringName) -> float:
		return raio

	func vida_maldicao(_curse_id: StringName) -> int:
		return vida

	func definir_vida_maldicao(_curse_id: StringName, vida_nova: int) -> void:
		vida = vida_nova

	func portador_maldicao(_curse_id: StringName) -> Portador:
		return portador

	func dono_maldicao(_curse_id: StringName) -> int:
		return dono

	func exaurir(curse_id: StringName) -> void:
		exauridas.append(curse_id)
		atingivel_flag = false


## Dublê do Vínculo (acuada).
class VinculoDuble extends ContratosDoCombate.VinculoParaCombate:
	var atingivel: bool = false
	var pos: Vector2 = Vector2(960.0, 540.0)
	var raio: float = 22.5
	var vida: int = 114
	var estado: StringName = &"Acuada"
	var falhas: int = 0

	func acuada_atingivel() -> bool:
		return atingivel and estado == &"Acuada" and vida > 0

	func posicao_acuada() -> Vector2:
		return pos

	func raio_acuada() -> float:
		return raio

	func vida_acuada() -> int:
		return vida

	func definir_vida_acuada(nova_vida: int) -> void:
		vida = nova_vida

	func falhar_encontro() -> void:
		falhas += 1
		estado = &"Fugiu"
		atingivel = false


## Simulador de passos da R1 para os testes unitários do Combate.
class SimCombate extends RefCounted:
	var tuning: CombatTuning
	var portador: Portador
	var mov := MovimentoDuble.new()
	var ia := IADuble.new()
	var camaras := CamarasDuble.new()
	var selo := SeloDuble.new()
	var status := StatusDuble.new()
	var maldicoes := MaldicoesDuble.new()
	var vinculo := VinculoDuble.new()
	var eventos := EventosDoPasso.new()
	var buffer := BufferDeComandos.new(PRAZO_BUFFER)
	var combate: Combate
	var n: int = 0
	var passos_congelados: Array[int] = []
	var log_eventos: Array[Array] = []
	var estados_pedidos: Array[int] = []

	func _init(usar_ressonancia: bool = false, p_tuning: CombatTuning = null,
			p_portador: Portador = null, p_ataque: AttackDef = null,
			p_especial: AttackDef = null) -> void:
		tuning = p_tuning if p_tuning != null else ApoioCombate.tuning_fp()
		portador = p_portador if p_portador != null else ApoioCombate.portador_jogador(100.0)
		var atk := p_ataque if p_ataque != null else (ApoioCombate.ataque_pulso() if usar_ressonancia else ApoioCombate.ataque_corte())
		var esp := p_especial if p_especial != null else (ApoioCombate.especial_onda() if usar_ressonancia else ApoioCombate.especial_investida())
		var d := DependenciasDoCombate.new()
		d.tuning = tuning
		d.movimento = mov
		d.maldicoes = maldicoes
		d.ia = ia
		d.camaras = camaras
		d.selo = selo
		d.status = status
		d.vinculo = vinculo
		d.eventos = eventos
		d.pedir_estado = func(est: int) -> void: estados_pedidos.append(est)
		d.jogadores.append(DependenciasDoCombate.Jogador.new(portador, atk, esp))
		combate = Combate.criar(d)

	## Executa 1 passo do orquestrador de teste (R1 itens 1 a 10).
	func passo(toque_ataque: bool = false, toque_especial: bool = false,
			segurado_ataque: bool = false, segurado_especial: bool = false,
			antes_do_movimento: Callable = Callable()) -> void:
		var apertados: Array[StringName] = []
		if toque_ataque:
			apertados.append(Acoes.ATAQUE)
		if toque_especial:
			apertados.append(Acoes.ESPECIAL)
		var segurados: Array[StringName] = []
		if segurado_ataque:
			segurados.append(Acoes.ATAQUE)
		if segurado_especial:
			segurados.append(Acoes.ESPECIAL)

		# Item 1 & 2: Input e hitstop
		var em_hitstop := combate.hitstop_ativo()
		buffer.atualizar(apertados, n, 0, em_hitstop)
		if em_hitstop:
			passos_congelados.append(n)
			combate.passo_congelado_do_combate()
			_coletar_eventos()
			return

		# Item 3: Combate, início do passo
		combate.inicio_do_passo()
		if antes_do_movimento.is_valid():
			antes_do_movimento.call()

		# Item 4: Movimento
		mov.passo_no_item_4(combate, n)

		# Item 5: Combate, golpe do jogador
		var cmd := ComandosDoPasso.new(buffer, segurados, n, 0)
		combate.golpe_do_jogador([cmd])

		# Item 6: Selo
		if selo.acao_no_item_6.is_valid():
			selo.acao_no_item_6.call(n, combate)

		# Item 6.1: Maldições
		if maldicoes.acao_no_item_6_1.is_valid():
			maldicoes.acao_no_item_6_1.call(n, combate)

		# Item 7: Inimigos (em ordem estável da lista)
		for ini in ia.lista.duplicate():
			if ini.vida <= 0.0 or ini.subjugado:
				continue
			if status.acao_no_tick.is_valid():
				status.acao_no_tick.call(n, ini, combate)
			if ini.vida <= 0.0 or ini.subjugado:
				continue
			combate.impacto_do_inimigo(ini.id)
			if ini.vida <= 0.0 or ini.subjugado:
				continue
			ia.turnos.append([n, ini.id, combate.cambaleando(ini.id)])
			if ia.acao_no_turno.is_valid():
				ia.acao_no_turno.call(n, ini, combate)

		# Item 8: Projéteis
		combate.projeteis()

		# Item 9: Varredura de mortes
		combate.varredura_de_mortes()

		# Item 10: Câmaras (só avalia câmara limpa se hitstop == 0)
		if combate.pode_avaliar_camara_limpa() and ia.lista.is_empty():
			camaras.avaliacoes_camara_limpa.append(n)

		_coletar_eventos()

	func _coletar_eventos() -> void:
		for ev in eventos.esvaziar():
			log_eventos.append([n, ev.tipo(), ev])
		n += 1

	func eventos_do_passo(p: int, tipo: StringName = &"") -> Array[EventoDoPasso]:
		var r: Array[EventoDoPasso] = []
		for item in log_eventos:
			if item[0] == p and (tipo == &"" or item[1] == tipo):
				r.append(item[2])
		return r

	func todos_eventos(tipo: StringName = &"") -> Array[EventoDoPasso]:
		var r: Array[EventoDoPasso] = []
		for item in log_eventos:
			if tipo == &"" or item[1] == tipo:
				r.append(item[2])
		return r
