class_name VistaDePorta
extends RefCounted
## Dados de apresentação de uma porta aberta no mundo (GDD portas-e-recompensas.md R8, R9-P;
## ADR-0012, ADR-0015).
##
## Exemplos do que mostra:
## - [code]bencao[/code]: ícone de bênção, [code]quantidade = 3[/code] (3 ofertas), [code]rotulo_quantidade = "3 ofertas"[/code];
## - [code]fragmentos[/code]: ícone de Fragmentos, [code]quantidade = 2[/code] ou [code]3[/code] (da próxima câmara de combate), [code]rotulo_quantidade = "+2"[/code] / [code]"+3"[/code];
## - [code]cura[/code]: ícone de cura, [code]quantidade = 30[/code] (30%), [code]rotulo_quantidade = "+30%"[/code];
## - [code]santuario[/code]: símbolo do santuário, [code]quantidade = 0[/code], [code]rotulo_quantidade = ""[/code];
## - [code]chefe[/code]: símbolo do chefe, [code]quantidade = 0[/code], [code]rotulo_quantidade = ""[/code] (R9-P);
## - [code]ultima[/code]: sem ícone de recompensa, [code]quantidade = 0[/code], [code]rotulo_quantidade = ""[/code].

var indice: int = 0
var tipo: StringName = &""
var quantidade: int = 0
var rotulo_quantidade: String = ""
var posicao: Vector2 = Vector2.ZERO
var aberta: bool = false
var carrega_recompensa: bool = false


func _init(p_indice: int = 0, p_tipo: StringName = &"", p_quantidade: int = 0,
		p_rotulo: String = "", p_posicao: Vector2 = Vector2.ZERO,
		p_aberta: bool = false, p_carrega_recompensa: bool = false) -> void:
	indice = p_indice
	tipo = p_tipo
	quantidade = p_quantidade
	rotulo_quantidade = p_rotulo
	posicao = p_posicao
	aberta = p_aberta
	carrega_recompensa = p_carrega_recompensa
