## Modelo dos avisos do perfil (save-e-perfil "UI Requirements"; TR-save-018; ADR-0012).
##
## Lógica pura, sem [Control]: recebe as chaves publicadas pelo [Save] e pelo
## [RepositorioDePerfil] ([method receber] é o [Callable] [code]avisar[/code] injetado) e
## decide o que a tela mostra. Cada chave entra no máximo uma vez por sessão; nada é
## mostrado em [constant EstadoDeJogo.Valor.JOGO] (nunca por cima do combate). A tela
## (épico hud) só apresenta: textos por chave de tradução, foco na [code]acao_padrao[/code],
## [code]ui_voltar[/code] = [code]acao_de_voltar[/code]. Não tem estado de jogo próprio.
## Não é thread-safe.
##
## Exemplo:
## [codeblock]
## var fila := FilaDeAvisosDoPerfil.new()
## save.configurar(perfil, fila.receber)
## var aviso := fila.atual(orquestrador.estado())   # {} em JOGO ou sem aviso
## if not aviso.is_empty():
##     tela.mostrar(aviso)                           # título = aviso["chave"]
## # jogador escolheu:
## match fila.escolher(&"tentar_de_novo"):
##     &"tentar_de_novo": save.tentar_saida_de_novo()
## [/codeblock]
class_name FilaDeAvisosDoPerfil
extends RefCounted

## Ação "OK" (fecha o aviso).
const ACAO_OK: StringName = &"ok"
## Ação "Tentar de novo" da saída (o aviso continua até sair ou desistir).
const ACAO_TENTAR_DE_NOVO: StringName = &"tentar_de_novo"
## Ação "Sair sem salvar" da saída.
const ACAO_SAIR_SEM_SALVAR: StringName = &"sair_sem_salvar"

## Chave de tradução do texto de cada ação (a tabela de tradução é do épico hud).
const TEXTO_DA_ACAO: Dictionary = {
	&"ok": &"AVISO_ACAO_OK",
	&"tentar_de_novo": &"PERFIL_ACAO_TENTAR_DE_NOVO",
	&"sair_sem_salvar": &"PERFIL_ACAO_SAIR_SEM_SALVAR",
}

# chave → [ações (a 1ª é a padrão), ação de voltar, discreto, prioritário]
const _DEFINICOES: Dictionary = {
	&"PERFIL_CORROMPIDO": [[&"ok"], &"ok", false, false],
	&"PERFIL_VERSAO_FUTURA": [[&"ok"], &"ok", false, false],
	&"PERSIST_FALHA_GRAVAR": [[&"ok"], &"ok", true, false],
	# Voltar = tentar de novo: um toque acidental não descarta o progresso.
	&"PERFIL_SAIR_SEM_SALVAR": [[&"tentar_de_novo", &"sair_sem_salvar"], &"tentar_de_novo", false, true],
}

var _recebidos: Dictionary = {}
var _fila: Array[StringName] = []


## Recebe uma chave publicada. [code]true[/code] se entrou na fila; chave desconhecida ou já
## recebida nesta sessão → [code]false[/code]. A saída sem salvar fura a fila.
func receber(chave: StringName) -> bool:
	if not _DEFINICOES.has(chave) or _recebidos.has(chave):
		return false
	_recebidos[chave] = true
	if _DEFINICOES[chave][3]:
		_fila.push_front(chave)
	else:
		_fila.append(chave)
	return true


## Aviso a mostrar em [param estado_de_jogo]: [code]{}[/code] em JOGO ou sem aviso; senão
## [code]{chave, acoes: Array[StringName], acao_padrao, acao_de_voltar, discreto}[/code].
func atual(estado_de_jogo: EstadoDeJogo.Valor) -> Dictionary:
	if estado_de_jogo == EstadoDeJogo.Valor.JOGO or _fila.is_empty():
		return {}
	var chave: StringName = _fila[0]
	var d: Array = _DEFINICOES[chave]
	var acoes: Array[StringName] = []
	acoes.assign(d[0])
	return {
		"chave": chave, "acoes": acoes, "acao_padrao": acoes[0],
		"acao_de_voltar": d[1], "discreto": d[2],
	}


## Jogador escolheu [param acao] no aviso atual. Devolve a ação para o [code]Main[/code]
## rotear ([code]&""[/code] se inválida). [constant ACAO_TENTAR_DE_NOVO] mantém o aviso;
## as outras o fecham para sempre nesta sessão.
func escolher(acao: StringName) -> StringName:
	if _fila.is_empty() or not (_DEFINICOES[_fila[0]][0] as Array).has(acao):
		return &""
	if acao != ACAO_TENTAR_DE_NOVO:
		_fila.pop_front()
	return acao


## Quantos avisos esperam (diagnóstico e testes).
func pendentes() -> int:
	return _fila.size()
