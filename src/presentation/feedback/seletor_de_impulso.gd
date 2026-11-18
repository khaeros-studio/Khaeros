class_name SeletorDeImpulso
extends RefCounted
## Remetente único de `PedidoImpulso` para `ImpulsosDeCamera` (`ADR-0007`, `R5`, `R15`).
## Resolve preempção (`chefe > pesado > leve`), desempate por maior escala e prioridade,
## e aplica `intensidade_tremor` / `reduzir_movimento`.

class CandidatoImpulso extends RefCounted:
	var evento_id: StringName = &""
	var preset: StringName = &""
	var escala: float = 0.0
	var direcao: Vector2 = Vector2.RIGHT
	var prioridade: int = 2

	func _init(
		p_evento: StringName,
		p_preset: StringName,
		p_escala: float,
		p_dir: Vector2 = Vector2.RIGHT,
		p_prio: int = 2
	) -> void:
		evento_id = p_evento
		preset = p_preset
		escala = p_escala
		direcao = p_dir
		prioridade = p_prio


var _candidatos: Array[CandidatoImpulso] = []
var _intensidade_tremor: float = 1.0
var _reduzir_movimento: bool = false


func configurar_acessibilidade(intensidade_tremor: float = 1.0, reduzir_movimento: bool = false) -> void:
	_intensidade_tremor = clampf(intensidade_tremor, 0.0, 1.0)
	_reduzir_movimento = reduzir_movimento


func limpar_passo() -> void:
	_candidatos.clear()


func propor(
	evento_id: StringName,
	preset: StringName,
	escala: float,
	direcao: Vector2 = Vector2.RIGHT,
	prioridade: int = 2
) -> void:
	if preset == &"" or escala <= 0.0:
		return
	# R15: ataques básicos e acertos recebidos pela Maldição nunca enviam impulso de câmera
	if evento_id == &"maldicao_atacou" or evento_id == &"maldicao_atingida":
		return
	_candidatos.append(CandidatoImpulso.new(evento_id, preset, escala, direcao, prioridade))


func resolver_pedido(epoca: int, t_inicio: float) -> PedidoImpulso:
	if _candidatos.is_empty():
		return null
	if _reduzir_movimento or _intensidade_tremor <= 0.0001:
		return null

	var vencedor: CandidatoImpulso = _candidatos[0]
	for i: int in range(1, _candidatos.size()):
		var c: CandidatoImpulso = _candidatos[i]
		if _vence(c, vencedor):
			vencedor = c

	var escala_final: float = clampf(vencedor.escala * _intensidade_tremor, 0.0, 2.0)
	if escala_final <= 0.0001:
		return null
	var dir_segura: Vector2 = vencedor.direcao.normalized() if vencedor.direcao.length_squared() > 0.0001 else Vector2.RIGHT
	return PedidoImpulso.new(vencedor.preset, escala_final, dir_segura, epoca, t_inicio)


func despachar_para_camera(
	camera_impulsos: ImpulsosDeCamera,
	epoca: int,
	t_atual: float
) -> PedidoImpulso:
	var pedido: PedidoImpulso = resolver_pedido(epoca, t_atual)
	if pedido != null and camera_impulsos != null:
		camera_impulsos.receber(pedido, epoca, t_atual)
	return pedido


static func peso_preset(preset: StringName) -> int:
	if preset == &"chefe":
		return 3
	if preset == &"pesado":
		return 2
	if preset == &"leve":
		return 1
	return 0


static func _vence(novo: CandidatoImpulso, atual: CandidatoImpulso) -> bool:
	var p_novo: int = peso_preset(novo.preset)
	var p_atual: int = peso_preset(atual.preset)
	if p_novo != p_atual:
		return p_novo > p_atual
	if not is_equal_approx(novo.escala, atual.escala):
		return novo.escala > atual.escala
	# recusou_morte sempre vence jogador_atingido em empate de preset/escala
	if novo.evento_id == &"recusou_morte" and atual.evento_id != &"recusou_morte":
		return true
	if atual.evento_id == &"recusou_morte" and novo.evento_id != &"recusou_morte":
		return false
	if novo.prioridade != atual.prioridade:
		return novo.prioridade < atual.prioridade
	return false
