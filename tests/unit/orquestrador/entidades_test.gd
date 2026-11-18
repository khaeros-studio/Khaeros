## Testes das entidades vivas e identidade na run (ADR-0003, story orquestrador-do-passo/002).
## Lógica pura: sem SceneTree, sem I/O. Definições de inimigo/jogador são Resource de fixture.
extends GdUnitTestSuite


## Definição de fixture (o EnemyDef real é do épico de catálogo).
class DefFixture extends Resource:
	var vida_base: float = VIDA_FIXTURE


## Portador falso: recebe dados, sem referência de volta ao combatente.
class PortadorFalso extends RefCounted:
	var dono_id: int = 0


const VIDA_FIXTURE: float = 40.0
const DANO_FIXTURE: float = 15.0
const POS_FIXTURE := Vector2(30.0, 20.0)


func _gerar(ids: GeradorDeIds, def: Resource, lista: Array[InimigoRef]) -> InimigoRef:
	var i := InimigoRef.new(ids.proximo(), def)
	i.vida = VIDA_FIXTURE
	lista.append(i)
	return i


func _ids_de(lista: Array[InimigoRef]) -> Array[int]:
	var r: Array[int] = []
	for i: InimigoRef in lista:
		r.append(i.id)
	return r


# --- Identidade e ordem ------------------------------------------------------

func test_gerar_tres_remover_segundo_gerar_outro_mantem_ordem_e_ids() -> void:
	# Arrange
	var ids := GeradorDeIds.new()
	var def := DefFixture.new()
	var lista: Array[InimigoRef] = []
	var a := _gerar(ids, def, lista)
	var b := _gerar(ids, def, lista)
	var c := _gerar(ids, def, lista)
	var id_a := a.id
	var id_c := c.id

	# Act — remoção ordenada (a IA faz isso no jogo; aqui o teste)
	lista.remove_at(lista.find(b))
	var d := _gerar(ids, def, lista)

	# Assert
	assert_array(_ids_de(lista)).contains_exactly([id_a, id_c, d.id])
	assert_bool(lista[0] == a and lista[1] == c and lista[2] == d).is_true()
	assert_int(a.id).is_equal(id_a)
	assert_int(c.id).is_equal(id_c)
	assert_bool(d.id != b.id).is_true()
	assert_int(d.id).is_greater(c.id)


func test_gerador_sequencia_crescente_unica_e_compartilhada() -> void:
	# Arrange — inimigos e Maldições pedem ao mesmo gerador injetado
	var ids := GeradorDeIds.new()
	var vistos: Array[int] = []

	# Act
	vistos.append(InimigoRef.new(ids.proximo(), DefFixture.new()).id)
	vistos.append(ids.proximo())  # o que uma MaldicaoRef pediria
	vistos.append(InimigoRef.new(ids.proximo(), DefFixture.new()).id)

	# Assert
	assert_array(vistos).contains_exactly([GeradorDeIds.PRIMEIRO_ID, GeradorDeIds.PRIMEIRO_ID + 1, GeradorDeIds.PRIMEIRO_ID + 2])


func test_gerador_reiniciar_volta_ao_primeiro_id_na_nova_run() -> void:
	# Arrange
	var ids := GeradorDeIds.new()
	ids.proximo()
	ids.proximo()

	# Act
	ids.reiniciar()

	# Assert
	assert_int(ids.proximo()).is_equal(GeradorDeIds.PRIMEIRO_ID)


func test_gerador_primeiro_id_nunca_e_id_invalido() -> void:
	# Assert
	assert_int(GeradorDeIds.PRIMEIRO_ID).is_not_equal(GeradorDeIds.ID_INVALIDO)
	assert_int(InimigoRef.new(GeradorDeIds.PRIMEIRO_ID, DefFixture.new()).id).is_equal(GeradorDeIds.PRIMEIRO_ID)


# --- Independência de instâncias e definição --------------------------------

func test_dois_inimigos_da_mesma_definicao_estado_independente_e_def_intacta() -> void:
	# Arrange
	var ids := GeradorDeIds.new()
	var def := DefFixture.new()
	var lista: Array[InimigoRef] = []
	var a := _gerar(ids, def, lista)
	var b := _gerar(ids, def, lista)

	# Act
	a.vida -= DANO_FIXTURE
	a.posicao = POS_FIXTURE
	a.no_selo = true

	# Assert
	assert_float(b.vida).is_equal(VIDA_FIXTURE)
	assert_vector(b.posicao).is_equal(Vector2.ZERO)
	assert_bool(b.no_selo).is_false()
	assert_float((def as DefFixture).vida_base).is_equal(VIDA_FIXTURE)
	assert_bool(a.definicao == b.definicao).is_true()


func test_dois_jogadores_estado_independente() -> void:
	# Arrange
	var def := DefFixture.new()
	var p0 := JogadorRef.new(0, def)
	var p1 := JogadorRef.new(1, def)

	# Act
	p0.posicao = POS_FIXTURE
	p0.fluxo = DANO_FIXTURE

	# Assert
	assert_vector(p1.posicao).is_equal(Vector2.ZERO)
	assert_float(p1.fluxo).is_equal(0.0)
	assert_int(p1.player_id).is_equal(1)


# --- Chefe e acuada ----------------------------------------------------------

func test_chefe_e_campo_de_inimigo_ref() -> void:
	# Arrange / Act
	var chefe := InimigoRef.new(GeradorDeIds.PRIMEIRO_ID, DefFixture.new(), true)
	var comum := InimigoRef.new(GeradorDeIds.PRIMEIRO_ID + 1, DefFixture.new())

	# Assert
	assert_bool(chefe.chefe).is_true()
	assert_bool(comum.chefe).is_false()


func test_acuada_nao_e_inimigo_ref_e_nao_entra_na_lista() -> void:
	# Arrange — a acuada é do Vínculo; a lista tipada só aceita InimigoRef
	var lista: Array[InimigoRef] = []
	var acuada := RefCounted.new()

	# Act
	var e_inimigo: bool = acuada is InimigoRef

	# Assert
	assert_bool(e_inimigo).is_false()
	assert_int(lista.size()).is_equal(0)


# --- Retrato de mortos -------------------------------------------------------

func test_retrato_de_mortos_lista_ordenada_dos_com_vida_ate_zero() -> void:
	# Arrange
	var ids := GeradorDeIds.new()
	var def := DefFixture.new()
	var lista: Array[InimigoRef] = []
	var a := _gerar(ids, def, lista)
	var b := _gerar(ids, def, lista)
	var c := _gerar(ids, def, lista)
	var d := _gerar(ids, def, lista)
	c.vida = 0.0
	a.vida = -DANO_FIXTURE
	b.vida = DANO_FIXTURE

	# Act
	var mortos := RetratoDeMortos.retrato_de_mortos(lista)

	# Assert — ordem da lista (ordem de surgimento), não a ordem em que morreram
	assert_array(_ids_de(mortos)).contains_exactly([a.id, c.id])
	assert_bool(mortos.has(d)).is_false()


func test_retrato_mortes_durante_o_passe_entram_no_passe_seguinte() -> void:
	# Arrange
	var ids := GeradorDeIds.new()
	var def := DefFixture.new()
	var lista: Array[InimigoRef] = []
	var a := _gerar(ids, def, lista)
	var b := _gerar(ids, def, lista)
	a.vida = 0.0
	var primeiro := RetratoDeMortos.retrato_de_mortos(lista)

	# Act — durante o passe, a morte de "a" mata "b" (explosão, por exemplo) e "a" é removido
	for m: InimigoRef in primeiro:
		b.vida = 0.0
		lista.remove_at(lista.find(m))
	var segundo := RetratoDeMortos.retrato_de_mortos(lista)

	# Assert
	assert_array(_ids_de(primeiro)).contains_exactly([a.id])
	assert_array(_ids_de(segundo)).contains_exactly([b.id])


func test_retrato_e_copia_mutar_nao_altera_lista_viva() -> void:
	# Arrange
	var ids := GeradorDeIds.new()
	var lista: Array[InimigoRef] = []
	_gerar(ids, DefFixture.new(), lista).vida = 0.0

	# Act
	RetratoDeMortos.retrato_de_mortos(lista).clear()

	# Assert
	assert_int(lista.size()).is_equal(1)


# --- Liberação (sem ciclos) --------------------------------------------------

func test_inimigo_e_portador_liberados_sem_referencia_de_volta() -> void:
	# Arrange
	var i := InimigoRef.new(GeradorDeIds.PRIMEIRO_ID, DefFixture.new())
	var p := PortadorFalso.new()
	p.dono_id = i.id
	i.portador = p
	var ref_i: WeakRef = weakref(i)
	var ref_p: WeakRef = weakref(p)

	# Act
	p = null
	i = null

	# Assert
	assert_object(ref_i.get_ref()).is_null()
	assert_object(ref_p.get_ref()).is_null()


func test_jogador_e_portador_liberados_sem_referencia_de_volta() -> void:
	# Arrange
	var j := JogadorRef.new(0, DefFixture.new())
	var p := PortadorFalso.new()
	j.portador = p
	var ref_j: WeakRef = weakref(j)
	var ref_p: WeakRef = weakref(p)

	# Act
	p = null
	j = null

	# Assert
	assert_object(ref_j.get_ref()).is_null()
	assert_object(ref_p.get_ref()).is_null()
