class_name NotificadorDeAtributo
extends OuvinteDeAtributos
## Despachante do aviso atributo × recurso (GDD modificadores-e-atributos R9, F4;
## ADR-0009 §6). O Main injeta uma instância nos portadores e registra os donos de
## recurso por atributo (Combate: vida_max, escudo_sala, recusas_morte; Bênçãos:
## trocas_oferta). Chamada síncrona, nunca sinal do Godot. As funções estáticas são as
## reações puras da R9 que os donos aplicam aos seus recursos (Modificadores nunca
## escreve recurso).
##
## Exemplo:
## [codeblock]
## var n := NotificadorDeAtributo.new()
## n.registrar(Atributos.VIDA_MAX, combate_ouvinte)
## portador.definir_ouvinte(n)
## vida = NotificadorDeAtributo.vida_apos_mudar_max(vida, antigo, novo)
## [/codeblock]

var _por_atributo: Dictionary[StringName, Array] = {}


## Registra [param ouvinte] para os avisos de [param atributo] (ordem de registro mantida).
func registrar(atributo: StringName, ouvinte: OuvinteDeAtributos) -> void:
	if not _por_atributo.has(atributo):
		_por_atributo[atributo] = []
	_por_atributo[atributo].append(ouvinte)


func atributo_mudou(id_combatente: int, player_id: int, atributo: StringName, antigo: int, novo: int) -> void:
	for o: OuvinteDeAtributos in _por_atributo.get(atributo, []):
		o.atributo_mudou(id_combatente, player_id, atributo, antigo, novo)


## F4: [code]min(vida + max(novo − antigo, 0), novo)[/code]. Descer nunca mata.
static func vida_apos_mudar_max(vida: float, antigo: int, novo: int) -> float:
	return minf(vida + maxi(novo - antigo, 0), novo)


## Cargas de esquiva, recusas e trocas (R9): sobe → ganha a diferença; desce → corta.
static func restantes_apos_mudar_max(restantes: int, antigo: int, novo: int) -> int:
	if novo > antigo:
		return restantes + (novo - antigo)
	return mini(restantes, novo)


## Escudo no meio da câmara (R9): sobe → ganha a diferença; desce → não muda.
static func escudo_apos_mudar(escudo: int, antigo: int, novo: int) -> int:
	return escudo + maxi(novo - antigo, 0)


## Escudo no começo da câmara (R9): passa a valer [code]escudo_sala[/code] (substitui).
static func escudo_no_comeco_da_camara(escudo_sala: int) -> int:
	return escudo_sala


## Vida no começo da run (R9) = [code]vida_max[/code].
static func vida_no_comeco_da_run(vida_max: int) -> float:
	return float(vida_max)
