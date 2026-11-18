@abstract
class_name ConsultaDeAlvoMaldicao
extends RefCounted
## Porta de leitura de alvos (Inimigos, Jogadores, Maldição e Acuada) para o módulo Telégrafos (ADR-0014).


@abstract func dono_vivo(inimigo_id: int) -> bool
@abstract func posicao_dono(inimigo_id: int) -> Vector2
@abstract func posicao_alvo(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> Vector2
@abstract func raio_alvo(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> float
@abstract func alvo_atingivel(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> bool
