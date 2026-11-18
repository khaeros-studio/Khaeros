class_name EscolhaDoChefe
extends RefCounted
## Regras da decisão Pactuar vs Exorcizar no chefe Subjugado (V18, V18.5;
## GDD vinculo-e-pactos.md; ADR-0015 §4.5).
##
## Casos ao escolher [code]&"pactuar"[/code] com a Maldição-chefe ([code]soberano_do_limiar[/code]):
## - V18.3 Não pactuada: [code]pactuada = true[/code], [code]nivel = 1[/code], [code]vinculo_pontos = 0[/code],
##   [code]encontros_bem_sucedidos += 1[/code]; emite [code]pacto_registrado[/code] e [code]pacto(chefe)[/code].
##   Não entra na dupla desta run; Fragmentos do chefe = 0.
## - V18.4 Já pactuada e [code]nivel < nivel_max[/code] (5): soma [code]pts_reafirmar_chefe[/code] (10)
##   aos pontos da run do chefe, [code]encontros_bem_sucedidos += 1[/code]; emite [code]pacto_registrado[/code].
## - V18.5 Já pactuada e no [code]nivel_max[/code] (5) ("o fardo repartido"):
##   os [code]pts_reafirmar_chefe[/code] (10) vão inteiros para **cada espécie da dupla desta run** (até 2).
##   Se uma espécie da dupla também já está no nível 5, a parte dela vai para a espécie pactuada
##   de **menor nível** fora da dupla (empate: ordem do manifesto).
## - V18.6 Ao escolher [code]&"exorcizar"[/code]: nada muda no pacto; o módulo de Chefes credita +6 Fragmentos.

const ESCOLHA_PACTUAR: StringName = &"pactuar"
const ESCOLHA_EXORCIZAR: StringName = &"exorcizar"
const ID_CHEFE_PADRAO: StringName = &"soberano_do_limiar"


## Resultado detalhado da resolução de Pactuar/Exorcizar no chefe.
class ResultadoEscolhaChefe:
	extends RefCounted
	var chefe_id: StringName = ID_CHEFE_PADRAO
	var escolha: StringName = ESCOLHA_PACTUAR
	var emitiu_pacto_registrado: bool = false
	var pacto_novo: bool = false
	var pontos_por_especie: Dictionary[StringName, int] = {}
	var vinculo_ja_inteiro: bool = false


## Calcula e aplica no [param perfil] (e devolve os pontos da run a somar) a decisão [param escolha] no chefe (V18, AC-VP-22, AC-VP-23).
static func resolver(chefe_id: StringName, escolha: StringName, perfil: PerfilVinculo,
		dupla_run: Array[StringName], tuning: VinculoTuning = null) -> ResultadoEscolhaChefe:
	var res := ResultadoEscolhaChefe.new()
	res.chefe_id = chefe_id if chefe_id != &"" else ID_CHEFE_PADRAO
	res.escolha = escolha
	if perfil == null or escolha != ESCOLHA_PACTUAR:
		return res

	var pts_chefe: int = tuning.pts_reafirmar_chefe if (tuning != null and tuning.pts_reafirmar_chefe > 0) else 10
	var nivel_max: int = tuning.nivel_max if (tuning != null and tuning.nivel_max > 0) else 5
	var est_chefe: PerfilVinculo.EstadoEspecie = perfil.estado_de(res.chefe_id)
	if est_chefe == null:
		return res

	est_chefe.encontros_bem_sucedidos = mini(est_chefe.encontros_vistos, est_chefe.encontros_bem_sucedidos + 1)

	# V18.3: espécie ainda não pactuada
	if not est_chefe.pactuada:
		perfil.registrar_pacto_novo(res.chefe_id)
		res.emitiu_pacto_registrado = true
		res.pacto_novo = true
		return res

	res.emitiu_pacto_registrado = true

	# V18.4: espécie já pactuada e abaixo do nível máximo
	if est_chefe.nivel < nivel_max:
		res.pontos_por_especie[res.chefe_id] = pts_chefe
		return res

	# V18.5: espécie no nível máximo (5) -> "o fardo repartido" (AC-VP-23)
	var recebedores_usados: Array[StringName] = []
	for esp_dupla: StringName in dupla_run:
		if esp_dupla == &"":
			continue
		var est_d: PerfilVinculo.EstadoEspecie = perfil.estado_de(esp_dupla)
		if est_d != null and est_d.pactuada and est_d.nivel < nivel_max:
			res.pontos_por_especie[esp_dupla] = int(res.pontos_por_especie.get(esp_dupla, 0)) + pts_chefe
			recebedores_usados.append(esp_dupla)
		else:
			var substituto: StringName = _menor_nivel_fora_da_dupla(perfil, dupla_run, recebedores_usados, nivel_max)
			if substituto != &"":
				res.pontos_por_especie[substituto] = int(res.pontos_por_especie.get(substituto, 0)) + pts_chefe
				recebedores_usados.append(substituto)

	if res.pontos_por_especie.is_empty():
		res.vinculo_ja_inteiro = true
	return res


static func _menor_nivel_fora_da_dupla(perfil: PerfilVinculo, dupla_run: Array[StringName],
		ja_usados: Array[StringName], nivel_max: int) -> StringName:
	var melhor_id: StringName = &""
	var menor_nivel: int = nivel_max
	for id: StringName in perfil.ordem_manifesto():
		if dupla_run.has(id) or ja_usados.has(id):
			continue
		var est: PerfilVinculo.EstadoEspecie = perfil.estado_de(id)
		if est != null and est.pactuada and not est.obsoleta and est.nivel < menor_nivel:
			menor_nivel = est.nivel
			melhor_id = id
	return melhor_id
