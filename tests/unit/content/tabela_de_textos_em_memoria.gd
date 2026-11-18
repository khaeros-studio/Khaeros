class_name TabelaDeTextosEmMemoria
extends TabelaDeTextos
## Dublê de [TabelaDeTextos] para testes (sem tradução importada).

var _textos: Dictionary[String, String] = {}


## Define (ou troca) o texto de uma chave.
func definir(chave: String, valor: String) -> void:
	_textos[chave] = valor


func tem(chave: String) -> bool:
	return _textos.has(chave)


func texto(chave: String) -> String:
	return _textos.get(chave, "")
