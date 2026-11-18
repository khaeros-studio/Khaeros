@abstract
class_name FonteDeComandos
extends RefCounted
## Lado do Input que o Movimento consome além da amostra (ADR-0006 §2; ADR-0008 §4). Em produção, adaptador
## sobre [ProvedorDeEntrada] ([method ProvedorDeEntrada.comandos_do_passo] e
## [method ProvedorDeEntrada.drenar_esquivas_congeladas]).


## Capacidade de consumo do buffer no passo [param id_passo] (época corrente).
@abstract func comandos_do_passo(id_passo: int) -> ComandosDoPasso

## Toques novos de Esquiva feitos durante hitstop desde a última drenagem (zera a contagem).
@abstract func drenar_esquivas_congeladas() -> int
