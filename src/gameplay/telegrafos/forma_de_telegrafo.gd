class_name FormaDeTelegrafo
extends RefCounted
## Adaptador interno único que monta a geometria de acerto e a vista publicada
## a partir de TelegrafoSlot, posição do dono e GeometriaDeMovimento (ADR-0014 Decisões 4, 5, 10, 11).


## Comprimento efetivo de uma faixa de projétil cortada por parede ou obstáculo (AC-TG-09).
static func comprimento_efetivo(derivada: FormasDeTelegrafo.FormaDerivada, pos_dono: Vector2,
		mira: Vector2, camara: GeometriaDeMovimento = null) -> float:
	if derivada == null:
		return 0.0
	if not derivada.eh_faixa_projetil or camara == null:
		return derivada.comprimento
	return GeometriaDeAcerto.alcance_do_raio(pos_dono, mira, derivada.comprimento,
		camara.jogavel, camara.obstaculos())


## Testa se `ponto` (centro do alvo travado) está dentro da forma de `slot` (F5, R6, R6a).
static func dentro(slot: TelegrafoSlot, pos_dono: Vector2, ponto: Vector2,
		camara: GeometriaDeMovimento = null) -> bool:
	if slot == null or slot.derivada == null or not slot.derivada.valida:
		return false
	var d := slot.derivada
	match d.forma:
		TelegrafoTipos.Forma.SETOR:
			if d.leques <= 1:
				return GeometriaDeAcerto.setor_toca(pos_dono, slot.mira, d.cos_meio, d.raio, ponto, 0.0)
			# Suporte a leques compostos (chefes): múltiplos setores distribuídos simetricamente
			var passo_graus := 360.0 / float(d.leques)
			for i in d.leques:
				var dir_i := GeometriaDeAcerto.girar_graus(slot.mira, float(i) * passo_graus)
				if GeometriaDeAcerto.setor_toca(pos_dono, dir_i, d.cos_meio, d.raio, ponto, 0.0):
					return true
			return false
		TelegrafoTipos.Forma.RETANGULO:
			if d.eh_avanco:
				# R6: durante o avanço, o teste de contato é círculo estrito (< R_c)
				return GeometriaDeAcerto.circulos_encostam(pos_dono, ponto, d.r_c)
			var comp := comprimento_efetivo(d, pos_dono, slot.mira, camara)
			if comp <= 0.0:
				return false
			var x_min := d.x_min
			var x_max := x_min + comp
			var centro := pos_dono + slot.mira * ((x_min + x_max) * 0.5)
			var meio_comp := (x_max - x_min) * 0.5
			var meia_larg := d.largura * 0.5
			return GeometriaDeAcerto.retangulo_orientado_toca(centro, slot.mira, meio_comp, meia_larg, ponto, 0.0)
		TelegrafoTipos.Forma.ANEL:
			return GeometriaDeAcerto.anel_toca(pos_dono, d.r_int, d.r_ext, ponto, 0.0)
		TelegrafoTipos.Forma.CIRCULO:
			return GeometriaDeAcerto.circulo_toca(pos_dono, d.raio, ponto, 0.0)
	return false


## Testa se `ponto` está dentro da envoltória retangular de desenho (F5 eixo local do retângulo, AC-TG-27).
static func dentro_envoltoria_retangulo(slot: TelegrafoSlot, pos_dono: Vector2, ponto: Vector2,
		camara: GeometriaDeMovimento = null) -> bool:
	if slot == null or slot.derivada == null or slot.derivada.forma != TelegrafoTipos.Forma.RETANGULO:
		return false
	var d := slot.derivada
	var comp := comprimento_efetivo(d, pos_dono, slot.mira, camara)
	var x_min := d.x_min
	var x_max := x_min + comp
	var centro := pos_dono + slot.mira * ((x_min + x_max) * 0.5)
	var meio_comp := (x_max - x_min) * 0.5
	var meia_larg := d.largura * 0.5
	return GeometriaDeAcerto.retangulo_orientado_toca(centro, slot.mira, meio_comp, meia_larg, ponto, 0.0)


## Preenche `vista` pré-alocada sem alocar objetos novos (ADR-0014 Decisão 8).
static func preencher_vista(slot: TelegrafoSlot, pos_dono: Vector2,
		camara: GeometriaDeMovimento, vista: VistaDeTelegrafo) -> void:
	var d := slot.derivada
	vista.slot = slot.indice
	vista.dono_id = slot.dono_id
	vista.seq = slot.seq
	vista.forma = d.forma
	vista.modo = d.modo
	vista.estado = slot.estado
	vista.pos = pos_dono
	vista.mira = slot.mira
	vista.rot = slot.mira.angle()
	vista.raio = d.raio
	vista.r_int = d.r_int
	vista.r_ext = d.r_ext
	vista.cos_meio = d.cos_meio
	vista.meio_angulo_graus = d.meio_angulo_graus
	vista.x_min = d.x_min
	vista.comprimento = comprimento_efetivo(d, pos_dono, slot.mira, camara)
	vista.largura = d.largura
	vista.p = slot.progresso()
	vista.passos_no_estado = slot.passos_no_estado
	vista.alvo_id = slot.alvo_id
	vista.alvo_faccao = slot.alvo_faccao
	match slot.alvo_faccao:
		TelegrafoTipos.FaccaoAlvo.ALIADO:
			vista.contorno_alvo = TelegrafoTipos.ContornoAlvo.SECUNDARIO_ALIADO
		TelegrafoTipos.FaccaoAlvo.ACUADA:
			vista.contorno_alvo = TelegrafoTipos.ContornoAlvo.SECUNDARIO_ACUADA
		_:
			vista.contorno_alvo = TelegrafoTipos.ContornoAlvo.PERIGO_JOGADOR
	vista.contorno_secundario_raio = d.contorno_secundario_raio if slot.estado == TelegrafoTipos.Estado.CRESCENDO else 0.0
	vista.ondas_concentricas = d.ondas_concentricas
	vista.leques = d.leques
