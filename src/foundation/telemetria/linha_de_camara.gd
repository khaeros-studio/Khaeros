## Estado em memória e montagem da linha `camara` da Telemetria local
## (GDD telemetria-local.md R4, R5, F1; ADR-0001; story telemetria-local/007).
##
## Contadores da câmara:
## [br]- zerados ao entrar na câmara (`camara_entrou`);
## [br]- `dano_recebido` soma a `vida_perdida` de cada `jogador_atingido`, sem descontar cura
## nem recuperação de `recusou_morte`, e ignorando o que o escudo absorveu (Combate R17);
## [br]- `abates` conta `inimigo_morreu` na câmara;
## [br]- `duracao_s = passos_vivos_em_Jogo / 60.0` (F1), arredondada para `casas_decimais_duracao` (2);
## [br]- num santuário (`tipo == "santuario"`), `dano_recebido` e `abates` saem sempre `0` (AC-TL-07);
## [br]- se `jogador_morreu` e `camara_limpa` chegarem no mesmo passo, vale a morte: sai **uma única**
## linha `camara` com `resultado = "morte"` (AC-TL-29).
##
## Exemplo:
## [codeblock]
## var c := LinhaDeCamara.new()
## c.abrir(0, 0, "combate", 80, 80, 120)
## c.registrar_passo_vivo()
## var d := c.fechar("limpa", 2)
## [/codeblock]
class_name LinhaDeCamara
extends RefCounted

const TIPO_SANTUARIO: String = "santuario"
const RESULTADO_LIMPA: String = "limpa"
const RESULTADO_MORTE: String = "morte"
const RESULTADO_ABANDONO: String = "abandono"

var aberta: bool = false
var indice: int = 0
var p: int = 0
var tipo_camara: String = "combate"
var ms_inicio: int = 0
var passos_vivos: int = 0
var vida_max: int = 80
var dano_recebido: int = 0
var abates: int = 0
var vida_fim: int = 80


## Abre uma nova câmara e zera os contadores (R5).
func abrir(p_indice: int, p_p: int, p_tipo: String, p_vida_max: int, p_vida_atual: int, p_ms_inicio: int) -> void:
	aberta = true
	indice = p_indice
	p = p_p
	tipo_camara = p_tipo
	ms_inicio = p_ms_inicio
	passos_vivos = 0
	vida_max = p_vida_max
	dano_recebido = 0
	abates = 0
	vida_fim = p_vida_atual if p_vida_atual >= 0 else p_vida_max


## Conta 1 passo vivo em estado `JOGO` (inclui hitstop, exclui Pausa, Bênção e Transição; R5, F1).
func registrar_passo_vivo(qtd: int = 1) -> void:
	if not aberta or qtd <= 0:
		return
	passos_vivos += qtd


## Registra dano de um `jogador_atingido`: soma `vida_perdida` sem descontar recuperação (R5).
func registrar_dano(vida_perdida: int, vida_restante: int = -1) -> void:
	if not aberta:
		return
	if tipo_camara != TIPO_SANTUARIO and vida_perdida > 0:
		dano_recebido += vida_perdida
	if vida_restante >= 0:
		vida_fim = vida_restante
	elif vida_perdida > 0:
		vida_fim = maxi(0, vida_fim - vida_perdida)


## Registra recuperação de `recusou_morte` na Vida final da câmara, sem descontar de `dano_recebido` (AC-TL-10).
func registrar_recusa_de_morte(vida_atual: int) -> void:
	if not aberta:
		return
	if vida_atual >= 0:
		vida_fim = vida_atual


## Registra 1 abate (`inimigo_morreu`) na câmara atual (R5).
func registrar_abate() -> void:
	if not aberta or tipo_camara == TIPO_SANTUARIO:
		return
	abates += 1


## Fecha a câmara atual e devolve o dicionário de campos específicos da linha `camara` (R4).
func fechar(resultado: String, casas_decimais: int = 2, p_vida_fim: int = -1) -> Dictionary:
	aberta = false
	var vf := p_vida_fim if p_vida_fim >= 0 else vida_fim
	if resultado == RESULTADO_MORTE:
		vf = 0
	var dano_out := 0 if tipo_camara == TIPO_SANTUARIO else dano_recebido
	var abates_out := 0 if tipo_camara == TIPO_SANTUARIO else abates
	return {
		"indice": indice,
		"p": p,
		"tipo": tipo_camara,
		"ms_inicio": ms_inicio,
		"duracao_s": calcular_duracao_s(passos_vivos, casas_decimais),
		"vida_max": vida_max,
		"dano_recebido": dano_out,
		"abates": abates_out,
		"vida_fim": vf,
		"resultado": resultado,
	}


## F1: `duracao_s = passos_vivos_em_Jogo / 60.0`, arredondada para `casas_decimais` (2).
## Ex.: 1 044 passos -> 17.40 s.
static func calcular_duracao_s(passos: int, casas_decimais: int = 2) -> float:
	var bruto := float(maxi(0, passos)) / float(OrquestradorDoPasso.PASSOS_POR_SEGUNDO)
	var casas := clampi(casas_decimais, 1, 3)
	var fator := pow(10.0, float(casas))
	return roundf(bruto * fator) / fator
