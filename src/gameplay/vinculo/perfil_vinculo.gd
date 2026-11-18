class_name PerfilVinculo
extends PortaDeSecao
## Perfil persistido de Vínculo e pactos (GDD vinculo-e-pactos.md V1, V2, V30–V33;
## ADR-0013 §7, ADR-0015 §2).
##
## Implementa [PortaDeSecao] para serializar na seção [code][vinculo][/code] do [RepositorioDePerfil]:
## - [method escrever] devolve apenas [code]bool[/code], [code]int[/code], [code]String[/code],
##   [code]Array[/code] e [code]Dictionary[/code] (chaves [code]String[/code]), com as espécies
##   na ordem do manifesto;
## - [method ler] valida faixas, recalcula [code]nivel[/code] a partir de [code]vinculo_pontos[/code] (F3),
##   corrige apenas a chave afetada e emite o aviso [code]&"VP-S1"[/code] no máximo uma vez por chave;
## - [method campos_de_ids] devolve [code]["ultima_dupla", "encontro_pendente"][/code] (AC-VP-25).

const AVISO_VP_S1: StringName = &"VP-S1"
const VERSAO_CONTEUDO: int = 1
const MAX_RUNS_INICIADAS: int = 2147483647
const MAX_RUNS_SEM_ENCONTRO: int = 1000
const MAX_ENCONTROS_VISTOS: int = 1000000


## Registro de pacto e vínculo de uma espécie no perfil.
class EstadoEspecie:
	extends RefCounted
	var id: String
	var raridade: StringName
	var obsoleta: bool = false
	var pactuada: bool = false
	var vinculo_pontos: int = 0
	var nivel: int = 0
	var encontros_vistos: int = 0
	var encontros_bem_sucedidos: int = 0

	func _init(p_id: String, p_raridade: StringName = &"comum", p_obsoleta: bool = false) -> void:
		id = p_id
		raridade = p_raridade
		obsoleta = p_obsoleta

	func para_dicionario() -> Dictionary:
		return {
			"pactuada": pactuada,
			"vinculo_pontos": vinculo_pontos,
			"nivel": nivel,
			"encontros_vistos": encontros_vistos,
			"encontros_bem_sucedidos": encontros_bem_sucedidos,
		}


var versao: int = VERSAO_CONTEUDO
var primeiro_pacto_concedido: bool = false
var primeiro_encontro_visto: bool = false
var runs_pactos_iniciadas: int = 0
var runs_pactos_sem_encontro: int = 0
var encontro_pendente: Array[String] = []
var ultima_dupla: Array[String] = []

var _tuning: VinculoTuning
var _ordem_manifesto: Array[String] = []
var _defs_por_id: Dictionary[String, CurseDef] = {}
var _especies: Dictionary[String, EstadoEspecie] = {}
var _avisar: Callable = Callable()
var _avisos_log: Array[String] = []


func _init(especies_catalogo: Array[CurseDef] = [], tuning: VinculoTuning = null,
		avisar: Callable = Callable()) -> void:
	_tuning = tuning if tuning != null else VinculoTuning.new()
	if _tuning.limiares_nivel.is_empty():
		_tuning.limiares_nivel = PackedInt64Array([20, 50, 90, 140])
	if _tuning.nivel_max <= 0:
		_tuning.nivel_max = 5
	if _tuning.pontos_teto <= 0:
		_tuning.pontos_teto = 9999
	if _tuning.encontros_para_consentir.is_empty():
		_tuning.encontros_para_consentir = PackedInt64Array([1, 1, 2, 2, 1])
	_avisar = avisar
	if especies_catalogo.is_empty():
		_registrar_especies_padrao_mvp()
	else:
		for c: CurseDef in especies_catalogo:
			if c != null:
				var sid := String(c.id)
				_ordem_manifesto.append(sid)
				_defs_por_id[sid] = c
	_reiniciar_valores_padrao()


func _registrar_especies_padrao_mvp() -> void:
	const IDS_MVP: Array[String] = ["vulto_mudo", "espreitador_da_fenda", "baluarte_de_cinza", "soberano_do_limiar"]
	const RARS_MVP: Array[StringName] = [&"comum", &"refinado", &"raro", &"primordial"]
	for i: int in IDS_MVP.size():
		var c := CurseDef.new()
		c.id = StringName(IDS_MVP[i])
		c.raridade = RARS_MVP[i]
		_ordem_manifesto.append(IDS_MVP[i])
		_defs_por_id[IDS_MVP[i]] = c


func _reiniciar_valores_padrao() -> void:
	versao = VERSAO_CONTEUDO
	primeiro_pacto_concedido = false
	primeiro_encontro_visto = false
	runs_pactos_iniciadas = 0
	runs_pactos_sem_encontro = 0
	encontro_pendente.clear()
	ultima_dupla.clear()
	_especies.clear()
	for sid: String in _ordem_manifesto:
		var c: CurseDef = _defs_por_id[sid]
		_especies[sid] = EstadoEspecie.new(sid, c.raridade, c.obsoleto)


# --- PortaDeSecao (V30, V31, V33; AC-VP-24, AC-VP-25) ------------------------

func campos_de_ids() -> PackedStringArray:
	return PackedStringArray(["ultima_dupla", "encontro_pendente"])


func migrar_conteudo(_v_de: int, dados: Dictionary) -> Dictionary:
	return dados


func escrever() -> Dictionary:
	var esp_dict: Dictionary = {}
	for sid: String in _ordem_manifesto:
		if _especies.has(sid):
			esp_dict[sid] = _especies[sid].para_dicionario()
	var pend: Array = []
	for s: String in encontro_pendente:
		pend.append(String(s))
	var dup: Array = []
	for s: String in ultima_dupla:
		dup.append(String(s))
	return {
		"versao": int(versao),
		"primeiro_pacto_concedido": bool(primeiro_pacto_concedido),
		"primeiro_encontro_visto": bool(primeiro_encontro_visto),
		"runs_pactos_iniciadas": int(runs_pactos_iniciadas),
		"runs_pactos_sem_encontro": int(runs_pactos_sem_encontro),
		"encontro_pendente": pend,
		"ultima_dupla": dup,
		"especies": esp_dict,
	}


func ler(dados: Dictionary) -> void:
	_reiniciar_valores_padrao()
	_avisos_log.clear()
	if dados.is_empty():
		return

	var avisos_emitidos: Dictionary = {}

	# versao
	if dados.has("versao"):
		if typeof(dados["versao"]) == TYPE_INT and int(dados["versao"]) >= 1:
			versao = int(dados["versao"])
		else:
			_emitir_vp_s1("versao", avisos_emitidos)

	# bools
	if dados.has("primeiro_pacto_concedido"):
		if typeof(dados["primeiro_pacto_concedido"]) == TYPE_BOOL:
			primeiro_pacto_concedido = bool(dados["primeiro_pacto_concedido"])
		else:
			_emitir_vp_s1("primeiro_pacto_concedido", avisos_emitidos)

	if dados.has("primeiro_encontro_visto"):
		if typeof(dados["primeiro_encontro_visto"]) == TYPE_BOOL:
			primeiro_encontro_visto = bool(dados["primeiro_encontro_visto"])
		else:
			_emitir_vp_s1("primeiro_encontro_visto", avisos_emitidos)

	# ints globais
	if dados.has("runs_pactos_iniciadas"):
		if typeof(dados["runs_pactos_iniciadas"]) == TYPE_INT:
			var v: int = int(dados["runs_pactos_iniciadas"])
			if v < 0 or v > MAX_RUNS_INICIADAS:
				_emitir_vp_s1("runs_pactos_iniciadas", avisos_emitidos)
			runs_pactos_iniciadas = clampi(v, 0, MAX_RUNS_INICIADAS)
		else:
			_emitir_vp_s1("runs_pactos_iniciadas", avisos_emitidos)

	if dados.has("runs_pactos_sem_encontro"):
		if typeof(dados["runs_pactos_sem_encontro"]) == TYPE_INT:
			var v: int = int(dados["runs_pactos_sem_encontro"])
			if v < 0 or v > MAX_RUNS_SEM_ENCONTRO:
				_emitir_vp_s1("runs_pactos_sem_encontro", avisos_emitidos)
			runs_pactos_sem_encontro = clampi(v, 0, MAX_RUNS_SEM_ENCONTRO)
		else:
			_emitir_vp_s1("runs_pactos_sem_encontro", avisos_emitidos)

	# especies
	if dados.has("especies") and typeof(dados["especies"]) == TYPE_DICTIONARY:
		var d_esp: Dictionary = dados["especies"]
		for sid: String in _ordem_manifesto:
			if not d_esp.has(sid):
				continue
			if typeof(d_esp[sid]) != TYPE_DICTIONARY:
				_emitir_vp_s1("especies." + sid, avisos_emitidos)
				continue
			_ler_estado_especie(sid, d_esp[sid] as Dictionary, avisos_emitidos)
	elif dados.has("especies"):
		_emitir_vp_s1("especies", avisos_emitidos)

	# Nenhuma espécie pactuada com primeiro_pacto_concedido = true -> força V3 na próxima escolha da Besta (V33)
	if primeiro_pacto_concedido and especies_pactuadas_ativas().is_empty():
		primeiro_pacto_concedido = false
		_emitir_vp_s1("primeiro_pacto_concedido", avisos_emitidos)

	# ultima_dupla (V33)
	if dados.has("ultima_dupla"):
		if typeof(dados["ultima_dupla"]) == TYPE_ARRAY:
			var bruta: Array = dados["ultima_dupla"]
			var limpa: Array[String] = []
			var mudou: bool = false
			for item in bruta:
				if typeof(item) != TYPE_STRING:
					mudou = true
					continue
				var s: String = item
				if s == "":
					if limpa.size() < 2:
						limpa.append("")
					else:
						mudou = true
					continue
				if not _especies.has(s) or not _especies[s].pactuada or _especies[s].obsoleta or limpa.has(s):
					mudou = true
					continue
				if limpa.size() < 2:
					limpa.append(s)
				else:
					mudou = true
			ultima_dupla = limpa
			if mudou:
				_emitir_vp_s1("ultima_dupla", avisos_emitidos)
		else:
			_emitir_vp_s1("ultima_dupla", avisos_emitidos)

	# encontro_pendente (V33)
	if dados.has("encontro_pendente"):
		if typeof(dados["encontro_pendente"]) == TYPE_ARRAY:
			var bruta_p: Array = dados["encontro_pendente"]
			var limpa_p: Array[String] = []
			var mudou_p: bool = false
			for item in bruta_p:
				if typeof(item) != TYPE_STRING:
					mudou_p = true
					continue
				var s: String = item
				if s == "" or not _especies.has(s):
					mudou_p = true
					continue
				var est: EstadoEspecie = _especies[s]
				if est.obsoleta or est.raridade == &"primordial" or est.pactuada:
					mudou_p = true
					continue
				if limpa_p.is_empty():
					limpa_p.append(s)
				else:
					mudou_p = true
			encontro_pendente = limpa_p
			if mudou_p:
				_emitir_vp_s1("encontro_pendente", avisos_emitidos)
		else:
			_emitir_vp_s1("encontro_pendente", avisos_emitidos)


func _ler_estado_especie(sid: String, d: Dictionary, avisos_emitidos: Dictionary) -> void:
	var est: EstadoEspecie = _especies[sid]
	if d.has("pactuada"):
		if typeof(d["pactuada"]) == TYPE_BOOL:
			est.pactuada = bool(d["pactuada"])
		else:
			_emitir_vp_s1("especies.%s.pactuada" % sid, avisos_emitidos)

	var teto_pts: int = _tuning.pontos_teto if _tuning != null else 9999
	if d.has("vinculo_pontos"):
		if typeof(d["vinculo_pontos"]) == TYPE_INT:
			var pts: int = int(d["vinculo_pontos"])
			if pts < 0 or pts > teto_pts:
				_emitir_vp_s1("especies.%s.vinculo_pontos" % sid, avisos_emitidos)
			est.vinculo_pontos = clampi(pts, 0, teto_pts)
		else:
			_emitir_vp_s1("especies.%s.vinculo_pontos" % sid, avisos_emitidos)

	var nivel_f3: int = PontosDeVinculo.calcular_nivel(est.pactuada, est.vinculo_pontos, _tuning)
	if d.has("nivel"):
		if typeof(d["nivel"]) == TYPE_INT:
			var n_lido: int = int(d["nivel"])
			if n_lido != nivel_f3:
				_emitir_vp_s1("especies.%s.nivel" % sid, avisos_emitidos)
		else:
			_emitir_vp_s1("especies.%s.nivel" % sid, avisos_emitidos)
	est.nivel = nivel_f3

	if d.has("encontros_vistos"):
		if typeof(d["encontros_vistos"]) == TYPE_INT:
			var ev: int = int(d["encontros_vistos"])
			if ev < 0 or ev > MAX_ENCONTROS_VISTOS:
				_emitir_vp_s1("especies.%s.encontros_vistos" % sid, avisos_emitidos)
			est.encontros_vistos = clampi(ev, 0, MAX_ENCONTROS_VISTOS)
		else:
			_emitir_vp_s1("especies.%s.encontros_vistos" % sid, avisos_emitidos)

	if d.has("encontros_bem_sucedidos"):
		if typeof(d["encontros_bem_sucedidos"]) == TYPE_INT:
			var eb: int = int(d["encontros_bem_sucedidos"])
			if eb < 0 or eb > est.encontros_vistos:
				_emitir_vp_s1("especies.%s.encontros_bem_sucedidos" % sid, avisos_emitidos)
			est.encontros_bem_sucedidos = clampi(eb, 0, est.encontros_vistos)
		else:
			_emitir_vp_s1("especies.%s.encontros_bem_sucedidos" % sid, avisos_emitidos)


func _emitir_vp_s1(chave: String, avisos_emitidos: Dictionary) -> void:
	if avisos_emitidos.has(chave):
		return
	avisos_emitidos[chave] = true
	_avisos_log.append(chave)
	if _avisar.is_valid():
		_avisar.call(AVISO_VP_S1, chave)


# --- Consultas e mutações de domínio (usadas apenas pelo Vínculo) ------------

func avisos_vp_s1() -> Array[String]:
	return _avisos_log.duplicate()


func estado_de(especie_id: StringName) -> EstadoEspecie:
	return _especies.get(String(especie_id), null)


func definicao_de(especie_id: StringName) -> CurseDef:
	return _defs_por_id.get(String(especie_id), null)


func ordem_manifesto() -> Array[StringName]:
	var out: Array[StringName] = []
	for sid: String in _ordem_manifesto:
		out.append(StringName(sid))
	return out


func especies_pactuadas_ativas() -> Array[StringName]:
	var out: Array[StringName] = []
	for sid: String in _ordem_manifesto:
		var est: EstadoEspecie = _especies[sid]
		if est.pactuada and not est.obsoleta:
			out.append(StringName(sid))
	return out


func especies_regulares_nao_pactuadas() -> Array[StringName]:
	var out: Array[StringName] = []
	for sid: String in _ordem_manifesto:
		var est: EstadoEspecie = _especies[sid]
		if not est.obsoleta and est.raridade != &"primordial" and not est.pactuada:
			out.append(StringName(sid))
	return out


func especies_regulares_pactuadas() -> Array[StringName]:
	var out: Array[StringName] = []
	for sid: String in _ordem_manifesto:
		var est: EstadoEspecie = _especies[sid]
		if not est.obsoleta and est.raridade != &"primordial" and est.pactuada:
			out.append(StringName(sid))
	return out


## Registra o pacto inicial ou novo de [param especie_id] (nível 1, 0 pontos).
func registrar_pacto_novo(especie_id: StringName) -> void:
	var sid := String(especie_id)
	if not _especies.has(sid):
		return
	var est: EstadoEspecie = _especies[sid]
	est.pactuada = true
	est.vinculo_pontos = maxi(0, est.vinculo_pontos)
	est.nivel = PontosDeVinculo.calcular_nivel(true, est.vinculo_pontos, _tuning)
	if encontro_pendente.has(sid):
		encontro_pendente.erase(sid)


## Soma [param pontos_run] ao perfil de [param especie_id] e recalcula o nível (V20, F3).
## Devolve [code]true[/code] se subiu de nível.
func somar_pontos_e_recalcular(especie_id: StringName, pontos_run: int) -> bool:
	var sid := String(especie_id)
	if not _especies.has(sid) or pontos_run <= 0:
		return false
	var est: EstadoEspecie = _especies[sid]
	var nivel_antes: int = est.nivel
	est.vinculo_pontos = PontosDeVinculo.somar_com_teto(est.vinculo_pontos, pontos_run, _tuning)
	est.nivel = PontosDeVinculo.calcular_nivel(est.pactuada, est.vinculo_pontos, _tuning)
	return est.nivel > nivel_antes


## Converte o estado atual para [EstadoInicialDaRun.PerfilDeVinculo] (V40, Telemetria AC-TL-34).
func para_estado_inicial_rng() -> EstadoInicialDaRun.PerfilDeVinculo:
	var pv := EstadoInicialDaRun.PerfilDeVinculo.new()
	for sid: String in _ordem_manifesto:
		var est: EstadoEspecie = _especies[sid]
		if est.pactuada and not est.obsoleta:
			pv.especies_pactuadas.append(StringName(sid))
			pv.niveis.append(est.nivel)
	pv.encontro_pendente = not encontro_pendente.is_empty()
	pv.primeiro_encontro_visto = primeiro_encontro_visto
	pv.runs_pactos_sem_encontro = runs_pactos_sem_encontro
	return pv
