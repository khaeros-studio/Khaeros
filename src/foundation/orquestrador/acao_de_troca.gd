## Uma das seis ações da troca de câmara (Combate R1, Transição; ADR-0001).
##
## O orquestrador as executa uma única vez, em ordem, no primeiro [code]quadro()[/code]
## de [code]TRANSICAO[/code] com [code]progresso_wipe[/code] ≥ 0,5: 1 Combate "câmara nova";
## 2 teleporte do jogador; 3 Câmaras montam a câmara e o Selo apaga os Selos; 4 VFX
## dos relógios apagados; 5 corte da câmera; 6 Pipeline troca a LUT e zera os relógios.
## O conteúdo de cada ação é do dono (Combate, Movimento, Câmaras, Cena, Pipeline).
##
## Exemplo:
## [codeblock]
## class_name AcaoCamaraNovaDoCombate extends AcaoDeTroca
## var _combate: ModuloDeCombate
## func executar() -> void:
##     _combate.camara_nova()
## [/codeblock]
## Não é seguro entre threads.
@abstract
class_name AcaoDeTroca
extends RefCounted


## Executa a ação. Não adiciona nem remove nós de física da engine.
@abstract func executar() -> void
