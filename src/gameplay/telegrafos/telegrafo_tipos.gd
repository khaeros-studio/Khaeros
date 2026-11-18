class_name TelegrafoTipos
extends RefCounted
## Enums e constantes de domínio de Telégrafos (GDD telegrafos.md R1–R10; ADR-0014).

enum Forma {
	CIRCULO,
	SETOR,
	RETANGULO,
	ANEL,
}

enum Modo {
	CENTRO_A_BORDA,
	AO_LONGO_DO_EIXO,
	BORDA_AO_CENTRO,
}

enum Estado {
	LIVRE,
	CRESCENDO,
	DISPARO,
	QUEBRADO,
	CANCELADO,
}

enum PoliticaDeTroca {
	FADE_DOIS_PASSOS,
	LIBERAR_JA,
}

enum FaccaoAlvo {
	JOGADOR,
	ALIADO,
	ACUADA,
}

enum CausaCancelamento {
	DONO_MORTO,
	TROCA_CAMARA,
	TRANSICAO_FASE,
	QUEDA_CHEFE,
}

## Contorno visual para o Pipeline (diferenciação JOGADOR vs MALDICAO / ACUADA).
enum ContornoAlvo {
	PERIGO_JOGADOR,
	SECUNDARIO_ALIADO,
	SECUNDARIO_ACUADA,
}

const PASSOS_TERMINAL: int = 2
const RAIO_JOGADOR_PADRAO_PX: float = 27.0
const RAIO_PROJETIL_PADRAO_PX: float = 13.5
const VIDA_PROJETIL_PADRAO_PASSOS: int = 240
const SAIDA_OFFSET_PX: float = 9.0
const AVANCO_MULT_VELOCIDADE: float = 3.6
const AVANCO_PASSOS_PADRAO: int = 26
const COS_MEIO_SETOR_PADRAO: float = 0.2
const MEIO_ANGULO_SETOR_GRAUS: float = 78.463041
