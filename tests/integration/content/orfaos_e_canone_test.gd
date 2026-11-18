extends GdUnitTestSuite
## Story conteudo-010 [I]: varredura de órfãos em `assets/data/`, verificação de
## tokens canônicos crus nos `.tres` e verificação de `.import` com `importer="keep"`
## (AC-04, AC-39, AC-45, AC-48).

const TOKENS_CANONICOS_PROIBIDOS: PackedStringArray = [
	"BLADE", "RESONANCE", "GUARDIAN", "VEIL", "TRANSMUTATION", "PACTS",
	"BEIRA_LIMIAR", "BEIRA_VEIO_INSTAVEL", "boss_anomalia_maior", "boss_guardiao_rito",
	"melee", "ranged", "charger", "projectile", "lunge", "bleed", "burn", "weak",
	"sanctuary", "fragments", "heal", "trial",
]


func test_ac04_nenhum_tres_orfao_em_assets_data() -> void:
	var manifesto := ResourceLoader.load("res://assets/data/content_catalog.tres") as ManifestoDoCatalogo
	assert_object(manifesto).is_not_null()
	var em_disco := VarreduraDeOrfaos.listar_tres_em_disco("res://assets/data")
	var orfaos := VarreduraDeOrfaos.verificar_orfaos(manifesto, em_disco)
	assert_array(orfaos).is_empty()


func test_ac39_nenhum_token_canonico_cru_gravado_nos_tres() -> void:
	var manifesto := ResourceLoader.load("res://assets/data/content_catalog.tres") as ManifestoDoCatalogo
	assert_object(manifesto).is_not_null()
	var re_token := RegEx.create_from_string("&?\"([A-Za-z0-9_]+)\"")
	var violacoes: PackedStringArray = []
	for caminho in manifesto.caminhos:
		var txt := FileAccess.get_file_as_string(caminho)
		for m in re_token.search_all(txt):
			var tok := m.get_string(1)
			if TOKENS_CANONICOS_PROIBIDOS.has(tok):
				violacoes.append("%s: token canônico cru '%s'" % [caminho, tok])
	assert_array(Array(violacoes)).is_empty()


func test_ac45_todos_os_csvs_em_canon_usam_importer_keep_sem_translation() -> void:
	var dir := DirAccess.open("res://assets/data/canon")
	assert_object(dir).is_not_null()
	for nome in dir.get_files():
		assert_bool(nome.ends_with(".translation")).is_false()
		if nome.ends_with(".csv"):
			var imp_path := "res://assets/data/canon/" + nome + ".import"
			assert_bool(FileAccess.file_exists(imp_path)).is_true()
			assert_str(FileAccess.get_file_as_string(imp_path)).contains("importer=\"keep\"")
