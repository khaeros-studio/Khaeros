class_name ConsentimentoPacto
extends RefCounted
## Regras de consentimento após limpar a câmara do encontro (V9, V10, V11, V13, V15;
## GDD vinculo-e-pactos.md; ADR-0012, ADR-0015, ADR-0017).
##
## Casos na tela de consentimento (estado `BENCAO` do orquestrador):
## 1. Espécie **não pactuada** e [code]encontros_bem_sucedidos + 1 >= encontros_para_consentir(raridade)[/code]:
##    opções [code]&"oferecer"[/code] ("Oferecer o vínculo") e [code]&"deixar_ir"[/code] ("Deixá-la ir").
## 2. Espécie **não pactuada** e [code]encontros_bem_sucedidos + 1 < encontros_para_consentir(raridade)[/code]
##    (ex.: Rara/Épica na 1ª vez, V13): opção única [code]&"ela_voltara"[/code] ("Ela voltará"),
##    incrementa [code]encontros_bem_sucedidos[/code] e grava [code]encontro_pendente = [especie][/code].
## 3. Espécie **já pactuada** (reafirmação, V11):
##    opções [code]&"reafirmar"[/code] ("Reafirmar o vínculo", +6 pontos na run) e [code]&"deixar_ir"[/code].

const OPCAO_OFERECER: StringName = &"oferecer"
const OPCAO_REAFIRMAR: StringName = &"reafirmar"
const OPCAO_DEIXAR_IR: StringName = &"deixar_ir"
const OPCAO_ELA_VOLTARA: StringName = &"ela_voltara"

const RESULTADO_PACTUADA: StringName = &"pactuada"
const RESULTADO_REAFIRMADA: StringName = &"reafirmada"
const RESULTADO_DEIXADA: StringName = &"deixada"
const RESULTADO_VOLTARA: StringName = &"voltara"

const ORDEM_RARIDADES: Array[StringName] = [&"comum", &"refinado", &"raro", &"epico", &"primordial"]


## Encontros bem-sucedidos necessários para a espécie consentir (V13: Comum 1, Refinado 1, Raro 2, Épico 2, Primordial 1).
static func encontros_necessarios(raridade: StringName, tuning: VinculoTuning = null) -> int:
	var idx: int = ORDEM_RARIDADES.find(raridade)
	if idx >= 0 and tuning != null and idx < tuning.encontros_para_consentir.size():
		return maxi(1, int(tuning.encontros_para_consentir[idx]))
	const PADRAO: Array[int] = [1, 1, 2, 2, 1]
	if idx >= 0 and idx < PADRAO.size():
		return PADRAO[idx]
	return 1


## Devolve os botões disponíveis na tela de consentimento para [param especie_id] no [param perfil] atual (V10, V11, V13).
static func opcoes_da_tela(especie_id: StringName, perfil: PerfilVinculo, tuning: VinculoTuning = null) -> Array[StringName]:
	if perfil == null:
		return [OPCAO_OFERECER, OPCAO_DEIXAR_IR]
	var est: PerfilVinculo.EstadoEspecie = perfil.estado_de(especie_id)
	if est == null:
		return [OPCAO_OFERECER, OPCAO_DEIXAR_IR]
	if est.pactuada:
		return [OPCAO_REAFIRMAR, OPCAO_DEIXAR_IR]
	var necessarios: int = encontros_necessarios(est.raridade, tuning)
	if est.encontros_bem_sucedidos + 1 >= necessarios:
		return [OPCAO_OFERECER, OPCAO_DEIXAR_IR]
	return [OPCAO_ELA_VOLTARA]
