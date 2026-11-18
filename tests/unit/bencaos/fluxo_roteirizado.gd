class_name FluxoRoteirizado
extends FluxoRng
## Dublê de FluxoRng: cada avanço devolve o próximo u de um roteiro (reais em [0, 1)
## convertidos para u32), passando pelas operações reais F3/F4/F7. Conta o consumo.
## Roteiro esgotado devolve 0.

var _roteiro: Array[float] = []
var consumidos: int = 0


func _init(roteiro: Array[float]) -> void:
	super(0, null)
	_roteiro = roteiro.duplicate()


func _avancar() -> int:
	var u: float = _roteiro[consumidos] if consumidos < _roteiro.size() else 0.0
	consumidos += 1
	return int(u * RngAritmetica.DOIS_A_32)
