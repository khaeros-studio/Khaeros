@abstract
class_name CombateParaIA
extends RefCounted
## Porta de chamadas do `ModuloDeIA` para o Combate (dano no jogador, na Maldição, na acuada,
## disparo de projéteis com alvo único, notificação de quebra e hitstop; ADR-0010, ADR-0018).


@abstract func ferir_jogador(player_id: int, dano_base: float, m_atacante: float,
		atacante_id: int, ataque_id: StringName) -> void
@abstract func ferir_maldicao(maldicao_id: int, dano_base: float, m_atacante: float,
		atacante_id: int, ataque_id: StringName) -> void
@abstract func ferir_acuada(dano_base: float, m_atacante: float,
		atacante_id: int, ataque_id: StringName) -> void
@abstract func disparar_projetil(dono_inimigo_id: int, pos: Vector2, dir: Vector2, vel_pxs: float,
		raio: float, vida_s: float, dano_base: float, m_disparo: float, atravessa: bool,
		alvo_faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> void
@abstract func aplicar_empurrao_no_alvo(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int,
		dir: Vector2, velocidade_pxs: float) -> void
@abstract func pedir_hitstop(passos: int) -> void


class Nulo extends CombateParaIA:
	func ferir_jogador(_player_id: int, _dano_base: float, _m_atacante: float,
			_atacante_id: int, _ataque_id: StringName) -> void:
		pass

	func ferir_maldicao(_maldicao_id: int, _dano_base: float, _m_atacante: float,
			_atacante_id: int, _ataque_id: StringName) -> void:
		pass

	func ferir_acuada(_dano_base: float, _m_atacante: float,
			_atacante_id: int, _ataque_id: StringName) -> void:
		pass

	func disparar_projetil(_dono_inimigo_id: int, _pos: Vector2, _dir: Vector2, _vel_pxs: float,
			_raio: float, _vida_s: float, _dano_base: float, _m_disparo: float, _atravessa: bool,
			_alvo_faccao: TelegrafoTipos.FaccaoAlvo, _alvo_id: int) -> void:
		pass

	func aplicar_empurrao_no_alvo(_faccao: TelegrafoTipos.FaccaoAlvo, _alvo_id: int,
			_dir: Vector2, _velocidade_pxs: float) -> void:
		pass

	func pedir_hitstop(_passos: int) -> void:
		pass
