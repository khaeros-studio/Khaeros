extends SceneTree
## Harness de desempenho da carga do catálogo (AC-38, TR-conteudo-015; ADVISORY, sem
## assert de tempo). Grava um catálogo sintético de fábrica (~40 definições) em 5
## pastas distintas de user:// (cada carga é fria: nenhum caminho está no cache do
## ResourceLoader), mede carga total e validação com Time.get_ticks_usec e imprime a
## mediana. A meta vale para build de release no PC de medição; rodar no editor
## (debug) dá só uma referência.
##
## Uso: godot --headless --path . -s res://tests/performance/content/carga_do_catalogo_perf.gd

const RAIZ := "user://perf_conteudo"
const REPETICOES := 5
const COPIAS_DE_INIMIGOS := 24


class ArteSempre:
	extends VerificadorDeArte

	func existe(_caminho: String) -> bool:
		return true


func _init() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	for i in COPIAS_DE_INIMIGOS:
		var e := FabricasDeCatalogo.inimigo(StringName("eco_%02d" % i))
		itens.append(ItemDoCatalogo.new(&"enemy", "", itens.size(), e))
	var textos := FabricasDeCatalogo.textos_para(itens)
	var registros := FabricasDeCatalogo.registros()
	var cargas: Array[float] = []
	var validacoes: Array[float] = []
	for r in REPETICOES:
		var pasta := "%s/rodada_%d" % [RAIZ, r]
		DirAccess.make_dir_recursive_absolute(pasta)
		var m := ManifestoDoCatalogo.new()
		for item in itens:
			var c := "%s/%s_%s.tres" % [pasta, item.tipo, item.definicao.id]
			ResourceSaver.save(item.definicao.duplicate_deep(Resource.DEEP_DUPLICATE_ALL), c)
			m.acrescentar(item.tipo, c)
		ResourceSaver.save(m, pasta + "/content_catalog.tres")
	for r in REPETICOES:
		var pasta := "%s/rodada_%d" % [RAIZ, r]
		var v := ValidadorDeCatalogo.new(registros, textos, ArteSempre.new())
		var carregador := CarregadorDeCatalogo.new(v, RelatorAcumulador.new())
		var t0 := Time.get_ticks_usec()
		var ok := carregador.carregar(pasta + "/content_catalog.tres")
		var t1 := Time.get_ticks_usec()
		var lidos: Array[ItemDoCatalogo] = []
		var cat := carregador.catalogo()
		if cat != null:
			var pos := 0
			for tipo in cat.tipos():
				for d in cat.listar(tipo, true):
					lidos.append(ItemDoCatalogo.new(tipo, "", pos, d))
					pos += 1
		var t2 := Time.get_ticks_usec()
		v.validar(lidos)
		var t3 := Time.get_ticks_usec()
		cargas.append((t1 - t0) / 1000.0)
		validacoes.append((t3 - t2) / 1000.0)
		print("rodada %d: pronto=%s defs=%d carga_total_ms=%.3f validacao_ms=%.3f" % [r, ok, lidos.size(), cargas[r], validacoes[r]])
	cargas.sort()
	validacoes.sort()
	print("MEDIANA carga_total_ms=%.3f validacao_ms=%.3f (debug=%s)" % [cargas[REPETICOES / 2], validacoes[REPETICOES / 2], OS.is_debug_build()])
	_limpar(RAIZ)
	quit()


func _limpar(pasta: String) -> void:
	var d := DirAccess.open(pasta)
	if d == null:
		return
	for sub in d.get_directories():
		_limpar(pasta + "/" + sub)
	for f in d.get_files():
		d.remove(f)
	DirAccess.remove_absolute(pasta)
