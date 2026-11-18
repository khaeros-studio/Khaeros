class_name TextoDaCarta
extends RefCounted
## Formatação do texto e montagem da vista de dados de uma carta de bênção
## (GDD bencaos-tradicoes.md R10; ADR-0009 §Formatação compartilhada, ADR-0012 §11;
## TR-bencaos-009).
##
## Usa exclusivamente [method FormulasDeModificadores.formatar_numero_arredondado] para
## que o número exibido na carta seja idêntico ao valor aplicado no [Portador]
## (ex.: Rara de O Muro de Pedras 25 × 1,5 = 37,5 → "+38", Épica → "+50"; AC-BN-18).
## Nunca usa [code]round()[/code], [code]roundi()[/code] nem [code]snappedf()[/code].
##
## Exemplo:
## [codeblock]
## var texto := TextoDaCarta.formatar_descricao(muro_de_pedras, SorteioDeOferta.RARA, tabela, textos)
## # "+38 de Vida máxima"
## [/codeblock]

## Template padrão por id canônico quando nenhuma tabela de tradução é injetada.
const TEMPLATES_PADRAO: Dictionary = {
	&"TRAD_GUARDIAN_MURO_PEDRAS_DESC": "+{valor} de Vida máxima",
	&"TRAD_BLADE_TRACO_UNICO_DESC": "+{valor}% de dano no Ataque",
	&"TRAD_BLADE_LAMINA_PESADA_DESC": "+{valor}% de dano no Especial",
	&"TRAD_RESONANCE_PRECO_NOME_DESC": "+{valor}% em todo dano",
	&"TRAD_VEIL_FIO_INVISIVEL_DESC": "+{valor}% de velocidade",
}


## Escala numérica da raridade a partir da [RarityTable] (1,0 / 1,5 / 2,0).
static func escala_da_raridade(raridade: int, tabela: RarityTable) -> float:
	if tabela == null or tabela.escalas.is_empty():
		return 1.0
	var idx: int = clampi(raridade, 0, tabela.escalas.size() - 1)
	return tabela.escalas[idx]


## Valor numérico escalado do primeiro efeito da [BoonDef] na [param raridade].
## Percentuais (ex.: 0,25) cuja chave de template usa "%" ou cujo tipo termina em "_pct"
## são convertidos para pontos percentuais antes do arredondamento quando [param como_percentual] é verdadeiro.
static func valor_para_exibicao(boon: BoonDef, raridade: int, tabela: RarityTable, como_percentual: bool = false) -> float:
	if boon == null or boon.efeitos.is_empty():
		return 0.0
	var efeito: EffectDef = boon.efeitos[0]
	var escala: float = escala_da_raridade(raridade, tabela)
	var escalado: float = AplicadorDeEfeitos.valor_escalado(efeito, escala)
	if como_percentual:
		return escalado * 100.0
	return escalado


## String do número já arredondado pela regra do Modificadores (meio longe de zero).
static func numero_formatado(boon: BoonDef, raridade: int, tabela: RarityTable, como_percentual: bool = false) -> String:
	var v: float = valor_para_exibicao(boon, raridade, tabela, como_percentual)
	return FormulasDeModificadores.formatar_numero_arredondado(v)


## Monta a descrição da [param boon] na [param raridade] a partir da chave de tradução
## [member BoonDef.chave_descricao]. Se [param textos] for fornecida e contiver a chave,
## usa o template dela; senão usa [constant TEMPLATES_PADRAO] ou [code]"+{valor} de Vida máxima"[/code]
## para [code]vida_max_plano[/code]. Substitui [code]{valor}[/code] pelo número arredondado.
static func formatar_descricao(boon: BoonDef, raridade: int, tabela: RarityTable,
		textos: TabelaDeTextos = null) -> String:
	if boon == null:
		return ""
	var chave: String = String(boon.chave_descricao)
	var template: String = ""
	if textos != null and textos.tem(chave):
		template = textos.obter(chave)
	elif TEMPLATES_PADRAO.has(boon.chave_descricao):
		template = String(TEMPLATES_PADRAO[boon.chave_descricao])
	elif not boon.efeitos.is_empty() and boon.efeitos[0].tipo == &"vida_max_plano":
		template = "+{valor} de Vida máxima"
	else:
		template = "+{valor}"
	var usa_pct: bool = template.contains("%")
	var num_str: String = numero_formatado(boon, raridade, tabela, usa_pct)
	return template.format({"valor": num_str})


## Monta o dicionário de vista (`CartaView` / `DadosDaCarta` em dados puros) para a Tela,
## pronto com [code]id[/code], [code]raridade[/code], [code]chave_nome[/code],
## [code]doutrina[/code], [code]texto[/code] e [code]numero_aplicado[/code].
static func montar_carta_view(boon: BoonDef, raridade: int, tabela: RarityTable,
		textos: TabelaDeTextos = null) -> Dictionary:
	var texto: String = formatar_descricao(boon, raridade, tabela, textos)
	var num: int = FormulasDeModificadores.arredondar_meio_longe_do_zero(
		valor_para_exibicao(boon, raridade, tabela, texto.contains("%"))
	)
	return {
		&"id": boon.id if boon != null else &"",
		&"raridade": raridade,
		&"chave_nome": boon.chave_nome if boon != null else &"",
		&"chave_descricao": boon.chave_descricao if boon != null else &"",
		&"doutrina": boon.doutrina if boon != null else &"",
		&"texto": texto,
		&"numero_aplicado": num,
	}
