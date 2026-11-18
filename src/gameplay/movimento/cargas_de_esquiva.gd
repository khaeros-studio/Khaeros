class_name CargasDeEsquiva
extends RefCounted
## Cargas de esquiva e recarga sequencial (GDD movimento-e-esquiva R7, F3; ADR-0008 §3). Lógica pura em
## passos inteiros; só passos vivos chamam [method avancar]. Gastar não zera o progresso.
##
## Exemplo:
## [codeblock]
## var c := CargasDeEsquiva.new()
## c.iniciar(1)
## c.gastar()
## for i in 42: c.avancar(42)   # c.cargas == 1
## [/codeblock]

## Cargas atuais (0..maximo).
var cargas: int = 0
## Máximo guardado (última leitura de [code]valor(cargas_esquiva)[/code]).
var maximo: int = 0
## Progresso do contador em andamento (0..R−1; 0 quando cheio).
var progresso: int = 0


## Começo da run: cargas no máximo, contador zerado (R7, AC-17).
func iniciar(p_maximo: int) -> void:
	maximo = p_maximo
	cargas = p_maximo
	progresso = 0


## Item 0 da R3: aplica a mudança do atributo. Sobe → ganha a diferença; desce → corta. Zera o contador
## se ficou cheio; senão o preserva. Devolve verdadeiro se o máximo mudou.
func sincronizar(novo_maximo: int) -> bool:
	if novo_maximo == maximo:
		return false
	if novo_maximo > maximo:
		cargas += novo_maximo - maximo
	else:
		cargas = mini(cargas, novo_maximo)
	maximo = novo_maximo
	if cargas >= maximo:
		progresso = 0
	return true


## Item 1 da R3: avança a recarga de [param r] passos; a carga recuperada já vale neste passo.
func avancar(r: int) -> void:
	if cargas >= maximo:
		progresso = 0
		return
	progresso += 1
	if progresso >= r:
		cargas += 1
		progresso = 0


## Gasta uma carga (sem mexer no progresso). Falso se não havia carga.
func gastar() -> bool:
	if cargas < 1:
		return false
	cargas -= 1
	return true


## Progresso normalizado 0..1 (0 quando cheio), para a apresentação.
func progresso_normalizado(r: int) -> float:
	if cargas >= maximo or r <= 0:
		return 0.0
	return float(progresso) / float(r)
