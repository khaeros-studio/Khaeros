class_name DadoDeConteudo
extends Resource
## Base de todo dado de conteúdo do catálogo: definições com id ([DefinicaoBase]) e
## sub-recursos embutidos sem id ([AttackDef], [EffectDef], [BossPatternDef],
## [LinearCurveDef]). Tratado como só de leitura em execução (GDD de Conteúdo R3).
##
## O esquema é derivado das propriedades [code]@export[/code] da classe e completado
## pela própria classe em [method _declarar_regras] (obrigatoriedade, limites,
## referências, chaves de texto, arte, tabelas de peso e regras entre campos).
##
## Exemplo:
## [codeblock]
## var e: EsquemaDeDefinicao = AttackDef.new().esquema()
## var r := e.regra(&"recarga_s")   # r.aceita_zero == false
## [/codeblock]


## Esquema declarativo desta classe (cacheado por script).
func esquema() -> EsquemaDeDefinicao:
	return EsquemaDeDefinicao.de(self)


## Ponto de extensão: a subclasse declara obrigatoriedade, limites e referências.
## Não deve ler valores da instância (o esquema é por classe).
func _declarar_regras(_e: EsquemaDeDefinicao) -> void:
	pass


## Nome da classe para mensagens (ex.: [code]"EnemyDef"[/code]).
func nome_da_classe() -> String:
	var s: Script = get_script()
	if s == null:
		return "Resource"
	return String(s.get_global_name())
