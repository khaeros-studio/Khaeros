## Dublê de PortaDeSecao para os testes do perfil: registra cada ler() e devolve
## em escrever() o estado programado. Carregado por preload (sem class_name).
extends PortaDeSecao

## Estado devolvido por escrever().
var estado: Dictionary = {}
## Cada dicionário recebido em ler(), em ordem.
var lidos: Array[Dictionary] = []
## Passo de migração de conteúdo (Callable(v_de, dados) -> dados); vazio = identidade.
var migrador: Callable = Callable()


func escrever() -> Dictionary:
	return estado.duplicate(true)


func ler(dados: Dictionary) -> void:
	lidos.append(dados.duplicate(true))


func campos_de_ids() -> PackedStringArray:
	return PackedStringArray(["ultima_dupla", "encontro_pendente"])


func migrar_conteudo(v_de: int, dados: Dictionary) -> Dictionary:
	if migrador.is_valid():
		return migrador.call(v_de, dados)
	return dados
