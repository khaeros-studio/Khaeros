## Contrato do relator de erros injetado no RNG (GDD rng-com-seed.md, Edge Cases;
## ADR-0005, "Operações e limites").
##
## Um pedido inválido nunca usa `assert` (para ficar testável): gera exatamente
## um registro aqui e conserva a sequência. A implementação real (log/relatório
## de erro) é montada no ponto de composição; os testes usam um dublê que grava.
@abstract
class_name RelatorDeErrosRng
extends RefCounted


## Uma operação de sorteio (F3–F8) foi recusada: argumento inválido ou fluxo
## com marcador de validade inválido. `operacao` identifica a fórmula.
@abstract func registrar_operacao_invalida(operacao: StringName, motivo: String) -> void


## Um pedido de fluxo foi recusado (Sem run, Encerrada, chave fora das faixas
## ou finalidade fora da matriz dono × finalidade).
@abstract func registrar_pedido_recusado(finalidade: int, regiao: int, profundidade: int, solicitante: StringName, motivo: String) -> void


## Aviso que não impede a run (ex.: "seed ignorada em release").
@abstract func registrar_aviso(mensagem: String) -> void
