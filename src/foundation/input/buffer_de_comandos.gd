class_name BufferDeComandos
extends RefCounted
## Buffer de comandos com contador único (GDD input-e-controle R6, F3 e emenda Pactos; ADR-0006 §2, §3;
## complemento do ADR-0008). Lógica pura; tempo em passos inteiros.
##
## F3: P = apertados ∩ {esquiva, especial, ataque, selo, troca}; se P ≠ ∅: B = B ∪ P e T = buffer_passos;
## senão, se T > 0 e o passo não é de hitstop: T −= 1 e, em T = 0, B = ∅. Consumir X: B = B − {X}.
## Cada entrada guarda `{acao, passo_do_toque, epoca, durante_congelamento}`.

## Uma entrada do buffer.
class Entrada extends RefCounted:
	## Ação no buffer.
	var acao: StringName
	## Passo do último toque desta ação.
	var passo_do_toque: int
	## Época do contexto do toque.
	var epoca: int
	## O toque foi feito durante hitstop (congelamento).
	var durante_congelamento: bool

	func _init(p_acao: StringName, p_passo: int, p_epoca: int, p_congelado: bool) -> void:
		acao = p_acao
		passo_do_toque = p_passo
		epoca = p_epoca
		durante_congelamento = p_congelado


var _buffer_passos: int = 0
var _prazo: int = 0
var _entradas: Dictionary = {}   # acao -> Entrada
var _esquivas_congeladas: int = 0


## `buffer_passos` vem do `InputTuning` (F3, 1–30).
func _init(buffer_passos: int = 0) -> void:
	_buffer_passos = buffer_passos


## Troca o prazo configurado (novo `InputTuning`); não altera o conteúdo atual.
func configurar(buffer_passos: int) -> void:
	_buffer_passos = buffer_passos


## Aplica F3 a um passo de Jogo com os toques novos do passo.
func atualizar(apertados: Array[StringName], id_passo: int, epoca: int, hitstop: bool) -> void:
	var houve_toque := false
	for acao: StringName in Acoes.NO_BUFFER:
		if not apertados.has(acao):
			continue
		houve_toque = true
		_entradas[acao] = Entrada.new(acao, id_passo, epoca, hitstop)
		if acao == Acoes.ESQUIVA and hitstop:
			_esquivas_congeladas += 1
	if houve_toque:
		_prazo = _buffer_passos
	elif _prazo > 0 and not hitstop:
		_prazo -= 1
		if _prazo == 0:
			_entradas.clear()


## Esvazia o buffer (fora de Jogo, troca de contexto, perda de foco).
func esvaziar() -> void:
	_entradas.clear()
	_prazo = 0
	_esquivas_congeladas = 0


## Verdadeiro se `acao` está no buffer com a época dada. Não aloca.
func contem(acao: StringName, epoca: int) -> bool:
	var entrada: Entrada = _entradas.get(acao)
	return entrada != null and entrada.epoca == epoca


## Remove só `acao` (não mexe no prazo nem nas outras). Verdadeiro se removeu.
func remover(acao: StringName, epoca: int) -> bool:
	if not contem(acao, epoca):
		return false
	_entradas.erase(acao)
	return true


## Prazo restante (T).
func prazo() -> int:
	return _prazo


## Ações no buffer, na ordem de prioridade (cópia).
func visao() -> Array[StringName]:
	var saida: Array[StringName] = []
	for acao: StringName in Acoes.NO_BUFFER:
		if _entradas.has(acao):
			saida.append(acao)
	return saida


## Metadados da entrada de `acao` (cópia `{acao, passo_do_toque, epoca, durante_congelamento}`), ou vazio.
func metadados(acao: StringName) -> Dictionary:
	var entrada: Entrada = _entradas.get(acao)
	if entrada == null:
		return {}
	return {"acao": entrada.acao, "passo_do_toque": entrada.passo_do_toque, "epoca": entrada.epoca,
			"durante_congelamento": entrada.durante_congelamento}


## Complemento ADR-0008: devolve e zera a contagem de toques de esquiva feitos durante hitstop. O Movimento
## chama no 1º passo vivo seguinte (integração no épico movimento-e-esquiva).
func drenar_esquivas_congeladas() -> int:
	var total := _esquivas_congeladas
	_esquivas_congeladas = 0
	return total


## Atalho para registrar um toque de `acao` no buffer (sem descartar outras entradas) e reiniciar o prazo.
func apertar(acao: StringName, passo: int = 0, epoca: int = 0, congelado: bool = false) -> void:
	if not Acoes.NO_BUFFER.has(acao):
		return
	_entradas[acao] = Entrada.new(acao, passo, epoca, congelado)
	if acao == Acoes.ESQUIVA and congelado:
		_esquivas_congeladas += 1
	_prazo = _buffer_passos


## Atalho para avançar um passo sem novos toques (desconta 1 do prazo quando não está em hitstop).
func avancar_passo(hitstop: bool = false) -> void:
	atualizar([], 0, 0, hitstop)


## Atalho para `contem(acao, epoca)` com `epoca = 0` por omissão.
func tem(acao: StringName, epoca: int = 0) -> bool:
	return contem(acao, epoca)


## Atalho para `remover(acao, epoca)` com `epoca = 0` por omissão.
func consumir(acao: StringName, epoca: int = 0) -> bool:
	return remover(acao, epoca)
