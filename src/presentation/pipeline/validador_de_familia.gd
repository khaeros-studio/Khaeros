class_name ValidadorDeFamilia
extends RefCounted
## Validador de materiais e famílias das camadas de mundo (GDD pipeline-visual.md R1, R5b,
## AC-PV-05, AC-PV-88; ADR-0011 §4, §8).
## Confere a lista fechada dos 9 shaders de mundo/UI, as marcas de família e acusa qualquer
## nó `tel_sdf` cujo dono pertença à facção do jogador (Maldição, aliado, invocação).

const LISTA_FECHADA_SHADERS: Dictionary = {
	&"amb_sprite": &"amb_graded",
	&"amb_mascara": &"amb_graded",
	&"amb_aditivo": &"amb_graded",
	&"char_sprite": &"char_tint",
	&"char_grupo": &"char_tint",
	&"tel_sdf": &"sem_grading",
	&"traco_sdf": &"sem_grading",
	&"vfx_sprite": &"sem_grading",
	&"ui": &"sem_grading",
}

const SHADERS_DE_PASSE: Array[StringName] = [
	&"pass_wipe",
	&"pass_morte",
	&"pass_vinheta",
]

const FACCOES_DO_JOGADOR: Array[StringName] = [
	&"jogador",
	&"maldicao",
	&"aliado",
	&"invocacao",
]


static func familia_do_caminho(caminho_shader: String) -> StringName:
	if caminho_shader.is_empty():
		return &""
	if caminho_shader.contains("/amb_graded/") or caminho_shader.contains("/mundo/"):
		return &"amb_graded"
	if caminho_shader.contains("/char_tint/") or caminho_shader.contains("/entidades/"):
		return &"char_tint"
	if caminho_shader.contains("/sem_grading/") or caminho_shader.contains("/ui/"):
		return &"sem_grading"
	return &""


static func inclui_marca_da_familia(codigo_shader: String, familia_esperada: StringName) -> bool:
	match familia_esperada:
		&"amb_graded":
			return codigo_shader.contains("familias/amb_graded.gdshaderinc")
		&"char_tint":
			return codigo_shader.contains("familias/char_tint.gdshaderinc")
		&"sem_grading":
			return codigo_shader.contains("familias/sem_grading.gdshaderinc")
	return false


## Percorre os `CanvasItem`s das nove camadas de mundo e devolve os caminhos dos nós inválidos:
## - sem `ShaderMaterial` ou sem `shader`;
## - com shader que não inclui o `.gdshaderinc` de uma das três famílias;
## - com `tel_sdf` cujo metadado `faccao_dono` pertence à facção do jogador (AC-PV-88).
## Os passes de tela em `pós` (layer 50) ficam de fora. Em release (`debug_ativo = false`), não lista nada.
static func validar_arvore_mundo(camadas: CamadasDoMundo, debug_ativo: bool = true) -> PackedStringArray:
	var violacoes := PackedStringArray()
	if not debug_ativo or camadas == null:
		return violacoes

	for idx_camada in CamadasDoMundo.CAMADAS_DE_MUNDO:
		var raiz_camada := camadas.raiz(idx_camada as CamadasDoMundo.Camada)
		_percorrer_filhos(raiz_camada, violacoes)
	return violacoes


static func _percorrer_filhos(no: Node, violacoes: PackedStringArray) -> void:
	for filho: Node in no.get_children():
		if filho.name == CamadasDoMundo.NOME_COR_DE_FUNDO or filho.name == &"AneisDeAreaVfx":
			_percorrer_filhos(filho, violacoes)
			continue
		if filho is CanvasItem and not _eh_ancora_pura(filho):
			var item := filho as CanvasItem
			var motivo := validar_canvas_item(item)
			if not motivo.is_empty():
				violacoes.append(String(item.get_path()))
		_percorrer_filhos(filho, violacoes)


static func _eh_ancora_pura(no: Node) -> bool:
	return no.get_class() == "Node2D" and String(no.name).begins_with("Ancora_")


static func validar_canvas_item(item: CanvasItem) -> String:
	if item == null:
		return "item nulo"
	var mat := item.material as ShaderMaterial
	if mat == null or mat.shader == null:
		return "sem ShaderMaterial"
	var codigo := mat.shader.code
	var caminho := mat.shader.resource_path
	var tem_familia := (
		inclui_marca_da_familia(codigo, &"amb_graded")
		or inclui_marca_da_familia(codigo, &"char_tint")
		or inclui_marca_da_familia(codigo, &"sem_grading")
	)
	if not tem_familia:
		return "shader sem marca de família: %s" % caminho

	var eh_tel_sdf := caminho.ends_with("tel_sdf.gdshader") or codigo.contains("uniform float contorno_secundario_raio")
	if eh_tel_sdf and item.has_meta(&"faccao_dono"):
		var faccao := StringName(str(item.get_meta(&"faccao_dono")))
		if FACCOES_DO_JOGADOR.has(faccao):
			return "AC-PV-88: tel_sdf proibido para facção do jogador (%s)" % faccao
	return ""


## Valida diretamente se um pedido de telégrafo pertence a uma facção permitida (R5b, AC-PV-88).
static func validar_dono_telegrafo(faccao_dono: StringName) -> bool:
	return not FACCOES_DO_JOGADOR.has(faccao_dono)
