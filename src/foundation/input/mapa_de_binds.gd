class_name MapaDeBinds
extends RefCounted
## Mapa de binds do usuário, como valor (GDD input-e-controle R8; ADR-0006 §6).
##
## `binds`: `{familia: {chave_de_bind: [ {tipo, codigo}, ... ]}}`, mesmo formato de `BindsPadrao`, até 3 binds
## por chave com o primário no índice 0. `trocar_analogicos` é a opção do gamepad. Só a
## `TransacaoDeRemapeamento` produz mapas novos; o provedor publica um mapa já validado.

## Mesmo limite de `BindsPadrao.MAX_BINDS` (R8).
const MAX_BINDS := BindsPadrao.MAX_BINDS

## Binds por família e chave.
var binds: Dictionary = {}
## Opção "trocar analógicos" do gamepad (R8).
var trocar_analogicos: bool = false


## Mapa padrão embarcado (`BindsPadrao`), sem troca de analógicos.
static func padrao() -> MapaDeBinds:
	return de_dicionario(BindsPadrao.mapa())


## Mapa a partir de um dicionário no formato de `BindsPadrao` (cópia profunda).
static func de_dicionario(dados: Dictionary, p_trocar_analogicos: bool = false) -> MapaDeBinds:
	var mapa := MapaDeBinds.new()
	mapa.binds = dados.duplicate(true)
	mapa.trocar_analogicos = p_trocar_analogicos
	return mapa


## Cópia independente.
func copia() -> MapaDeBinds:
	return de_dicionario(binds, trocar_analogicos)


## Binds (cópia) de uma chave numa família; vazio se não houver.
func de(familia: StringName, chave: StringName) -> Array:
	var por_chave: Dictionary = binds.get(familia, {})
	return (por_chave.get(chave, []) as Array).duplicate(true)


## Substitui a lista de binds de uma chave (uso interno da transação e do repositório).
func definir(familia: StringName, chave: StringName, lista: Array) -> void:
	if not binds.has(familia):
		binds[familia] = {}
	(binds[familia] as Dictionary)[chave] = lista.duplicate(true)


## "Restaurar padrão" de uma família só (R8): a outra família fica intacta.
func restaurar_padrao(familia: StringName) -> void:
	var padrao_completo := BindsPadrao.mapa()
	binds[familia] = (padrao_completo.get(familia, {}) as Dictionary).duplicate(true)


## Igualdade de conteúdo (binds por chave lógica e opção de analógicos).
func igual_a(outro: MapaDeBinds) -> bool:
	if outro.trocar_analogicos != trocar_analogicos:
		return false
	return _assinatura(binds) == _assinatura(outro.binds)


## Chave lógica de um bind simples (`tipo:codigo`).
static func logica(bind: Dictionary) -> StringName:
	return DescritorDeEntrada.de_bind(bind).chave_logica()


static func _assinatura(dados: Dictionary) -> Dictionary:
	var saida: Dictionary = {}
	for familia: StringName in dados:
		var por_chave: Dictionary = {}
		for chave: StringName in (dados[familia] as Dictionary):
			var lista: Array[String] = []
			for bind: Dictionary in dados[familia][chave]:
				lista.append(String(logica(bind)))
			por_chave[String(chave)] = lista
		saida[String(familia)] = por_chave
	return saida
