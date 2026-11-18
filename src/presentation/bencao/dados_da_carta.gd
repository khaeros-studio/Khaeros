class_name DadosDaCarta
extends RefCounted
## Contrato de dados das 6 zonas visuais da carta `320×500` (Art Bible §7.5, `design/gdd/tela-de-bencao-e-carta.md` R3):
## 1. Moldura / Placa (`assets/art/ui/cartas/moldura_*.png`)
## 2. Cabeçalho de Doutrina / Raridade + Glifo (`assets/art/ui/glifos/glifo_*.png`)
## 3. Ilustração / Retrato (`128×128` ou retrato de Maldição `assets/art/ui/maldicoes/*_retrato.png`)
## 4. Título (chave de tradução)
## 5. Corpo de Regra / Efeito (chave de tradução + parâmetros numéricos)
## 6. Rodapé de Preço / Condição / Aviso (`preco_vida`, `aviso_texto` para Besta do Vínculo, ou papel Campo/Reserva)

const LARGURA_CARTA_100_PX: float = 320.0
const ALTURA_CARTA_100_PX: float = 500.0
const ESPACAMENTO_CARTAS_100_PX: float = 40.0

var id: StringName = &""
var modo: StringName = &"bencao" # &"bencao", &"arma", &"maldicao", &"melhoria"
var doutrina: StringName = &"sangue" # &"sangue", &"ferro", &"sombra", &"pactos", &"arma"
var raridade: int = 0 # 0=Comum, 1=Rara, 2=Lendária / Preço de Sangue

# Zona 1 & 2: Moldura e Glifo
var caminho_moldura: String = "res://assets/art/ui/cartas/moldura_comum.png"
var caminho_glifo: String = "res://assets/art/ui/glifos/glifo_sangue.png"
var chave_raridade: StringName = &"BENCAO_RARIDADE_COMUM"

# Zona 3: Ilustração / Retrato
var caminho_ilustracao: String = ""

# Zona 4 & 5: Título e Corpo (sempre chaves de tradução)
var chave_titulo: StringName = &""
var chave_corpo: StringName = &""
var parametros_corpo: Dictionary = {}

# Zona 6: Preço / Aviso / Papel
var preco_vida: int = 0
var chave_preco: StringName = &""
var aviso_texto: StringName = &"" # ex.: &"ARMA_AVISO_BESTA_DO_VINCULO"
var desabilitada: bool = false
var chave_motivo_desabilitada: StringName = &""


static func criar_de_bencao(
	id_bencao: StringName,
	doutrina_id: StringName,
	raridade_val: int,
	preco_vida_val: int = 0
) -> DadosDaCarta:
	var d: DadosDaCarta = DadosDaCarta.new()
	d.id = id_bencao
	d.modo = &"bencao"
	d.doutrina = doutrina_id
	d.raridade = clampi(raridade_val, 0, 2)
	d.caminho_moldura = _resolver_moldura_por_raridade(d.raridade, preco_vida_val > 0)
	d.caminho_glifo = _resolver_glifo_por_doutrina(doutrina_id)
	d.chave_raridade = _resolver_chave_raridade(d.raridade)
	d.chave_titulo = StringName("BENCAO_%s_TITULO" % String(id_bencao).to_upper())
	d.chave_corpo = StringName("BENCAO_%s_DESC" % String(id_bencao).to_upper())
	d.preco_vida = maxi(0, preco_vida_val)
	if d.preco_vida > 0:
		d.chave_preco = &"BENCAO_PRECO_VIDA"
	return d


static func criar_de_arma(id_arma: StringName, pactos_disponiveis: int = 0) -> DadosDaCarta:
	var d: DadosDaCarta = DadosDaCarta.new()
	d.id = id_arma
	d.modo = &"arma"
	d.doutrina = &"pactos" if id_arma == &"besta_do_vinculo" else &"arma"
	d.raridade = 1
	d.caminho_moldura = "res://assets/art/ui/cartas/moldura_rara.png"
	d.caminho_glifo = _resolver_glifo_por_doutrina(d.doutrina)
	d.chave_raridade = &"ARMA_CATEGORIA_INICIAL"
	d.chave_titulo = StringName("ARMA_%s_TITULO" % String(id_arma).to_upper())
	d.chave_corpo = StringName("ARMA_%s_DESC" % String(id_arma).to_upper())
	if id_arma == &"besta_do_vinculo" and pactos_disponiveis <= 0:
		d.aviso_texto = &"ARMA_AVISO_SEM_PACTOS_NO_PERFIL"
	elif id_arma == &"besta_do_vinculo":
		d.aviso_texto = &"ARMA_DOUTRINA_PACTOS_ATIVA"
	return d


static func criar_de_maldicao(id_especie: StringName) -> DadosDaCarta:
	var d: DadosDaCarta = DadosDaCarta.new()
	d.id = id_especie
	d.modo = &"maldicao"
	d.doutrina = &"pactos"
	d.raridade = 1
	d.caminho_moldura = "res://assets/art/ui/cartas/moldura_pacto.png"
	d.caminho_glifo = "res://assets/art/ui/glifos/glifo_pactos.png"
	d.caminho_ilustracao = "res://assets/art/ui/maldicoes/%s_retrato.png" % String(id_especie)
	d.chave_raridade = &"PACTO_ESPECIE_VINCULADA"
	d.chave_titulo = StringName("MALDICAO_%s_TITULO" % String(id_especie).to_upper())
	d.chave_corpo = StringName("MALDICAO_%s_DESC" % String(id_especie).to_upper())
	return d


static func _resolver_moldura_por_raridade(raridade_val: int, tem_preco_sangue: bool) -> String:
	if tem_preco_sangue:
		return "res://assets/art/ui/cartas/moldura_sangue.png"
	if raridade_val >= 2:
		return "res://assets/art/ui/cartas/moldura_lendaria.png"
	if raridade_val == 1:
		return "res://assets/art/ui/cartas/moldura_rara.png"
	return "res://assets/art/ui/cartas/moldura_comum.png"


static func _resolver_glifo_por_doutrina(doutrina_id: StringName) -> String:
	if doutrina_id == &"pactos":
		return "res://assets/art/ui/glifos/glifo_pactos.png"
	if doutrina_id == &"ferro":
		return "res://assets/art/ui/glifos/glifo_ferro.png"
	if doutrina_id == &"sombra":
		return "res://assets/art/ui/glifos/glifo_sombra.png"
	return "res://assets/art/ui/glifos/glifo_sangue.png"


static func _resolver_chave_raridade(raridade_val: int) -> StringName:
	if raridade_val >= 2:
		return &"BENCAO_RARIDADE_LENDARIA"
	if raridade_val == 1:
		return &"BENCAO_RARIDADE_RARA"
	return &"BENCAO_RARIDADE_COMUM"
