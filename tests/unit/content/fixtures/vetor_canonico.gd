class_name VetorCanonico
extends RefCounted
## Vetor de referência CONGELADO da impressão canônica (protocolo v1, ADR-0004), gerado
## fora do Godot por um codificador Python independente (hashlib.sha256) em 2026-11-16.
## Catálogo mínimo: 1 tipo "upgrade" com UpgradeDef "melhoria" (chave_nome
## UPGRADE_MELHORIA_NAME, custos [10, -3], 1 EffectDef embutido: tipo vida_max_plano,
## valor -0.0, escala_com_raridade true, params {b: 1.5, a: 0.25}).
## Mudou o protocolo? Suba ImpressaoCanonica.VERSAO_DO_FORMATO e regenere este vetor.

const BYTES_HEX := "4b484145524f532d434154414c4f470100000001000000070000007570677261646501000000070700000075706772616465080000006d656c686f726961050000000a00000063686176655f6e6f6d650415000000555047524144455f4d454c484f5249415f4e414d4506000000637573746f730502000000020a0000000000000002fdffffffffffffff0700000065666569746f7305010000000709000000456666656374446566000000000400000013000000657363616c615f636f6d5f7261726964616465010106000000706172616d730602000000010000006103000000000000d03f010000006203000000000000f83f040000007469706f040e000000766964615f6d61785f706c616e6f0500000076616c6f7203000000000000000002000000696404080000006d656c686f726961080000006f62736f6c65746f0100"
const SHA256 := "48b17c862358a5569450a30f2ba00f87da81bb6c0639f69cbbb65cede7814be6"


## Monta o catálogo mínimo descrito acima.
static func catalogo_minimo() -> Catalogo:
	var e := EffectDef.new()
	e.tipo = &"vida_max_plano"
	e.valor = -0.0
	e.escala_com_raridade = true
	e.params = {&"b": 1.5, &"a": 0.25}
	var u := UpgradeDef.new()
	u.id = &"melhoria"
	u.chave_nome = &"UPGRADE_MELHORIA_NAME"
	u.custos = PackedInt64Array([10, -3])
	u.efeitos = [e]
	var cat := Catalogo.new(RelatorAcumulador.new())
	cat.adicionar(&"upgrade", u)
	return cat
