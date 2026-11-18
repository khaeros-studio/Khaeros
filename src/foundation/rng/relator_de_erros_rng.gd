## Contrato do relator de erros injetado no RNG (GDD rng-com-seed.md, Edge Cases;
## ADR-0005, "Operações e limites").
##
## Um pedido inválido nunca usa `assert` (para ficar testável): gera exatamente
## um registro aqui e conserva a sequência. A implementação real (log/relatório
## de erro) é montada no ponto de composição; os testes usam um dublê que grava.
class_name RelatorDeErrosRng
extends RefCounted


## Uma operação de sorteio (F3–F8) foi recusada: argumento inválido ou fluxo
## com marcador de validade inválido. `operacao` identifica a fórmula.
func registrar_operacao_invalida(_operacao: StringName, _motivo: String) -> void:
	pass


## Um pedido de fluxo foi recusado (Sem run, Encerrada, chave fora das faixas
## ou finalidade fora da matriz dono × finalidade).
func registrar_pedido_recusado(_finalidade: int, _regiao: int, _profundidade: int, _solicitante: StringName, _motivo: String) -> void:
	pass


## Aviso que não impede a run (ex.: "seed ignorada em release").
func registrar_aviso(_mensagem: String) -> void:
	pass
