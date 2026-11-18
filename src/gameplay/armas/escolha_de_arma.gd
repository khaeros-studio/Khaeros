class_name EscolhaDeArma
extends RefCounted
## Lógica de escolha da arma antes da run, pré-seleção, gravação de `ultima_arma` em
## `user://preferencias.cfg` e modo de build de playtest
## (GDD `design/gdd/armas-das-doutrinas.md` R4, Edge Cases; Story 005, Story 007;
## AC-AR-08, AC-AR-09, AC-AR-11, AC-AR-12, AC-AR-39; ADR-0012 §11, ADR-0013).
##
## Separada da vista (`Control`): recebe um [ArmazemDeArquivos] injetado (ou null/Nulo no
## build de playtest), monta os dados das cartas (`CartaView` / `DadosDaCarta` em dicionário)
## com o rótulo de velocidade ("lenta", "média", "rápida") e o aviso da Besta sem Maldição,
## e só grava `user://preferencias.cfg` ao confirmar fora de playtest.

const CAMINHO_PREFERENCIAS: String = "user://preferencias.cfg"
const SECAO_ARMAS: String = "armas"
const CHAVE_ULTIMA_ARMA: String = "ultima_arma"
const ID_PADRAO_PRIMEIRA_VEZ: StringName = &"lamina"
const AVISO_BESTA_SEM_MALDICAO: StringName = &"ARMA_PACTOS_AVISO_SEM_MALDICAO"
const TEXTO_AVISO_BESTA_PADRAO: String = "sem Maldição: o Chamado não responde"

var _armas: Array[WeaponDef] = []
var _tuning: ArmasTuning
var _armazem: ArmazemDeArquivos
var _build_playtest: bool = false
var _selecionada: StringName = &""
var _confirmada: StringName = &""
var _estado: ArmaDaRun.Estado = ArmaDaRun.Estado.ESCOLHENDO
var _avisos_debug: PackedStringArray = PackedStringArray()
var _leituras: int = 0
var _gravacoes: int = 0


## Inicializa e abre a escolha (R4). Se [param build_playtest] for verdadeiro, não lê nem
## grava o arquivo e nenhuma carta vem pré-selecionada (`_selecionada == &""`).
func _init(armas: Array[WeaponDef], armazem: ArmazemDeArquivos = null,
		build_playtest: bool = false, tuning: ArmasTuning = null) -> void:
	_armas = armas.duplicate()
	_armazem = armazem
	_build_playtest = build_playtest
	_tuning = tuning if tuning != null else FabricaDeArmas.tuning()
	abrir_escolha()


## Abre (ou reabre na próxima run) o estado `ESCOLHENDO`.
func abrir_escolha() -> void:
	_estado = ArmaDaRun.Estado.ESCOLHENDO
	_confirmada = &""
	_avisos_debug.clear()
	if _armas.is_empty():
		_selecionada = &""
		return
	if _build_playtest:
		_selecionada = &""
		return
	_selecionada = _resolver_pre_selecao()


## Arma atualmente selecionada na tela (`&""` no build de playtest antes de o jogador escolher).
func selecionada() -> StringName:
	return _selecionada


## Arma confirmada para a run (`&""` enquanto em `ESCOLHENDO` ou após `cancelar_esc`).
func confirmada() -> StringName:
	return _confirmada


## Estado atual (`ESCOLHENDO`, `EQUIPADA` ou `ENCERRADA`).
func estado() -> ArmaDaRun.Estado:
	return _estado


## Avisos de debug gerados na última abertura (conjunto exato para AC-AR-08 e AC-AR-39).
func avisos_debug() -> PackedStringArray:
	return _avisos_debug.duplicate()


## Quantidade de leituras feitas no arquivo de preferências.
func leituras_preferencias() -> int:
	return _leituras


## Quantidade de gravações feitas no arquivo de preferências.
func gravacoes_preferencias() -> int:
	return _gravacoes


## Move a seleção para [param id_arma] (se existir na lista de armas disponíveis).
func selecionar(id_arma: StringName) -> bool:
	if _estado != ArmaDaRun.Estado.ESCOLHENDO:
		return false
	if _encontrar_arma(id_arma) == null:
		return false
	_selecionada = id_arma
	return true


## Move a seleção pelo índice do cartão (`0..cartas_count()-1`).
func selecionar_indice(indice: int) -> bool:
	if indice < 0 or indice >= _armas.size():
		return false
	return selecionar(_armas[indice].id)


## Confirma a arma selecionada (R4, AC-AR-09, AC-AR-39):
## bloqueado se nenhuma arma estiver selecionada; fora de playtest, grava `ultima_arma`
## em `user://preferencias.cfg` e transiciona para `EQUIPADA`.
func confirmar() -> bool:
	if _estado != ArmaDaRun.Estado.ESCOLHENDO:
		return false
	if _selecionada == &"" or _encontrar_arma(_selecionada) == null:
		return false
	_confirmada = _selecionada
	_estado = ArmaDaRun.Estado.EQUIPADA
	if not _build_playtest and _armazem != null:
		_gravar_ultima_arma(_confirmada)
	return true


## Cancela a tela de escolha (Esc; AC-AR-09): não grava nada e não entra em `EQUIPADA`.
func cancelar_esc() -> void:
	if _estado != ArmaDaRun.Estado.ESCOLHENDO:
		return
	_confirmada = &""


## Notifica fim da run (`jogador_morreu` ou vitória; AC-AR-10) -> `ENCERRADA`.
func encerrar_run() -> void:
	if _estado == ArmaDaRun.Estado.EQUIPADA:
		_estado = ArmaDaRun.Estado.ENCERRADA


## Rótulo relativo de velocidade (R4, AC-AR-12): `< vel_media_min` (360) = `"lenta"`,
## `360..400` = `"média"`, `> 400` = `"rápida"`.
func rotulo_velocidade(velocidade_pxs: float) -> String:
	if velocidade_pxs < _tuning.vel_media_min - 1e-9:
		return "lenta"
	if velocidade_pxs <= _tuning.vel_media_max + 1e-9:
		return "média"
	return "rápida"


## Monta os dados das cartas para a tela de escolha (Story 007, AC-AR-12, AC-TB-36/37):
## nome canônico, Doutrina, Vida, velocidade como rótulo ("média"), nomes e descrições
## `<chave_nome>_DESC` do Ataque e do Especial, estado `selecionada` e `aviso_texto` na Besta
## quando [param tem_maldicao_pactuada] é falso.
func montar_cartas_para_tela(tem_maldicao_pactuada: bool = true,
		tabela_traducao: Dictionary = {}) -> Array[Dictionary]:
	var fonte_txt: Dictionary = FabricaDeArmas.NOMES_CANONICOS.duplicate()
	for k: Variant in FabricaDeArmas.DESCRICOES_CANONICAS.keys():
		fonte_txt[k] = FabricaDeArmas.DESCRICOES_CANONICAS[k]
	for k: Variant in tabela_traducao.keys():
		fonte_txt[k] = tabela_traducao[k]

	var out: Array[Dictionary] = []
	for w: WeaponDef in _armas:
		var chave_atk_desc := StringName(String(w.ataque.chave_nome) + "_DESC")
		var chave_esp_desc := StringName(String(w.especial.chave_nome) + "_DESC")
		var aviso_chave: StringName = &""
		var aviso_txt: String = ""
		if w.id == FabricaDeArmas.ID_PACTOS and not tem_maldicao_pactuada:
			aviso_chave = AVISO_BESTA_SEM_MALDICAO
			aviso_txt = String(fonte_txt.get(AVISO_BESTA_SEM_MALDICAO, TEXTO_AVISO_BESTA_PADRAO))
		out.append({
			&"modo": &"arma",
			&"id": w.id,
			&"doutrina": w.doutrina,
			&"chave_nome": w.chave_nome,
			&"nome": String(fonte_txt.get(w.chave_nome, String(w.chave_nome))),
			&"vida_max": w.vida_max,
			&"velocidade_rotulo": rotulo_velocidade(w.velocidade),
			&"ataque_chave_nome": w.ataque.chave_nome,
			&"ataque_nome": String(fonte_txt.get(w.ataque.chave_nome, String(w.ataque.chave_nome))),
			&"ataque_chave_desc": chave_atk_desc,
			&"ataque_desc": String(fonte_txt.get(chave_atk_desc, "")),
			&"especial_chave_nome": w.especial.chave_nome,
			&"especial_nome": String(fonte_txt.get(w.especial.chave_nome, String(w.especial.chave_nome))),
			&"especial_chave_desc": chave_esp_desc,
			&"especial_desc": String(fonte_txt.get(chave_esp_desc, "")),
			&"selecionada": w.id == _selecionada,
			&"aviso_chave": aviso_chave,
			&"aviso_texto": aviso_txt,
		})
	return out


func _encontrar_arma(id_arma: StringName) -> WeaponDef:
	for w: WeaponDef in _armas:
		if w.id == id_arma:
			return w
	return null


func _id_fallback() -> StringName:
	if _encontrar_arma(ID_PADRAO_PRIMEIRA_VEZ) != null:
		return ID_PADRAO_PRIMEIRA_VEZ
	return _armas[0].id if not _armas.is_empty() else &""


func _resolver_pre_selecao() -> StringName:
	var padrao: StringName = _id_fallback()
	if _armazem == null:
		return padrao
	_leituras += 1
	var leitura: LeituraDeArquivo = _armazem.ler_texto(CAMINHO_PREFERENCIAS)
	if not leitura.existe:
		return padrao
	if not leitura.ok:
		_avisos_debug.append("preferencias.cfg corrompido: falha de leitura")
		return padrao
	var cfg := ConfigFile.new()
	var err: Error = cfg.parse(leitura.texto)
	if err != OK:
		_avisos_debug.append("preferencias.cfg corrompido: erro de sintaxe (%d)" % err)
		return padrao
	if not cfg.has_section_key(SECAO_ARMAS, CHAVE_ULTIMA_ARMA):
		_avisos_debug.append("preferencias.cfg corrompido: chave [armas] ultima_arma ausente")
		return padrao
	var valor: Variant = cfg.get_value(SECAO_ARMAS, CHAVE_ULTIMA_ARMA, "")
	var id_lido := StringName(String(valor))
	if id_lido == &"" or _encontrar_arma(id_lido) == null:
		_avisos_debug.append("arma desconhecida em preferencias.cfg: '%s'" % String(id_lido))
		return padrao
	return id_lido


func _gravar_ultima_arma(id_arma: StringName) -> void:
	var texto := "[%s]\n%s=\"%s\"\n" % [SECAO_ARMAS, CHAVE_ULTIMA_ARMA, String(id_arma)]
	_gravacoes += 1
	_armazem.gravar_atomico(CAMINHO_PREFERENCIAS, texto)
