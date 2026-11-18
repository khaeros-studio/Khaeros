# PROTOTYPE - NOT FOR PRODUCTION (engine-verificacao)
@abstract class_name EventoDoPasso extends RefCounted
## Base abstrata de evento do passo (réplica mínima do ADR-0002 para o experimento).
var passo: int = 0
## Tipo do evento; override tem de ter `return` explícito (regra 4.7).
@abstract func tipo() -> StringName
