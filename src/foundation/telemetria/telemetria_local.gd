## Consumidor puro de eventos e gravador JSON Lines da Telemetria local
## (GDD telemetria-local.md R1–R13, R4-P, F1–F5; ADR-0002, ADR-0013 §5).
##
## Características principais:
## [br]- **Só escuta** (`ConsumidorDeEventos`): nunca altera estado de jogo, nunca emite eventos,
## nunca chama método de escrita de nenhum sistema do jogo e **o jogo nunca lê o arquivo `.jsonl`** (AC-TL-14, AC-TL-30);
## [br]- Máquina de 6 estados do GDD (`DESLIGADA`, `ARMADA`, `ABERTA`, `PARADA_POR_FALHA`,
## `PARADA_POR_LIMITE`, `ENCERRADA`);
## [br]- Um arquivo `.jsonl` por sessão em `user://telemetria/sessao-AAAAMMDD-HHMMSS[-N].jsonl`,
## mantido aberto via `EscritorDeLinhas` sobre `ArmazemDeArquivos`, com `escrever_linha` + `descarregar`
## a cada linha (AC-TL-01, AC-TL-03, AC-TL-23);
## [br]- Campos comuns em toda linha (`t`, `n`, `ms`, `run`, e `schema = 2` apenas na linha `n = 0`, AC-TL-02, AC-TL-34);
## [br]- Limite de bytes (`max_bytes_sessao`) verificado em memória com reserva de 512 B para
## `sessao_encerrada` (`limite`), retenção das últimas `max_sessoes` (20) sessões e "Apagar dados"
## preservando o arquivo aberto da sessão em curso (AC-TL-20, AC-TL-21, AC-TL-26, AC-TL-32);
## [br]- Medição de custo por linha e por passo em microssegundos (`pior_passo_us()`), registrando
## `TL2` quando ultrapassa `orcamento_linha_ms` (1 ms) ou `orcamento_passo_ms` (3 ms), e `Restart Rate`
## da sessão (`taxa_reinicio_sessao()`, razão de runs com `motivo == "abandono"` pelo total de runs encerradas).
##
## Não é thread-safe: uso exclusivo na thread principal.
##
## Exemplo:
## [codeblock]
## var tel := TelemetriaLocal.new(armazem, relogio, tuning, avisos, "0.1.0", "1B4E", true)
## tel.iniciar_sessao()
## tel.consumir(lote_de_eventos)
## tel.encerrar_sessao()
## [/codeblock]
class_name TelemetriaLocal
extends ConsumidorDeEventos

## Estados da máquina de estados da Telemetria (GDD §States and Transitions).
enum Estado {
	DESLIGADA,
	ARMADA,
	ABERTA,
	PARADA_POR_FALHA,
	PARADA_POR_LIMITE,
	ENCERRADA,
}

## Versão do esquema JSONL (Schema 2 com emenda Pactos, story 009).
const SCHEMA_ATUAL: int = 2
## Reserva mínima em bytes para garantir a escrita de `sessao_encerrada` (`limite`) (R9).
const RESERVA_LIMITE_BYTES: int = 512
## Pasta padrão de telemetria em `user://`.
const PASTA_PADRAO: String = "user://telemetria"

## Valores padrão do `TelemetriaTuning` quando não injetado.
const PADRAO_MAX_BYTES_SESSAO: int = 2097152
const PADRAO_MAX_SESSOES: int = 20
const PADRAO_ORCAMENTO_LINHA_MS: float = 1.0
const PADRAO_ORCAMENTO_PASSO_MS: float = 3.0
const PADRAO_CASAS_DECIMAIS_DURACAO: int = 2

var _armazem: ArmazemDeArquivos
var _relogio: RelogioDeSessao
var _avisos: RelatorDeAvisosTelemetria
var _pasta: String = PASTA_PADRAO
var _versao_jogo: String = "0.1.0"
var _impressao_curta: String = "0000"

var _max_bytes_sessao: int = PADRAO_MAX_BYTES_SESSAO
var _max_sessoes: int = PADRAO_MAX_SESSOES
var _orcamento_linha_ms: float = PADRAO_ORCAMENTO_LINHA_MS
var _orcamento_passo_ms: float = PADRAO_ORCAMENTO_PASSO_MS
var _casas_decimais_duracao: int = PADRAO_CASAS_DECIMAIS_DURACAO

var _estado: Estado = Estado.DESLIGADA
var _ligada: bool = true
var _escritor: EscritorDeLinhas = null
var _caminho_arquivo_atual: String = ""
var _bytes_escritos: int = 0
var _n_linha: int = 0
var _ultimo_ms: int = 0

# Estado da run e câmara em curso (apenas observação para telemetria)
var _indice_run_sessao: int = 0
var _em_run: bool = false
var _doutrina_atual: String = ""
var _camara: LinhaDeCamara = LinhaDeCamara.new()
var _ultimas_trocas_oferta: int = 0
var _fragmentos_por_origem: Dictionary = {}
var _caminho_da_run: Array = []

# Métricas de orçamento e Restart Rate (stories 004 e 010)
var _pior_linha_us: int = 0
var _pior_passo_us: int = 0
var _ultimo_passo_us: int = 0
var _runs_encerradas_sessao: int = 0
var _runs_abandonadas_sessao: int = 0


func _init(armazem: ArmazemDeArquivos, relogio: RelogioDeSessao, tuning: Resource = null,
		avisos: RelatorDeAvisosTelemetria = null, versao_jogo: String = "0.1.0",
		impressao_curta: String = "0000", ligada_inicial: bool = true,
		pasta: String = PASTA_PADRAO) -> void:
	_armazem = armazem
	_relogio = relogio
	_avisos = avisos if avisos != null else RelatorDeAvisosTelemetria.new()
	_versao_jogo = versao_jogo
	_impressao_curta = impressao_curta
	_ligada = ligada_inicial
	_pasta = pasta
	configurar_tuning(tuning)
	_estado = Estado.ARMADA if _ligada else Estado.DESLIGADA


## Aplica os valores do `TelemetriaTuning` validado (ou restaura os padrões se `null`).
func configurar_tuning(tuning: Resource) -> void:
	if tuning == null:
		_max_bytes_sessao = PADRAO_MAX_BYTES_SESSAO
		_max_sessoes = PADRAO_MAX_SESSOES
		_orcamento_linha_ms = PADRAO_ORCAMENTO_LINHA_MS
		_orcamento_passo_ms = PADRAO_ORCAMENTO_PASSO_MS
		_casas_decimais_duracao = PADRAO_CASAS_DECIMAIS_DURACAO
		return
	var mb: Variant = tuning.get(&"max_bytes_sessao")
	if mb != null and int(mb) > 0:
		_max_bytes_sessao = int(mb)
	var ms: Variant = tuning.get(&"max_sessoes")
	if ms != null and int(ms) > 0:
		_max_sessoes = int(ms)
	var ol: Variant = tuning.get(&"orcamento_linha_ms")
	if ol != null and float(ol) > 0.0:
		_orcamento_linha_ms = float(ol)
	var op: Variant = tuning.get(&"orcamento_passo_ms")
	if op != null and float(op) > 0.0:
		_orcamento_passo_ms = float(op)
	var cd: Variant = tuning.get(&"casas_decimais_duracao")
	if cd != null and int(cd) > 0:
		_casas_decimais_duracao = int(cd)


## Abre a sessão na inicialização do jogo (R2). Se `_ligada == false`, permanece em `DESLIGADA`
## sem tocar o armazém (AC-TL-15).
func iniciar_sessao() -> bool:
	if not _ligada:
		_estado = Estado.DESLIGADA
		return false
	return _abrir_arquivo_de_sessao()


## Encerra a sessão ao sair do jogo pelo menu (R2, Edge Cases).
## Se houver uma câmara aberta em curso, grava `camara` com `resultado = "abandono"` antes de
## `sessao_encerrada` (`motivo = "saida"`), sem gravar `run_encerrada`.
func encerrar_sessao() -> void:
	if _estado == Estado.ABERTA:
		if _camara.aberta:
			var dados_camara := _camara.fechar(LinhaDeCamara.RESULTADO_ABANDONO, _casas_decimais_duracao)
			_gravar_evento(&"camara", dados_camara)
		_fechar_com_sessao_encerrada("saida")
	_fechar_escritor()
	_estado = Estado.ENCERRADA


## R6 (AC-TL-15, AC-TL-16): liga ou desliga a telemetria durante a sessão.
## - Desligar em `ABERTA`: grava `sessao_encerrada` (`desligada`), fecha o arquivo e vai a `DESLIGADA`.
## - Ligar em `DESLIGADA` ou `PARADA_POR_LIMITE`: vai a `ARMADA` (abre novo arquivo na próxima `run_iniciada`).
## - Em `PARADA_POR_FALHA` ou `ENCERRADA`: religar não abre arquivo na sessão atual.
func definir_ligada(ligada: bool) -> void:
	if _ligada == ligada:
		return
	_ligada = ligada
	if not ligada:
		if _estado == Estado.ABERTA:
			_fechar_com_sessao_encerrada("desligada")
			_fechar_escritor()
		if _estado != Estado.PARADA_POR_FALHA and _estado != Estado.ENCERRADA:
			_estado = Estado.DESLIGADA
	else:
		if _estado == Estado.DESLIGADA or _estado == Estado.PARADA_POR_LIMITE:
			_estado = Estado.ARMADA


## R6 (AC-TL-26, AC-TL-32): apaga todos os `sessao-*.jsonl` da pasta após confirmação,
## preservando o arquivo da sessão aberta em curso e ignorando falhas com `TL1`.
func apagar_dados(confirmado: bool = true) -> int:
	if _armazem == null:
		return 0
	var aberto := _caminho_arquivo_atual if _estado == Estado.ABERTA else ""
	return RetencaoDeSessoes.apagar_dados(_armazem, _pasta, aberto, confirmado, _avisos)


## Consumidor puro de `EventosDoPasso` (ADR-0002): processa o lote do passo em ordem,
## resolvendo a precedência `jogador_morreu` > `camara_limpa` no mesmo passo (AC-TL-29) e
## medindo o custo total do passo em microssegundos (`pior_passo_us()`, AC-TL-25, TR-telemetria-012).
func consumir(eventos: Array[EventoDoPasso]) -> void:
	if eventos.is_empty():
		_ultimo_passo_us = 0
		return
	var t0_us: int = _relogio.agora_us() if _relogio != null else 0

	var morreu_neste_passo := false
	for e: EventoDoPasso in eventos:
		if e != null and e.tipo() == &"jogador_morreu":
			morreu_neste_passo = true
			break

	for e: EventoDoPasso in eventos:
		if e == null:
			continue
		_processar_evento(e, morreu_neste_passo)

	var t1_us: int = _relogio.agora_us() if _relogio != null else t0_us
	_ultimo_passo_us = maxi(0, t1_us - t0_us)
	if _ultimo_passo_us > _pior_passo_us:
		_pior_passo_us = _ultimo_passo_us
	var orc_passo_us := int(roundf(_orcamento_passo_ms * 1000.0))
	if _ultimo_passo_us > orc_passo_us:
		_avisos.registrar_tl2("passo excedeu orcamento: %d us > %d us" % [_ultimo_passo_us, orc_passo_us])


# --- Consultas de estado e métricas -----------------------------------------

func estado() -> Estado:
	return _estado


func esta_ligada() -> bool:
	return _ligada


func caminho_arquivo_atual() -> String:
	return _caminho_arquivo_atual


func bytes_escritos() -> int:
	return _bytes_escritos


func numero_linha_atual() -> int:
	return _n_linha


func indice_run_atual() -> int:
	return _indice_run_sessao if _em_run else 0


func total_runs_sessao() -> int:
	return _indice_run_sessao


func pior_linha_us() -> int:
	return _pior_linha_us


func pior_passo_us() -> int:
	return _pior_passo_us


func ultimo_passo_us() -> int:
	return _ultimo_passo_us


## Restart Rate da sessão: razão entre runs encerradas por `"abandono"` e total de runs encerradas.
func taxa_reinicio_sessao() -> float:
	if _runs_encerradas_sessao <= 0:
		return 0.0
	return float(_runs_abandonadas_sessao) / float(_runs_encerradas_sessao)


## Calcula o Restart Rate de uma lista de dicionários de linhas JSONL (para ferramentas/testes).
static func calcular_restart_rate(linhas_lidas: Array[Dictionary]) -> float:
	var encerradas := 0
	var abandonos := 0
	for l: Dictionary in linhas_lidas:
		if String(l.get("t", "")) == "run_encerrada":
			encerradas += 1
			var mot := String(l.get("motivo", ""))
			if mot.is_empty() and l.get("resumo") is Dictionary:
				mot = String((l["resumo"] as Dictionary).get("motivo", ""))
			if mot == "abandono":
				abandonos += 1
	if encerradas <= 0:
		return 0.0
	return float(abandonos) / float(encerradas)


# --- Processamento interno de eventos ---------------------------------------

func _processar_evento(e: EventoDoPasso, morreu_neste_passo: bool) -> void:
	var tipo := e.tipo()
	match tipo:
		&"run_iniciada":
			_ao_run_iniciada(e)
		&"camara_entrou":
			_ao_camara_entrou(e)
		&"passo_vivo":
			_camara.registrar_passo_vivo(1)
		&"jogador_atingido":
			var vp_var: Variant = e.get("vida_perdida")
			var vp: int = int(vp_var) if vp_var != null else 0
			var vr_var: Variant = e.get("vida_restante")
			var vr: int = int(vr_var) if vr_var != null else -1
			_camara.registrar_dano(vp, vr)
		&"recusou_morte":
			var va_var: Variant = e.get("vida_atual")
			_camara.registrar_recusa_de_morte(int(va_var) if va_var != null else -1)
		&"inimigo_morreu":
			_camara.registrar_abate()
		&"camara_limpa":
			if morreu_neste_passo:
				# R5 (AC-TL-29): morte e camara_limpa no mesmo passo -> vale a morte.
				return
			if _camara.aberta:
				var vf_var: Variant = e.get("vida_fim")
				var vf: int = int(vf_var) if vf_var != null else -1
				var dados := _camara.fechar(LinhaDeCamara.RESULTADO_LIMPA, _casas_decimais_duracao, vf)
				_gravar_evento(&"camara", dados)
		&"oferta_aberta":
			var dados_of := LinhasDeEventos.montar_oferta(e, _camara.indice, _avisos)
			if dados_of.get("trocas") != null:
				_ultimas_trocas_oferta = int(dados_of["trocas"])
			_gravar_evento(&"oferta", dados_of)
		&"oferta_trocada":
			var dados_ot := LinhasDeEventos.montar_oferta_trocada(e, _avisos)
			if dados_ot.get("trocas") != null:
				_ultimas_trocas_oferta = int(dados_ot["trocas"])
			_caminho_da_run.append({"tipo": "troca", "indice_camara": _camara.indice})
			_gravar_evento(&"oferta_trocada", dados_ot)
		&"bencao_tomada":
			var dados_bn := LinhasDeEventos.montar_bencao(e, _ultimas_trocas_oferta, _avisos)
			if dados_bn.get("trocas_restantes") != null:
				_ultimas_trocas_oferta = int(dados_bn["trocas_restantes"])
			_caminho_da_run.append({
				"tipo": "bencao",
				"indice_camara": _camara.indice,
				"id": dados_bn.get("id"),
			})
			_gravar_evento(&"bencao", dados_bn)
		&"porta_escolhida", &"porta":
			var dados_pt := LinhasDeEventos.montar_porta(e, _camara.indice, _avisos)
			_caminho_da_run.append({
				"tipo": "porta",
				"indice_camara": dados_pt.get("indice_camara"),
				"escolha": dados_pt.get("tipo"),
			})
			_gravar_evento(&"porta", dados_pt)
		&"saldo_mudou":
			var delta_var: Variant = e.get("delta")
			var orig_var: Variant = e.get("origem")
			var delta: int = int(delta_var) if delta_var != null else 0
			if delta > 0 and orig_var != null:
				var chave_orig := String(orig_var)
				_fragmentos_por_origem[chave_orig] = int(_fragmentos_por_origem.get(chave_orig, 0)) + delta
		&"jogador_morreu":
			if _camara.aberta:
				var dados_cam_morte := _camara.fechar(LinhaDeCamara.RESULTADO_MORTE, _casas_decimais_duracao, 0)
				_gravar_evento(&"camara", dados_cam_morte)
			var dados_morte := LinhasDeEventos.montar_morte(e, _camara.indice, _camara.vida_max)
			_gravar_evento(&"morte", dados_morte)
		&"encontro_pacto":
			if _em_run and _doutrina_atual != "" and _doutrina_atual != LinhasDeRun.DOUTRINA_PACTOS:
				return
			var dados_ep := LinhasDePactos.montar_encontro_pacto(e, _camara.indice, _avisos)
			_gravar_evento(&"encontro_pacto", dados_ep)
		&"pacto_registrado", &"pacto":
			# Em Armada (antes de run_iniciada), o arquivo ainda não abriu: descartado sem TL3 (Edge Case R4-P).
			if _estado != Estado.ABERTA:
				return
			if _em_run and _doutrina_atual != "" and _doutrina_atual != LinhasDeRun.DOUTRINA_PACTOS:
				return
			var dados_pa := LinhasDePactos.montar_pacto(e, _avisos)
			_gravar_evento(&"pacto", dados_pa)
		&"run_encerrada":
			_ao_run_encerrada(e)
		&"vinculo_atualizado", &"vinculo_fim_run":
			if _doutrina_atual != "" and _doutrina_atual != LinhasDeRun.DOUTRINA_PACTOS:
				return
			var dados_vf := LinhasDePactos.montar_vinculo_fim_run(e, _avisos)
			# GDD R4-P: sai depois de run_encerrada com o MESMO número de run.
			_gravar_evento_com_run(&"vinculo_fim_run", dados_vf, _indice_run_sessao)


func _ao_run_iniciada(e: EventoDoPasso) -> void:
	_indice_run_sessao += 1
	_em_run = true
	_camara.aberta = false
	_ultimas_trocas_oferta = 0
	_fragmentos_por_origem.clear()
	_caminho_da_run.clear()

	# R6 (AC-TL-16): quando Armada, a próxima run_iniciada abre um arquivo novo começando com sessao_iniciada (n=0, run continua).
	if _estado == Estado.ARMADA and _ligada:
		_abrir_arquivo_de_sessao()

	var dados := LinhasDeRun.montar_run_iniciada(e, _avisos)
	if dados.get("estado_inicial") is Dictionary:
		var est := dados["estado_inicial"] as Dictionary
		_doutrina_atual = String(est.get("doutrina", ""))
	else:
		_doutrina_atual = ""
	_gravar_evento(&"run_iniciada", dados)


func _ao_camara_entrou(e: EventoDoPasso) -> void:
	var ind: Variant = e.get("indice")
	var p_val: Variant = e.get("p")
	var tipo_val: Variant = e.get("tipo_camara")
	if tipo_val == null:
		tipo_val = e.get("tipo")
	var vmax_val: Variant = e.get("vida_max")
	var vatual_val: Variant = e.get("vida_atual")
	_camara.abrir(
		int(ind) if ind != null else 0,
		int(p_val) if p_val != null else 0,
		String(tipo_val) if tipo_val != null else "combate",
		int(vmax_val) if vmax_val != null else 80,
		int(vatual_val) if vatual_val != null else -1,
		_obter_ms_monotonico()
	)


func _ao_run_encerrada(e: EventoDoPasso) -> void:
	var dados := LinhasDeRun.montar_run_encerrada(e, _fragmentos_por_origem, _caminho_da_run, _avisos)
	var motivo := String(dados.get("motivo", ""))
	# R12 (AC-TL-12): se a run foi abandonada com câmara em curso, fecha a câmara com resultado = "abandono" antes de run_encerrada.
	if _camara.aberta:
		var res_cam := LinhaDeCamara.RESULTADO_ABANDONO if motivo == "abandono" else (
			LinhaDeCamara.RESULTADO_MORTE if motivo == "morte" else LinhaDeCamara.RESULTADO_LIMPA
		)
		var dados_cam := _camara.fechar(res_cam, _casas_decimais_duracao)
		_gravar_evento(&"camara", dados_cam)

	_runs_encerradas_sessao += 1
	if motivo == "abandono":
		_runs_abandonadas_sessao += 1

	_gravar_evento_com_run(&"run_encerrada", dados, _indice_run_sessao)
	_em_run = false


# --- I/O de sessão e gravação por linha -------------------------------------

func _abrir_arquivo_de_sessao() -> bool:
	if _armazem == null or _relogio == null:
		_entrar_parada_por_falha("armazem ou relogio ausente")
		return false
	var err_pasta := _armazem.garantir_pasta(_pasta)
	if err_pasta != OK:
		_entrar_parada_por_falha("garantir_pasta falhou: err=%d" % err_pasta)
		return false

	RetencaoDeSessoes.aplicar_retencao_na_abertura(_armazem, _pasta, _max_sessoes, _avisos)
	var nome_base := _relogio.nome_base_sessao()
	var caminho := RetencaoDeSessoes.escolher_caminho_livre(_armazem, _pasta, nome_base)
	var escritor := _armazem.criar_escritor_de_linhas(caminho)
	if escritor == null:
		_entrar_parada_por_falha("criar_escritor_de_linhas devolveu null: %s" % caminho.get_file())
		return false

	_escritor = escritor
	_caminho_arquivo_atual = caminho
	_bytes_escritos = 0
	_n_linha = 0
	_ultimo_ms = 0
	_estado = Estado.ABERTA

	var dados_sessao := {
		"schema": SCHEMA_ATUAL,
		"versao": _versao_jogo,
		"impressao": _impressao_curta.substr(0, 4),
		"os": _relogio.familia_os(),
		"data_utc": _normalizar_utc_z(_relogio.data_utc_iso()),
	}
	return _gravar_evento(&"sessao_iniciada", dados_sessao)


func _gravar_evento(tipo_linha: StringName, campos_especificos: Dictionary) -> bool:
	var run_num := _indice_run_sessao if _em_run else 0
	return _gravar_evento_com_run(tipo_linha, campos_especificos, run_num)


func _gravar_evento_com_run(tipo_linha: StringName, campos_especificos: Dictionary, run_num: int) -> bool:
	if _estado != Estado.ABERTA or _escritor == null:
		return false

	var ms_atual := _obter_ms_monotonico()
	var linha_dict: Dictionary = {
		"t": String(tipo_linha),
		"n": _n_linha,
		"ms": ms_atual,
		"run": run_num,
	}
	for chave: Variant in campos_especificos.keys():
		var k := String(chave)
		if k == "schema" and _n_linha != 0:
			continue
		linha_dict[k] = campos_especificos[chave]

	var json_str := JSON.stringify(linha_dict)
	var bytes_linha := json_str.to_utf8_buffer().size() + 1 # +1 da quebra de linha '\n'

	# R9 (AC-TL-20): verifica se cabe com a reserva de 512 B antes de escrever (salvo a própria sessao_encerrada).
	if tipo_linha != &"sessao_encerrada":
		if _bytes_escritos + bytes_linha + RESERVA_LIMITE_BYTES > _max_bytes_sessao:
			_fechar_com_sessao_encerrada("limite")
			_fechar_escritor()
			_estado = Estado.PARADA_POR_LIMITE
			return false
	else:
		if _bytes_escritos + bytes_linha > _max_bytes_sessao:
			_fechar_escritor()
			_estado = Estado.PARADA_POR_LIMITE
			return false

	var t0_us := _relogio.agora_us()
	var ok_escrita := _escritor.escrever_linha(json_str)
	var ok_flush := _escritor.descarregar() if ok_escrita else false
	var t1_us := _relogio.agora_us()

	if not ok_escrita or not ok_flush:
		_entrar_parada_por_falha("falha ao escrever ou descarregar linha %d (%s)" % [_n_linha, String(tipo_linha)])
		return false

	_bytes_escritos += bytes_linha
	_n_linha += 1

	var custo_us := maxi(0, t1_us - t0_us)
	if custo_us > _pior_linha_us:
		_pior_linha_us = custo_us
	var orc_linha_us := int(roundf(_orcamento_linha_ms * 1000.0))
	if custo_us > orc_linha_us:
		_avisos.registrar_tl2("linha %d excedeu orcamento: %d us > %d us" % [_n_linha - 1, custo_us, orc_linha_us])

	return true


func _fechar_com_sessao_encerrada(motivo: String) -> void:
	if _estado != Estado.ABERTA or _escritor == null:
		return
	_gravar_evento(&"sessao_encerrada", {"motivo": motivo})


func _entrar_parada_por_falha(detalhe: String) -> void:
	_avisos.registrar_tl1(detalhe)
	_fechar_escritor()
	_estado = Estado.PARADA_POR_FALHA


func _fechar_escritor() -> void:
	if _escritor != null:
		_escritor.fechar()
		_escritor = null


func _obter_ms_monotonico() -> int:
	if _relogio == null:
		return _ultimo_ms
	var agora := _relogio.agora_ms()
	if agora > _ultimo_ms:
		_ultimo_ms = agora
	return _ultimo_ms


static func _normalizar_utc_z(data_iso: String) -> String:
	var s := data_iso.strip_edges()
	if s.is_empty():
		return "2026-11-18T00:00:00Z"
	if not s.ends_with("Z"):
		return s + "Z"
	return s
