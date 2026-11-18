class_name OpcoesDoHud
extends RefCounted
## Contêiner tipado das 12 opções de UI/Acessibilidade/Áudio/Vídeo (`story-007` e `story-009`),
## com validação de faixas, integração opcional com persistência e aviso `OPCOES_FALHA_GRAVAR`.

const ESCALA_HUD_MIN: float = 0.80
const ESCALA_HUD_MAX: float = 1.50
const MARGEM_SEGURA_PADRAO_PX: float = 48.0

# 12 opções governadas pelo HUD e Telas
var escala_hud: float = 1.00 # 0.80 .. 1.50 (suporta presets 0.85, 1.0, 1.25, 1.50 e contínuo 0.80..1.30)
var opacidade_hud: float = 1.00 # 0.50 .. 1.00
var alto_contraste: bool = false
var reduzir_movimento: bool = false
var reduzir_flashes: bool = false
var intensidade_tremor: float = 1.00 # 0.00 .. 1.00
var numeros_dano: StringName = &"ligado" # &"ligado", &"reduzido", &"desligado"
var aviso_vida_baixa: bool = true
var daltonismo: StringName = &"nenhum" # &"nenhum", &"deuteranopia", &"protanopia", &"tritanopia"
var intensidade_telegrafo: float = 1.00 # 1.00 .. 2.00
var mostrar_relogio_run: bool = false
var telemetria_ativa: bool = false

# Opções de Áudio e Vídeo para a Tela de Opções
var volume_master: float = 1.00
var volume_sfx: float = 0.80
var volume_musica: float = 0.80
var volume_ui: float = 0.80
var modo_janela: StringName = &"tela_cheia" # &"tela_cheia", &"janela", &"sem_borda"
var vsync_ativo: bool = true

var _ultimo_erro_gravacao: StringName = &""


func aplicar_dicionario(dados: Dictionary) -> void:
	if dados.has("escala_hud"):
		escala_hud = clampf(float(dados["escala_hud"]), ESCALA_HUD_MIN, ESCALA_HUD_MAX)
	if dados.has("opacidade_hud"):
		opacidade_hud = clampf(float(dados["opacidade_hud"]), 0.50, 1.00)
	if dados.has("alto_contraste"):
		alto_contraste = bool(dados["alto_contraste"])
	if dados.has("reduzir_movimento"):
		reduzir_movimento = bool(dados["reduzir_movimento"])
	if dados.has("reduzir_flashes"):
		reduzir_flashes = bool(dados["reduzir_flashes"])
	if dados.has("intensidade_tremor"):
		intensidade_tremor = clampf(float(dados["intensidade_tremor"]), 0.0, 1.0)
	if dados.has("numeros_dano"):
		var nd: StringName = StringName(dados["numeros_dano"])
		if nd == &"ligado" or nd == &"reduzido" or nd == &"desligado":
			numeros_dano = nd
	if dados.has("aviso_vida_baixa"):
		aviso_vida_baixa = bool(dados["aviso_vida_baixa"])
	if dados.has("daltonismo"):
		var d: StringName = StringName(dados["daltonismo"])
		if d == &"nenhum" or d == &"deuteranopia" or d == &"protanopia" or d == &"tritanopia":
			daltonismo = d
	if dados.has("intensidade_telegrafo"):
		intensidade_telegrafo = clampf(float(dados["intensidade_telegrafo"]), 1.0, 2.0)
	if dados.has("mostrar_relogio_run"):
		mostrar_relogio_run = bool(dados["mostrar_relogio_run"])
	if dados.has("telemetria_ativa"):
		telemetria_ativa = bool(dados["telemetria_ativa"])
	if dados.has("volume_master"):
		volume_master = clampf(float(dados["volume_master"]), 0.0, 1.0)
	if dados.has("volume_sfx"):
		volume_sfx = clampf(float(dados["volume_sfx"]), 0.0, 1.0)
	if dados.has("volume_musica"):
		volume_musica = clampf(float(dados["volume_musica"]), 0.0, 1.0)
	if dados.has("volume_ui"):
		volume_ui = clampf(float(dados["volume_ui"]), 0.0, 1.0)
	if dados.has("modo_janela"):
		var mj: StringName = StringName(dados["modo_janela"])
		if mj == &"tela_cheia" or mj == &"janela" or mj == &"sem_borda":
			modo_janela = mj
	if dados.has("vsync_ativo"):
		vsync_ativo = bool(dados["vsync_ativo"])


func exportar_dicionario() -> Dictionary:
	return {
		"escala_hud": escala_hud,
		"opacidade_hud": opacidade_hud,
		"alto_contraste": alto_contraste,
		"reduzir_movimento": reduzir_movimento,
		"reduzir_flashes": reduzir_flashes,
		"intensidade_tremor": intensidade_tremor,
		"numeros_dano": numeros_dano,
		"aviso_vida_baixa": aviso_vida_baixa,
		"daltonismo": daltonismo,
		"intensidade_telegrafo": intensidade_telegrafo,
		"mostrar_relogio_run": mostrar_relogio_run,
		"telemetria_ativa": telemetria_ativa,
		"volume_master": volume_master,
		"volume_sfx": volume_sfx,
		"volume_musica": volume_musica,
		"volume_ui": volume_ui,
		"modo_janela": modo_janela,
		"vsync_ativo": vsync_ativo,
	}


func gravar_em(gravador: Callable) -> bool:
	_ultimo_erro_gravacao = &""
	if not gravador.is_valid():
		return true
	var ok: bool = bool(gravador.call(exportar_dicionario()))
	if not ok:
		_ultimo_erro_gravacao = &"OPCOES_FALHA_GRAVAR"
	return ok


func ultimo_erro_gravacao() -> StringName:
	return _ultimo_erro_gravacao
