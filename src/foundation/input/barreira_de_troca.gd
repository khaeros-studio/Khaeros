class_name BarreiraDeTroca
extends RefCounted
## Barreira da troca de contexto, por entrada física (GDD input-e-controle R10; ADR-0006 §3).
##
## Ao armar: as entradas físicas seguradas ficam bloqueadas até a soltura, e na próxima amostra todas as
## bordas do intervalo são descartadas (o toque do mesmo passo da troca conta como "segurado na troca",
## mesmo se a soltura já chegou). O desbloqueio de uma entrada não desbloqueia outra ainda segurada.
## Usada pelo `ProvedorDeEntrada` na troca de contexto, na troca de mapa e na injeção/retirada do tuning.

var _pendente: bool = false
var _bloqueados: Dictionary = {}   # chave_fisica -> true


## Arma a barreira: bloqueia as chaves físicas informadas (seguradas no passo anterior) e descarta as bordas
## da próxima amostra, bloqueando também o que estiver segurado nela.
func armar(chaves_fisicas_seguradas: Array) -> void:
	_pendente = true
	for chave: StringName in chaves_fisicas_seguradas:
		_bloqueados[chave] = true


## Aplica a barreira à amostra do passo. `fisicos`: chave_fisica → descritor segurado agora. Libera o que foi
## solto, bloqueia tudo se a barreira estava pendente e devolve as bordas que sobrevivem.
func filtrar(fisicos: Dictionary, bordas: Array[AdaptadorDeEntradaGodot.Borda]) -> Array[AdaptadorDeEntradaGodot.Borda]:
	for chave: StringName in _bloqueados.keys():
		if not fisicos.has(chave):
			_bloqueados.erase(chave)
	if not _pendente:
		return bordas
	for chave: StringName in fisicos:
		_bloqueados[chave] = true
	_pendente = false
	var vazias: Array[AdaptadorDeEntradaGodot.Borda] = []
	return vazias


## Verdadeiro se a entrada física continua bloqueada desde uma troca.
func bloqueado(chave_fisica: StringName) -> bool:
	return _bloqueados.has(chave_fisica)


## Verdadeiro se a próxima amostra ainda vai descartar bordas.
func pendente() -> bool:
	return _pendente
