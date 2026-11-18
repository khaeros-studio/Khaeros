# PROTOTYPE - NOT FOR PRODUCTION (engine-verificacao)
extends SceneTree
## EX-0009-1/EX-0002-2 complementos: bits do literal 2^53+1 e instanciar a base @abstract.
func _hex(x: float) -> String:
	var pb := PackedByteArray(); pb.resize(8); pb.encode_double(0, x); pb.reverse(); return pb.hex_encode()
func _initialize() -> void:
	var lit: float = 9007199254740993.0
	var conv: float = float(9007199254740993)
	var txt: float = "9007199254740993".to_float()
	print("EX|f64 bits 2^53=%s literal(2^53+1)=%s float(int 2^53+1)=%s to_float=%s" % [_hex(9007199254740992.0), _hex(lit), _hex(conv), _hex(txt)])
	print("EX|abstrata: tentando EventoDoPasso.new() via script.new()...")
	var s: Script = load("res://eventos/evento_do_passo.gd")
	var o: Variant = s.new()
	print("EX|abstrata: resultado=%s" % str(o))
	quit()
