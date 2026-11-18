## Contrato de uma seção opaca do perfil (ADR-0013 §7; save-e-perfil R3, R15).
##
## Implementada pelo dono do conteúdo (no MVP, o Vínculo, seção [code][vinculo][/code]);
## o [RepositorioDePerfil] não conhece os campos. Valores permitidos em
## [method escrever]: [code]bool[/code], [code]int[/code], [code]String[/code] e
## [code]Array[/code]/[code]Dictionary[/code] (chaves [code]String[/code]) feitos só
## desses — sem [code]float[/code], [code]StringName[/code], [code]Object[/code] nem
## [code]Resource[/code]. O estado por espécie vem no dicionário [code]especies[/code],
## com chave = id de [code]CurseDef[/code]. Não é thread-safe.
##
## Exemplo (dublê de teste):
## [codeblock]
## class VinculoFalso extends PortaDeSecao:
##     var estado: Dictionary = {}
##     func escrever() -> Dictionary: return estado.duplicate(true)
##     func ler(dados: Dictionary) -> void: estado = dados
##     func campos_de_ids() -> PackedStringArray: return PackedStringArray(["ultima_dupla"])
##     func migrar_conteudo(_v_de: int, dados: Dictionary) -> Dictionary: return dados
## [/codeblock]
@abstract
class_name PortaDeSecao
extends RefCounted


## Estado a persistir (cópia; o repositório não guarda referência viva).
@abstract func escrever() -> Dictionary


## Recebe o que foi lido, já migrado e filtrado de ids desconhecidos; [code]{}[/code]
## quando não há arquivo, quando é corrompido, versão futura ou reset. Validar faixas
## e a forma de cada entrada é do dono, aqui.
@abstract func ler(dados: Dictionary) -> void


## Chaves de primeiro nível cujos valores são [code]Array[/code] de ids de espécie
## (MVP: [code]["ultima_dupla", "encontro_pendente"][/code]). Ids desconhecidos viram [code]""[/code].
@abstract func campos_de_ids() -> PackedStringArray


## Migração pura do conteúdo da seção a partir da versão de formato [param v_de] do
## arquivo; devolve os dados migrados (ou os mesmos, se nada a fazer).
@abstract func migrar_conteudo(v_de: int, dados: Dictionary) -> Dictionary
