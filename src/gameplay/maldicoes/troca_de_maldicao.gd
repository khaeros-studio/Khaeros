class_name TrocaDeMaldicao
extends RefCounted
## Ação `Troca` manual (sub-passo 5 do item 6.1) e execução da Técnica Combinada (Saída + Entrada no mesmo passo;
## GDD maldicoes.md R11, R12, R20, R21, F5; ADR-0017 §3, §5).


static func motivo_indisponivel(pacto: EstadoDoPacto) -> StringName:
	if pacto == null or pacto.campo == null:
		return &"sem_campo"
	if pacto.campo.estado == MaldicaoRef.Estado.SALTANDO:
		return &"saltando"
	if pacto.reserva == null:
		return &"sem_reserva"
	if pacto.reserva.estado == MaldicaoRef.Estado.EXAUSTA:
		return &"reserva_exausta"
	if pacto.recarga_troca > 0:
		return &"recarga"
	return &""


static func troca_disponivel(pacto: EstadoDoPacto) -> bool:
	return motivo_indisponivel(pacto) == &""


## Sub-passo 5 do 6.1: processa a ação `troca` do comando do jogador ou um pedido manual direto.
static func tentar_troca_manual(ctx: ContextoDaTecnica) -> bool:
	var pacto := ctx.pacto
	var motivo := motivo_indisponivel(pacto)
	if motivo != &"":
		if ctx.eventos != null:
			ctx.eventos.emitir(EventosMaldicoes.EvTrocaIndisponivel.new(pacto.player_id, motivo))
		return false

	var que_sai := pacto.campo
	var que_entra := pacto.reserva
	pacto.ids_marcados_saida.clear()

	# 1º: Efeito de Saída onde `que_sai` está (R12, F5)
	var tec_saida := CatalogoMaldicoes.tecnica_saida(que_sai.especie_id)
	var acertos_saida := ExecutorDeTecnica.executar(tec_saida, que_sai, ctx)

	# 2º: Avisa a IA da saída de campo ANTES da Entrada (R21: inimigos atraídos pela que sai entram em respiro no mesmo passo)
	IADeAliado.limpar_passivas_condicionais(que_sai)
	if ctx.ia != null:
		ctx.ia.maldicao_saiu_de_campo(pacto.player_id)
	if ctx.eventos != null:
		for id_atr: int in pacto.ids_atraidos:
			ctx.eventos.emitir(EventosMaldicoes.EvAtracaoFim.new(id_atr))
	pacto.ids_atraidos.clear()

	# 3º: Troca campo <-> reserva (que_sai vai para a reserva Pronta com acum_regen = 0; que_entra entra ao lado do jogador)
	que_sai.estado = MaldicaoRef.Estado.PRONTA
	que_sai.acum_regen = 0.0
	que_sai.alvo_id = -1
	que_sai.estourou_fio = false

	que_entra.pos = ctx.ia.conter(ctx.pos_jogador, que_entra.raio_px()) if ctx.ia != null else ctx.pos_jogador
	que_entra.estado = MaldicaoRef.Estado.SEGUINDO
	que_entra.alvo_id = -1
	que_entra.estourou_fio = false

	pacto.campo = que_entra
	pacto.reserva = que_sai
	pacto.recarga_troca = pacto.recarga_troca_total

	# 4º: Efeito de Entrada ao chegar, lendo o que a Saída deixou (imobilizado, marcado, atraído, Abalo)
	var tec_entrada := CatalogoMaldicoes.tecnica_entrada(que_entra.especie_id)
	var acertos_entrada := ExecutorDeTecnica.executar(tec_entrada, que_entra, ctx)
	pacto.ids_marcados_saida.clear()

	# 5º: Eventos `troca_feita(manual)` e `tecnica_combinada`
	if ctx.eventos != null:
		ctx.eventos.emitir(EventosMaldicoes.EvMaldicaoTrocada.new(
			pacto.player_id, &"manual", que_sai.id, que_entra.id))
		ctx.eventos.emitir(EventosMaldicoes.EvTecnicaCombinada.new(
			pacto.player_id, tec_saida.id, tec_entrada.id, acertos_saida + acertos_entrada))
	return true
