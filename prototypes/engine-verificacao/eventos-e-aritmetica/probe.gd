# PROTOTYPE - NOT FOR PRODUCTION (engine-verificacao)
extends SceneTree
## EX-0002-1/2, EX-0009-1 (headless). Saída "EX|".

func _initialize() -> void:
	print("EX|versao=%s debug=%s ds=%s cpu=%s" % [Engine.get_version_info().string, OS.is_debug_build(), DisplayServer.get_name(), OS.get_processor_name()])
	_float64()
	_tipos()
	for n: int in [20, 50, 100]:
		_custo(n)
	_filter_sem_tipo()
	quit()

func _float64() -> void:
	var a: float = 9007199254740992.0
	var b: float = a + 1.0
	var c: float = 9007199254740993.0
	var s: float = 0.1 + 0.2
	var pb := PackedByteArray(); pb.resize(8); pb.encode_double(0, s)
	pb.reverse()
	print("EX|f64 2^53+1==2^53 (soma)=%s  literal 2^53+1==2^53=%s  2^52+1!=2^52=%s" % [b == a, c == a, 4503599627370496.0 + 1.0 != 4503599627370496.0])
	print("EX|f64 0.1+0.2 bits=0x%s ==0.3:%s str=%s" % [pb.hex_encode(), s == 0.3, String.num(s, 17)])
	print("EX|f64 int(2^62)+1 exato=%s  max_int=%d" % [int(4611686018427387904) + 1 == 4611686018427387905, 9223372036854775807])

func _tipos() -> void:
	var lista: Array[EventoDoPasso] = []
	for i in 9:
		var e: EventoDoPasso
		match i % 3:
			0: e = EventoDano.new(); (e as EventoDano).valor = i
			1: e = EventoMorte.new()
			_: e = EventoEsquiva.new()
		e.passo = i
		lista.append(e)
	var danos: Array[EventoDano] = []
	for e: EventoDoPasso in lista:
		if e.tipo() == &"dano":
			danos.append(e as EventoDano)
	var tipados: Array[EventoDoPasso] = []
	tipados.assign(lista.filter(func(e: EventoDoPasso) -> bool: return e.tipo() == &"morte"))
	var errado: EventoMorte = lista[0] as EventoMorte
	print("EX|tipos append=%d do_tipo(dano)=%d soma_valor=%d filter+assign(morte)=%d as_errado_null=%s is_typed=%s builtin=%s" % [lista.size(), danos.size(), danos.reduce(func(acc: int, d: EventoDano) -> int: return acc + d.valor, 0), tipados.size(), errado == null, lista.is_typed(), lista.get_typed_class_name()])
	var instanciou: bool = true
	var base: Script = load("res://eventos/evento_do_passo.gd")
	print("EX|tipos base abstrata can_instantiate=%s is_abstract=%s" % [base.can_instantiate(), base.is_abstract()])

func _custo(n: int) -> void:
	const PASSOS: int = 10000
	var tempos := PackedInt64Array(); tempos.resize(PASSOS)
	var guarda: int = 0
	for p in PASSOS:
		var t0: int = Time.get_ticks_usec()
		var lista: Array[EventoDoPasso] = []
		for i in n:
			var e := EventoDano.new()
			e.passo = p
			e.valor = i
			lista.append(e)
		guarda += lista.size()
		lista.clear()
		tempos[p] = Time.get_ticks_usec() - t0
	tempos.sort()
	var soma: int = 0
	for t in tempos: soma += t
	print("EX|custo eventos/passo=%d passos=%d media_us=%.1f p50_us=%d p99_us=%d max_us=%d (guarda %d)" % [n, PASSOS, float(soma) / PASSOS, tempos[PASSOS / 2], tempos[int(PASSOS * 0.99)], tempos[PASSOS - 1], guarda])

func _filter_sem_tipo() -> void:
	var lista: Array[EventoDoPasso] = [EventoDano.new(), EventoMorte.new()]
	var bruto: Array = lista.filter(func(e: EventoDoPasso) -> bool: return true)
	print("EX|filter retorno is_typed=%s (vazio = sem tipo)" % bruto.is_typed())
	print("EX|filter atribuicao direta a Array[EventoDoPasso]: tentando...")
	var tipado: Array[EventoDoPasso] = lista.filter(func(e: EventoDoPasso) -> bool: return true)
	print("EX|filter atribuicao direta PASSOU tamanho=%d typed=%s" % [tipado.size(), tipado.is_typed()])
