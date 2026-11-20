# Design de Níveis e Arenas de Chefe — Expansão de Khaeros (5 Novos Bosses e Mapas)

> **Status:** Spec Oficial de Level Design (Pronta para Implementação e Produção de Assets)  
> **Autor:** Level Designer (`Khaeros`)  
> **Canon Level:** `Provisional` (novas regiões pós-Limiar/Santuário e 5 Chefes inéditos; respeita integralmente a *Lore Freeze* de P5 e o *Art Bible* vigente)  
> **Engine / Simulação:** Godot `4.7` / GDScript · Passo fixo `60 Hz` (`PASSOS_POR_SEGUNDO = 60`, `unit_to_px = 1,5`, `Iniciado = ~90 px` a `1080p`)  
> **Referências Estruturais Lidas:**
> - [mapa_masmorra.gd](file:///c:/Users/lucas/meu-jogo-estudio/src/gameplay/run/mapa_masmorra.gd)
> - [region_def.gd](file:///c:/Users/lucas/meu-jogo-estudio/src/content/region_def.gd) · [enemy_def.gd](file:///c:/Users/lucas/meu-jogo-estudio/src/content/enemy_def.gd) · [boss_pattern_def.gd](file:///c:/Users/lucas/meu-jogo-estudio/src/content/boss_pattern_def.gd)
> - [bestiario-oficial.md](file:///c:/Users/lucas/meu-jogo-estudio/design/world/bestiario-oficial.md) · [art-bible.md](file:///c:/Users/lucas/meu-jogo-estudio/design/art/art-bible.md) · [chefes.md](file:///c:/Users/lucas/meu-jogo-estudio/design/gdd/chefes.md)
> - [catalogo_campanha.gd](file:///c:/Users/lucas/meu-jogo-estudio/src/gameplay/run/catalogo_campanha.gd) · [game_session.gd](file:///c:/Users/lucas/meu-jogo-estudio/src/gameplay/game_session.gd) · [game_camera.gd](file:///c:/Users/lucas/meu-jogo-estudio/src/presentation/game_camera.gd) · [world_view.gd](file:///c:/Users/lucas/meu-jogo-estudio/src/presentation/world_view.gd)

---

## Sumário Executivo e Padrões Globais de Design

Este documento especifica **5 novas regiões/arenas de chefe** e seus respectivos **5 Bosses** (`Rank C+` a `Rank Cataclísmico`, Níveis `21` a `90`), desenhados para romper a monotonia de arenas vazias aplicando os pilares de Khaeros:

1. **Pilar P3 (*Reflexo que se lê*) e Gramática Visual do Art Bible:** Todo ataque é telegrafado em shader SDF (`4 px` de contorno `#0D0E14`, anel `#FF3DAE`, núcleo `#FFD3EE`, `L* ≥ 88`) acima de um chão achatado (`L* 22–38`) sem círculos, cones ou linhas geométricas pintadas na textura de piso. As mecânicas ambientais usam canais visuais subordinados (`L* ≤ 45`, borda orgânica/ramificada ou halo dourado de escolha `#E3B23C`).
2. **Determinismo Estrito a `60 Hz`:** Nenhuma regra de mapa, ciclo de maré, esporos, destruição de pilares ou ativação de selos usa `randf()`, `randi()` ou `RandomNumberGenerator` nativo da engine. Todo temporizador opera em **ticks inteiros (`passos`)** derivados de `live_steps` ou contadores determinísticos por estado, garantindo paridade para testes automatizados e eventual co-op autoritativo.
3. **Regra de Projeção 2D 3/4 de Colosso e Limite de Textura (`≤ 4096 px`):**
   - Na câmera `3/4` de Khaeros (`1080p`, `Iniciado ≈ 90 px`), criaturas de `8m` a `50m` **não** são exportadas como sprites rígidos gigantes em `1×1` linear (o que excederia o teto de `4096 px` do Art Bible §8.6 e cobriria a arena inteira).
   - Bosses de `8m`–`25m` usam escala visual `2,8×–5,5×` (`260–520 px` em tela) com **partes articuladas em rig 2D**; bosses de `32m` e `50m` (*Leviatã* e *Pesadelo*) utilizam **corpos multi-segmentados modulares** (cabeça, segmentos dorsais e membros periféricos independentes) + **sombra tectônica subterrânea/submersa**, transmitindo escala colossal sem sacrificar leitura de hurtbox nem o orçamento de `512 MiB` de VRAM.
4. **Cobertura Ultrawide (`43:18`, `W = 2580`) e `camera_zoom`:** Todas as 5 arenas mantêm largura `≥ (2580 / camera_zoom) + 80 px` e altura `≥ (1080 / camera_zoom) + 80 px`, assegurando sangria segura em monitores `16:9` e `21:9`/`43:18` dentro de `GameCamera._clamp()`.

---

## Mapa 1 — `colina_raizes_profundas` · Colina das Raízes Profundas

### Ficha de Level Design e Fluxo da Câmara
- **ID da Região / Arena:** `colina_raizes_profundas` (`Câmara do Chefe` — índice `6` do grafo `MapaMasmorra` ou encontro isolado em `CatalogoMapasBosses`)
- **Boss:** **Devorador da Coroa de Espinhos** (`devorador_coroa_espinhos`) · `Rank C+` · Nível `21` · Controlador Estático / Emboscador de Área · Escala Grande `~8 m`, enraizada no centro `(1400, 880)`
- **Tema e Atmosfera:** Clareira circular claustrofóbica em floresta apodrecida e úmida, tomada por raízes retorcidas escavadas na turfa negra e bancos baixos de névoa esverdeada rente às bordas (mantendo o piso central limpo sob telégrafos).
- **Tempo Estimado de Combate:** `2 min 45 s – 3 min 30 s` (`~9.900 – 12.600` ticks vivos)
- **Rumo Crítico (Critical Path):** Nascer sobre a **Laje Sul** `(1400, 1460)` → cruzar por *dash* entre as **5 Lajes de Pedra Antiga** evitando acionar *Sensor de Raízes* → manter pressão angular em média distância → atravessar/contornar os **4 Bolsões de Esporos** (ou dissipá-los com Selo `[Q]` / fogo / vento) → esperar a abertura de *Fissura da Coroa* para punir o **Núcleo Central Vulnerável** (`1,75×` dano) → abater/subjugar o Devorador e liberar o portal norte `(1400, 78)`.
- **Rotas Opcionais / Maestria:** Anel perimetral externo de `220 px` livre entre os bolsões e o muro de raízes permite contornar esporos sem gastar carga de Selo `[Q]`, ao custo de atravessar solo de raízes em corrida rápida (`< 1,10 s` antes do gatilho de emboscada).
- **Curva de Ritmo (Pacing Chart):**
  - `0–15 s` *(Introdução / Leitura)*: Intensidade `2 → 3` — jogador nasce seguro sobre a Laje 1; lê o diâmetro da clareira e o sensor sob a terra.
  - `15–75 s` *(Fase 1 — Dança entre Ilhas)*: Intensidade `4` — alternância entre *Chicote de Agulhas*, *Miragem de Esporos* e rotação horária/anti-horária pelas 5 Lajes.
  - `75–110 s` *(Janela de Burst)*: Intensidade `3 → 5` — *Fissura da Coroa* abre as pétalas em lâmina (pico de ameaça AoE, seguido de `3,20 s` de núcleo exposto para punição pesada).
  - `110–190 s` *(Fase 2 — ≤ 50% HP)*: Intensidade `5` — recargas caem para `70%`, 2 bolsões passam a emitir névoa simultaneamente e *Aperto Devorador* encadeia após chicotes.
  - `190–210 s` *(Catarse / Pós-luta)*: Intensidade `5 → 1` — raízes murcham, a névoa verde-musgo abre nas bordas revelando o portal dourado.
- **Beats Narrativos (sem violar a Lore Freeze P5):**
  1. As **5 Lajes de Pedra Antiga** trazem sulcos gastos de ferramentas, sem texto nem heráldica — indicando que alguém tentou calçar a clareira antes que as raízes a engolissem.
  2. Ao morrer, as pétalas espinhosas se fecham como casulo murcho e liberam a relíquia do núcleo sem revelar quem plantou a coroa.
- **Cues de Música / Áudio:**
  - *Entrada:* vento úmido filtrado + estalo grave de madeira tensionada (`bus_amb_colina`).
  - *Combate Fase 1:* percussão seca de madeira/osso em `104 BPM` + cordas graves abafadas.
  - *Sensor de Raízes (pré-gatilho `75%`):* zumbido térreo crescente + farfalhar seco sob as botas.
  - *Fissura da Coroa / Fase 2 (`≤ 50% HP`):* camada de sopros metálicos dissonantes (`+18%` energia), silenciando subitamente no instante em que o núcleo exposto recebe golpe crítico.

---

### Bloco 1.1 — Estrutura de Dados do Mapa (`colina_raizes_profundas`)

| Campo | Valor Canônico |
|---|---|
| `region_id` / `arena_id` | `colina_raizes_profundas` / `arena_colina_raizes` |
| `largura` × `altura` | `2800.0 × 1760.0 px` (clareira circular efetiva `Rx = 1180`, `Ry = 760`) |
| `camera_zoom` | `1.08` (visível `16:9`: `1778×1000 px`; `43:18`: `2389×1000 px`) |
| `spawn_jogador` | `(1400.0, 1480.0)` — centralizado sobre a Laje 1 |
| `spawn_chefe` | `(1400.0, 880.0)` — enraizado estático (`velocidade = 0.0`) |
| `chefe_id` | `devorador_coroa_espinhos` (`Rank C+`, Nível `21`, `1850 HP`, `raio_px = 110.0`) |
| `espolio` | `nucleo_de_espinho` (`Núcleo de Espinho`) + `casca_espinhosa` (`Casca Espinhosa`) |

```gdscript
# Compatível com RegionDef, EnemyDef, BossPatternDef, MapaMasmorra e CatalogoMapasBosses
const MAPA_COLINA_RAIZES: Dictionary = {
	"region_def": {
		"id": &"colina_raizes_profundas",
		"chave_nome": &"REG_COLINA_RAIZES_NOME",
		"camaras": [&"combate", &"emboscada", &"santuario_cura", &"combate_denso", &"altar_pacto", &"elite_guarda", &"chefe"],
		"pool_inimigos": [&"eco_perdido", &"vulto_mudo", &"anomalia_menor"],
		"chefe": &"devorador_coroa_espinhos",
		"fragmentos_chefe": 14,
	},
	"arena": {
		"id": "arena_colina_raizes",
		"formato": "elipse_circular",
		"largura": 2800.0,
		"altura": 1760.0,
		"margem": 180.0,
		"centro": Vector2(1400.0, 880.0),
		"elipse_raios": Vector2(1180.0, 760.0),
		"camera_zoom": 1.08,
		"spawn_jogador": Vector2(1400.0, 1480.0),
		"spawn_chefe": Vector2(1400.0, 880.0),
		"portal_saida": Vector2(1400.0, 78.0),
		"paleta": {
			"bg": Color("0b120e"),
			"floor": Color("1a241e"),
			"accent": Color("6b8f5e"),
			"border": Color("2a3a2f"),
			"motif": "raizes",
		},
		"pilares": [], # O boss estático no centro atua como obstáculo sólido central (r = 110.0)
		"zonas_seguras": [
			{"id": "laje_sul", "tipo": "laje_pedra_antiga", "x": 1400.0, "y": 1460.0, "r": 130.0},
			{"id": "laje_oeste", "tipo": "laje_pedra_antiga", "x": 820.0, "y": 980.0, "r": 120.0},
			{"id": "laje_leste", "tipo": "laje_pedra_antiga", "x": 1980.0, "y": 980.0, "r": 120.0},
			{"id": "laje_noroeste", "tipo": "laje_pedra_antiga", "x": 1010.0, "y": 460.0, "r": 115.0},
			{"id": "laje_nordeste", "tipo": "laje_pedra_antiga", "x": 1790.0, "y": 460.0, "r": 115.0},
		],
		"zonas_perigo": [
			{"id": "solo_raizes_geral", "tipo": "solo_raizes", "forma": "elipse_arena_exceto_lajes", "x": 1400.0, "y": 880.0, "r": 1180.0},
			{"id": "esporo_sw", "tipo": "bolsao_esporos", "x": 980.0, "y": 1270.0, "r": 135.0, "dissipavel_por": ["fogo", "vento", "selo"]},
			{"id": "esporo_se", "tipo": "bolsao_esporos", "x": 1820.0, "y": 1270.0, "r": 135.0, "dissipavel_por": ["fogo", "vento", "selo"]},
			{"id": "esporo_nw", "tipo": "bolsao_esporos", "x": 740.0, "y": 650.0, "r": 135.0, "dissipavel_por": ["fogo", "vento", "selo"]},
			{"id": "esporo_ne", "tipo": "bolsao_esporos", "x": 2060.0, "y": 650.0, "r": 135.0, "dissipavel_por": ["fogo", "vento", "selo"]},
		],
		"obstaculos_destrutiveis": [],
		"interativos": [],
	},
	"enemy_def": {
		"id": &"devorador_coroa_espinhos",
		"chave_nome": &"BOSS_DEVORADOR_COROA_NOME",
		"rank": "C+",
		"nivel": 21,
		"arquetipo": "controlador_estatico_emboscador",
		"comportamento": &"chefe",
		"vida": 1850.0,
		"velocidade": 0.0,
		"raio_px": 110.0,
		"dano": 18.0,
		"alcance_px": 780.0,
		"preparo_s": 0.65,
		"recarga_s": 1.10,
		"velocidade_projetil": 420.0,
		"custo_onda": 0,
		"padroes": [
			{
				"chave_nome": &"PAT_MIRAGEM_ESPOROS",
				"forma_telegrafo": &"circulo",
				"dimensoes": {&"raio_px": 145.0, &"qtd_zonas": 3.0},
				"preparo_s": 0.80,
				"execucao_s": 0.25,
				"recarga_s": 1.25,
				"dano": 16.0,
				"efeitos": [&"ativa_bolsao_esporos", &"desorientacao_leve"],
				"raio_secundario_px": 0.0,
			},
			{
				"chave_nome": &"PAT_CHICOTE_AGULHAS",
				"forma_telegrafo": &"retangulo",
				"dimensoes": {&"largura_px": 132.0, &"comprimento_px": 720.0},
				"preparo_s": 0.60,
				"execucao_s": 0.20,
				"recarga_s": 1.10,
				"dano": 22.0,
				"efeitos": [&"dispara_agulhas_3"],
				"raio_secundario_px": 0.0,
			},
			{
				"chave_nome": &"PAT_APERTO_DEVORADOR",
				"forma_telegrafo": &"anel",
				"dimensoes": {&"raio_int_px": 120.0, &"raio_ext_px": 340.0},
				"preparo_s": 0.75,
				"execucao_s": 0.30,
				"recarga_s": 1.40,
				"dano": 24.0,
				"efeitos": [&"enraizar_1_2s", &"puxao_vinhas_90px"],
				"raio_secundario_px": 340.0,
			},
			{
				"chave_nome": &"PAT_FISSURA_DA_COROA",
				"forma_telegrafo": &"setor",
				"dimensoes": {&"raio_px": 460.0, &"meio_angulo_graus": 180.0, &"laminas": 6.0},
				"preparo_s": 0.95,
				"execucao_s": 0.35,
				"recarga_s": 3.20,
				"dano": 30.0,
				"efeitos": [&"expoe_nucleo_vulneravel_1_75x"],
				"raio_secundario_px": 460.0,
			},
		],
	},
	"espolio": [
		{"id": "nucleo_de_espinho", "nome": "Núcleo de Espinho", "raridade": "raro", "tipo": "material_boss"},
		{"id": "casca_espinhosa", "nome": "Casca Espinhosa", "raridade": "incomum", "tipo": "material_boss"},
	],
}
```

---

### Bloco 1.2 — Planta / Layout Tático da Arena (`colina_raizes_profundas`)

```text
  0         400       800       1200      1600      2000      2400      2800 (X)
0 +-------------------------------------------------------------------------+
  | ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ [ PORTAL ] ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ |  Y=78
  | ~ ~ ~ . - - - - - - - - - - - - - - - - - - - - - - - - - - - - . ~ ~ ~ |
  | ~ ~ /    Solo de Raízes (Perigo: vibração acumula emboscada)     \ ~ ~  |
400 ~ /         [L4]                                 [L5]              \ ~  |  Y=460
  | ~|       (1010,460)                           (1790,460)            |~  |
  | ~|         r=115                                r=115               |~  |
  | ~|    (E3)                                                (E4)      |~  |  Y=650
  | ~|  (740,650)                                          (2060,650)   |~  |
800 ~|                   . - - - - - - - - - - .                        |~  |
  | ~|                  /    * BOSS CENTRAL *   \                       |~  |  Y=880
  | ~|      [L2]       |  Devorador (1400,880)   |        [L3]          |~  |
  | ~|   (820,980)     |     r=110 (Estático)    |     (1980,980)       |~  |  Y=980
  | ~|     r=120        \   Núcleo Expõe Fissura/         r=120         |~  |
1200 |                   ' - - - - - - - - - - '                        |~  |
  | ~|         (E1)                                      (E2)           |~  |  Y=1270
  | ~ \     (980,1270)                                (1820,1270)      / ~  |
  | ~ ~ \                      [ L1 - ENTRADA ]                      / ~ ~  |  Y=1460
  | ~ ~ ~ ' - - - - - - - - - - (1400, 1460) - - - - - - - - - - - ' ~ ~ ~  |  P=(1400,1480)
1760+-----------------------------------------------------------------------+ (Y)

Legenda:
  ~ ~  Borda de floresta podre / raízes intransponíveis (Moldura L* 0-10)
  [L1..L5] 5 Lajes de Pedra Antiga (Zonas Seguras sem detecção de raízes)
  (E1..E4) 4 Bolsões de Esporos (Névoa periódica dissipável por fogo/vento/Selo)
  P = Spawn Jogador (1400, 1480) | BOSS = Devorador da Coroa de Espinhos (1400, 880)
```

| Elemento | ID | Categoria | Coordenadas `(x, y)` | Raio / Dimensão | Papel Tático / Sightline |
|---|---|---|---|---|---|
| Spawn Jogador | `spawn_p1` | Spawn | `(1400, 1480)` | `r = 27 px` | Nasce seguro sobre L1 com linha de visão limpa até o boss |
| Spawn Boss | `devorador` | Boss Estático | `(1400, 880)` | `r = 110 px` | Ancorado no centro exato; bloqueia passagem central direta |
| Laje Sul (Entrada) | `laje_sul` | Zona Segura | `(1400, 1460)` | `r = 130 px` | Zera vibração; distância `580 px` ao centro (fora de *Aperto Devorador*) |
| Laje Oeste | `laje_oeste` | Zona Segura | `(820, 980)` | `r = 120 px` | Rotação anti-horária; `318 px` borda-a-borda até `laje_noroeste` |
| Laje Leste | `laje_leste` | Zona Segura | `(1980, 980)` | `r = 120 px` | Rotação horária simétrica à `laje_oeste` |
| Laje Noroeste | `laje_noroeste` | Zona Segura | `(1010, 460)` | `r = 115 px` | Flanco superior esquerdo; alcance ótimo para punir *Fissura da Coroa* |
| Laje Nordeste | `laje_nordeste` | Zona Segura | `(1790, 460)` | `r = 115 px` | Flanco superior direito; próximo ao portal de saída |
| Solo de Raízes | `solo_raizes_geral` | Perigo Contínuo | Toda elipse fora de L1–L5 | `1180 × 760 px` | Acumula vibração ao caminhar/correr e dispara emboscada de vinhas |
| Bolsão Sudoeste | `esporo_sw` | Perigo Periódico | `(980, 1270)` | `r = 135 px` | Corta corredor direto `L1 → L2`; contornável pela borda externa |
| Bolsão Sudeste | `esporo_se` | Perigo Periódico | `(1820, 1270)` | `r = 135 px` | Corta corredor direto `L1 → L3` |
| Bolsão Noroeste | `esporo_nw` | Perigo Periódico | `(740, 650)` | `r = 135 px` | Pressiona trânsito `L2 → L4` |
| Bolsão Nordeste | `esporo_ne` | Perigo Periódico | `(2060, 650)` | `r = 135 px` | Pressiona trânsito `L3 → L5` |

---

### Bloco 1.3 — Configuração das Mecânicas Ambientais (`colina_raizes_profundas`)

Todas as regras abaixo executam no passo fixo de `60 Hz` (`1 s = 60 ticks`), **sem RNG**:

1. **Sensor de Raízes & Solo de Raízes (Determinístico por Acúmulo):**
   - **Gatilho:** Enquanto o jogador está sobre `solo_raizes_geral` (fora das 5 Lajes e **não** em estado de `esquiva` ou salto), `acum_vibracao` sobe **`+1` por tick em caminhada normal** (limiar = **`72 ticks` / `1,20 s`**) ou **`+1,5` por tick** se estiver atacando/sprintando sobre a terra.
   - **Zonas Seguras (5 Lajes):** Em qualquer Laje (`dist(pos, laje.centro) <= laje.r`), `acum_vibracao` não sobe e decai **`-2` por tick** (`0,60 s` para limpar completamente).
   - **Telegráfico da Emboscada:** Ao atingir `72 ticks`, o contador reinicia para `0` e spawna uma **Emboscada de Vinhas** na posição prevista do jogador: círculo SDF magenta de `r = 95 px` com **`0,55 s` (`33 ticks`) de preparo** antes de irromper.
   - **Efeito / Contra-jogada:** Atingir causa `14` de dano e aplica `Enraizamento` por `0,80 s` (`48 ticks`). Alternar `corrida curta (< 0,70 s) + esquiva (202,5 px)` de Laje em Laje mantém `acum_vibracao < 50`, anulando 100% das emboscadas sem punir travessias ágeis.
2. **4 Bolsões de Esporos (`esporo_sw/se/nw/ne`):**
   - **Ciclo Determinístico:** Os 4 bolsões alternam ativação em pares opostos a cada **`12,0 s` (`720 ticks`)**:
     - `Ciclo Par (ticks 0..719 mod 1440)`: ativos `esporo_sw` + `esporo_ne` (`8,0 s / 480 ticks` ativos, `4,0 s / 240 ticks` dormentes).
     - `Ciclo Ímpar (ticks 720..1439 mod 1440)`: ativos `esporo_se` + `esporo_nw`.
     - Em **Fase 2 (`HP ≤ 925`)**, os 4 bolsões entram em `10,0 s ativo / 4,0 s dormente` com defasagem em cascata (`0, 180, 360, 540 ticks`).
   - **Telegráfico e Efeito:** `1,00 s` (`60 ticks`) de borbulho orgânico magenta-acinzentado na crosta (`L* ≤ 45`) antes de liberar a nuvem (`r = 135 px`). Entrar na nuvem ativa aplica `4 dmg/s` (tick a cada `30 passos = 2 dmg`) + `-20%` velocidade de movimento.
   - **Contra-jogada / Dissipação:** Acertar o centro do bolsão com **Selo `[Q]`**, ataque com tag `fogo` (ex.: bênçãos de Queimadura) ou projétil/golpe com tag `vento` **dissipa instantaneamente** o bolsão por **`16,0 s` (`960 ticks`)**.
3. **Ciclo de Padrões do Boss (`devorador_coroa_espinhos`):**
   - Rotação determinística `0 → 1 → 2 → 3 → 0...`:
     1. *Miragem de Esporos* (`0,80 s` preparo): marca `3` círculos (`r = 145 px`) sobre as 3 lajes mais próximas do jogador, forçando troca imediata de Laje.
     2. *Chicote de Agulhas* (`0,60 s` preparo): retângulo de `132 × 720 px` na direção travada + leque de `3` agulhas rápidas (`420 px/s`).
     3. *Aperto Devorador* (`0,75 s` preparo): anel médio `120–340 px` que puxa em `90 px` quem estiver na terra e deixa zona de espinhos por `2,0 s`.
     4. *Fissura da Coroa* (`0,95 s` preparo): o boss abre `6` pétalas em lâmina causando dano em setor `460 px` (`30 dmg`) e entra em **Núcleo Central Exposto por `3,20 s` (`192 ticks`)**, recebendo **`1,75×` de dano** e zerando sua mitigação de casca (`0,65×` fora da janela → `1,75×` na janela).
   - **Fase 2 (`HP ≤ 925`):** Transição invulnerável de `0,60 s` (`36 ticks`) com pulso repulsor (`r = 260 px`, sem dano); recargas reduzem para `× 0,70`, *Fissura da Coroa* abre janela de `2,50 s` (`150 ticks`) e dispara `6` esporos lentos nas bordas ao fechar.

---

### Bloco 1.4 — Lista de Assets Necessários (`colina_raizes_profundas`)

- **`arena_bg` (Chunks `≤ 2048×2048`):**
  - `res://assets/art/environment/colina_raizes_profundas/arena_bg_nw_1x.png` (`1640×1600`)
  - `res://assets/art/environment/colina_raizes_profundas/arena_bg_ne_1x.png` (`1640×1600`)
  - `res://assets/art/environment/colina_raizes_profundas/arena_bg_sw_1x.png` (`1640×1600`)
  - `res://assets/art/environment/colina_raizes_profundas/arena_bg_se_1x.png` (`1640×1600`)
  - *(Nota Art Bible §8.5/§8.6: solo em turfa fria `#1A241E` com `L* 22–34` e zero verde `#00FF00` saturado; bordas em paredão de raízes entrelaçadas `#0D0E14` / `#2A3A2F`).*
- **Tiles / Zonas de Terreno:**
  - `env_colina_solo_raizes_01_2x.png` e `_02_2x.png` (`512×512`, textura orgânica de raízes finas sem círculos geométricos).
  - `env_colina_laje_antiga_01_2x.png` e `_02_2x.png` (`512×512`, contorno `3 px` `#0D0E14` em pedras planas secas, valor `L* 36` destacado sutilmente da turfa `L* 24`).
- **Props de Storytelling (Lore Freeze P5):**
  - `prp_colina_toco_podre_01_2x.png` (`256×256`), `prp_colina_raiz_arco_01_2x.png` (`384×320`), `prp_colina_marcos_pedra_01_2x.png` (`192×192`, pedra lascada sem texto/rosto).
- **Objetos Interativos / Portas:**
  - `prp_colina_portal_norte_2x.png` (`384×512`, arco de pedra coberto de raízes secas com halo dourado `#E3B23C` ao limpar a sala).
- **Sprites / Partes do Boss (`~8 m`, traço `3,5 px` 1× / `7 px` 2×):**
  - Atlas `bos_devorador_coroa_sheet_2x.png` + `bos_devorador_coroa_frames_v01.tres`:
    - Base enraizada estática (`640×512` em `1×` / `1280×1024` em `2×`);
    - `6` pétalas-lâmina articuladas (`rig 2D`: fechadas vs. abertas em flor cortante);
    - Núcleo central emissor (`#E0259C` exposto apenas em `Fissura da Coroa`, `L* ≤ 70`);
    - Animações obrigatórias: `spawn`, `idle`, `windup_esporo`, `windup_chicote`, `windup_aperto`, `attack`, `fissura_aberta`, `recover`, `hurt`, `death`.
- **VFX Ambientais & Indicadores de Perigo:**
  - `vfx_colina_nevoa_baixa_mask.png` (`512×256` P3 tons de cinza, colorida no shader para `#3B4943` musgo dessaturado `G - max(R,B) ≤ 50`, apenas nas bordas).
  - `vfx_colina_esporos_flipbook_2x.png` (`512×512`, 8 quadros de névoa orgânica `#5C5470` / `#E0259C` `L* ≤ 45`, sem borda grossa).
  - `vfx_colina_vinha_emboscada_2x.png` (flipbook 6 quadros de vinhas negras `#0D0E14` com espinhos).
  - Indicador passivo de *Sensor de Raízes*: arco tracejado em `#CFC6B4` ao redor dos pés do jogador com preenchimento de alerta `#E0259C` proporcional a `acum_vibracao / 72` (nunca sólido/fechado para não confundir com telégrafo).

---

## Mapa 2 — `costa_abissal` · Costa Abissal (Cais da Água Negra)

### Ficha de Level Design e Fluxo da Câmara
- **ID da Região / Arena:** `costa_abissal` (`Cais da Água Negra`)
- **Boss:** **Leviatã da Maré Morta** (`leviata_mare_morta`) · `Rank A+` · Nível `48` · Colosso Aquático / Predador de Pressão · Escala Colossal `~32 m` (emerge e submerge)
- **Tema e Atmosfera:** Orla costeira ampla sob céu de tempestade imóvel; sequência de píeres de madeira negra quebrados ao sul, três bancos de areia centrais inundáveis, dois recifes elevados ao norte e três quebra-mares com restos de faróis apagados cercando águas abissais escuras.
- **Tempo Estimado de Combate:** `3 min 45 s – 4 min 45 s` (`~13.500 – 17.100` ticks vivos)
- **Rumo Crítico (Critical Path):** Nascer no **Píer Principal Sul** `(1700, 1690)` → avançar para o **Banco de Areia Central** durante a Maré Baixa posicionando-se junto aos **3 Quebra-Mares / Pilares de Farol** → atrair *Investida Quebra-Maré* contra um Quebra-Mar para atordoar/desviar a trajetória do colosso → usar o ângulo seguro ao lado dos pilares para golpear as **Fissuras Azuis Brilhantes** dorsais do Leviatã (`2,0×` dano e cancela *Ruptura de Pressão*) → recuar para os **2 Recifes Elevados** ou Píeres durante a **Maré Alta de Tempestade** → sobreviver a *Espiral das Profundezas* e finalizar o abate.
- **Rotas Opcionais / Maestria:** Jogadores com múltiplas cargas de esquiva ou alta velocidade podem atravessar os canais entre `Píer Oeste ↔ Banco Oeste ↔ Recife NW` antes da subida da maré para atacar a cauda ou o flanco exposto antes que o boss gire após *Investida Quebra-Maré*.
- **Curva de Ritmo (Pacing Chart):**
  - `0–20 s` *(Maré Baixa Inicial)*: Intensidade `2 → 3` — píeres, bancos de areia e recifes totalmente secos; o Leviatã rompe a superfície norte `(1700, 380)` com *Rugido Abissal*.
  - `20–56 s` *(Ciclo 1 — Submersão & Investida)*: Intensidade `4` — o Leviatã submerge (`sombra 32 m` deslizando), emerge em *Investida Quebra-Maré* e dispara *Ruptura de Pressão*.
  - `56–80 s` *(Maré Alta / Tempestade 1)*: Intensidade `5` — os 3 Bancos de Areia inundam; *Instinto da Tempestade* ativa (`+18%` velocidade de jatos e velocidade submersa); disputa concentrada nos 2 Recifes e Píeres.
  - `80–160 s` *(Vazante → Fase 2 `≤ 50% HP`)*: Intensidade `4 → 5` — na Fase 2, o ciclo de tempestade acelera e o boss encadeia *Rugido Abissal* direto para *Espiral das Profundezas*.
  - `160–240 s` *(Clímax)*: Intensidade `5` — quebra coordenada de fissuras azuis a partir do Farol Central ou Recifes até zerar o HP.
- **Beats Narrativos (Lore Freeze P5):**
  1. Os **3 Pilares de Farol** têm bacias de bronze corroído que nunca acenderam com óleo da Academia — arquitetura costeira sem época definida.
  2. Píeres partidos apontam para o mar aberto onde a névoa apaga o horizonte, sem navios nem inscrições legíveis.
- **Cues de Música / Áudio:**
  - *Maré Baixa:* marola pesada + madeirame rangendo (`60%` intensidade).
  - *Aviso de Maré Alta (`3,0 s` antes):* trovão surdo contínuo + assobio de vento marinho subindo em filtro passa-alta.
  - *Submersão do Leviatã:* corte subaquático breve (`low-pass 450 Hz`) enquanto a sombra gigante desliza sob a água negra.
  - *Fissura Azul Quebrada:* estilhaço cristalino agudo + rugido abafado de descompressão.

---

### Bloco 2.1 — Estrutura de Dados do Mapa (`costa_abissal`)

| Campo | Valor Canônico |
|---|---|
| `region_id` / `arena_id` | `costa_abissal` / `arena_costa_abissal` |
| `largura` × `altura` | `3400.0 × 1920.0 px` |
| `camera_zoom` | `0.92` (visível `16:9`: `2087×1174 px`; `43:18`: `2804×1174 px`) |
| `spawn_jogador` | `(1700.0, 1690.0)` — sobre o Píer Principal Sul |
| `spawn_chefe` | `(1700.0, 380.0)` — Bacia Abissal Norte |
| `chefe_id` | `leviata_mare_morta` (`Rank A+`, Nível `48`, `3600 HP`, `raio_px = 135.0` cabeça, `~32 m` modular) |
| `espolio` | `nucleo_abissal` (`Núcleo Abissal`) + `escama_de_ruina` (`Escama de Ruína`) |

```gdscript
const MAPA_COSTA_ABISSAL: Dictionary = {
	"region_def": {
		"id": &"costa_abissal",
		"chave_nome": &"REG_COSTA_ABISSAL_NOME",
		"camaras": [&"combate", &"emboscada", &"santuario_cura", &"combate_denso", &"altar_pacto", &"elite_guarda", &"chefe"],
		"pool_inimigos": [&"vulto_mudo", &"espreitador_da_fenda", &"anomalia_menor"],
		"chefe": &"leviata_mare_morta",
		"fragmentos_chefe": 28,
	},
	"arena": {
		"id": "arena_costa_abissal",
		"formato": "costeira_modular",
		"largura": 3400.0,
		"altura": 1920.0,
		"margem": 140.0,
		"camera_zoom": 0.92,
		"spawn_jogador": Vector2(1700.0, 1690.0),
		"spawn_chefe": Vector2(1700.0, 380.0),
		"portal_saida": Vector2(1700.0, 78.0),
		"paleta": {
			"bg": Color("070c14"),
			"floor": Color("15202e"),
			"accent": Color("38bdf8"),
			"border": Color("2a3b4f"),
			"motif": "costa",
		},
		"pilares": [
			{"id": "quebramar_sw", "tipo": "quebra_mar_farol", "x": 1160.0, "y": 1340.0, "r": 58.0, "bloqueia_investida": true},
			{"id": "quebramar_se", "tipo": "quebra_mar_farol", "x": 2240.0, "y": 1340.0, "r": 58.0, "bloqueia_investida": true},
			{"id": "farol_norte_central", "tipo": "pilar_farol", "x": 1700.0, "y": 680.0, "r": 64.0, "bloqueia_investida": true},
		],
		"zonas_seguras": [
			{"id": "pier_sul_principal", "tipo": "pier_elevado", "forma": "rect", "x": 1700.0, "y": 1670.0, "largura": 1160.0, "altura": 300.0, "sempre_seco": true},
			{"id": "pier_oeste", "tipo": "pier_elevado", "forma": "rect", "x": 630.0, "y": 1320.0, "largura": 580.0, "altura": 400.0, "sempre_seco": true},
			{"id": "pier_leste", "tipo": "pier_elevado", "forma": "rect", "x": 2770.0, "y": 1320.0, "largura": 580.0, "altura": 400.0, "sempre_seco": true},
			{"id": "recife_nw", "tipo": "recife_elevado", "forma": "circulo", "x": 880.0, "y": 560.0, "r": 230.0, "sempre_seco": true},
			{"id": "recife_ne", "tipo": "recife_elevado", "forma": "circulo", "x": 2520.0, "y": 560.0, "r": 230.0, "sempre_seco": true},
			{"id": "banco_areia_centro", "tipo": "banco_areia", "forma": "circulo", "x": 1700.0, "y": 1060.0, "r": 260.0, "inundavel_mare_alta": true},
			{"id": "banco_areia_oeste", "tipo": "banco_areia", "forma": "circulo", "x": 1160.0, "y": 1020.0, "r": 180.0, "inundavel_mare_alta": true},
			{"id": "banco_areia_leste", "tipo": "banco_areia", "forma": "circulo", "x": 2240.0, "y": 1020.0, "r": 180.0, "inundavel_mare_alta": true},
		],
		"zonas_perigo": [
			{"id": "agua_profunda_norte", "tipo": "agua_profunda", "forma": "rect", "x": 1700.0, "y": 240.0, "largura": 3200.0, "altura": 420.0},
			{"id": "fossa_agua_negra", "tipo": "agua_profunda", "forma": "fundo_base_costeiro", "x": 1700.0, "y": 960.0, "r": 1700.0},
		],
		"obstaculos_destrutiveis": [],
		"interativos": [],
	},
	"enemy_def": {
		"id": &"leviata_mare_morta",
		"chave_nome": &"BOSS_LEVIATA_MARE_NOME",
		"rank": "A+",
		"nivel": 48,
		"arquetipo": "colosso_aquatico_pressao",
		"comportamento": &"chefe",
		"vida": 3600.0,
		"velocidade": 210.0,
		"velocidade_submersa": 340.0,
		"raio_px": 135.0,
		"comprimento_total_px": 1600.0,
		"dano": 26.0,
		"alcance_px": 1400.0,
		"preparo_s": 0.85,
		"recarga_s": 1.35,
		"velocidade_projetil": 560.0,
		"custo_onda": 0,
		"padroes": [
			{
				"chave_nome": &"PAT_INVESTIDA_QUEBRA_MARE",
				"forma_telegrafo": &"retangulo",
				"dimensoes": {&"largura_px": 270.0, &"comprimento_px": 1520.0},
				"preparo_s": 0.90,
				"execucao_s": 0.65,
				"recarga_s": 1.60,
				"dano": 34.0,
				"efeitos": [&"deslize_colosso", &"para_em_quebramar_expoe_fissuras"],
				"raio_secundario_px": 0.0,
			},
			{
				"chave_nome": &"PAT_RUPTURA_PRESSAO",
				"forma_telegrafo": &"retangulo",
				"dimensoes": {&"largura_px": 110.0, &"comprimento_px": 1280.0, &"feixes_fissuras": 4.0},
				"preparo_s": 0.75,
				"execucao_s": 0.30,
				"recarga_s": 1.30,
				"dano": 26.0,
				"efeitos": [&"jatos_agua_comprimida", &"abre_fissuras_azuis_vulneraveis"],
				"raio_secundario_px": 0.0,
			},
			{
				"chave_nome": &"PAT_RUGIDO_ABISSAL",
				"forma_telegrafo": &"anel",
				"dimensoes": {&"raio_int_px": 140.0, &"raio_ext_px": 620.0},
				"preparo_s": 0.85,
				"execucao_s": 0.35,
				"recarga_s": 1.50,
				"dano": 24.0,
				"efeitos": [&"empurrao_180px_agua", &"ativa_onda_mare"],
				"raio_secundario_px": 620.0,
			},
			{
				"chave_nome": &"PAT_ESPIRAL_PROFUNDEZAS",
				"forma_telegrafo": &"circulo",
				"dimensoes": {&"raio_px": 310.0, &"espiral_bracos": 3.0},
				"preparo_s": 1.05,
				"execucao_s": 0.80,
				"recarga_s": 2.20,
				"dano": 32.0,
				"efeitos": [&"submerge_vortice", &"puxao_agua_profunda_amplificado"],
				"raio_secundario_px": 540.0,
			},
		],
	},
	"espolio": [
		{"id": "nucleo_abissal", "nome": "Núcleo Abissal", "raridade": "epico", "tipo": "material_boss"},
		{"id": "escama_de_ruina", "nome": "Escama de Ruína", "raridade": "raro", "tipo": "material_boss"},
	],
}
```

---

### Bloco 2.2 — Planta / Layout Tático da Arena (`costa_abissal`)

```text
  0        500       1000      1500      2000      2500      3000     3400 (X)
0 +------------------------------------------------------------------------+
  | ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ [ PORTAL ] ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ | Y=78
  | ~~~ ÁGUA PROFUNDA NORTE (Leviatã emerge/submerge aqui) ~~~~~~~~~~~~~~~ |
  |               ** BOSS: Leviatã da Maré Morta (1700, 380) **            | Y=380
400   . - - - - .                                            . - - - - .   |
  |  /  RECIFE   \             (F) FAROL NORTE              /  RECIFE   \  | Y=560
  | |    NW       |             (1700, 680)                |    NE       | |
  |  \ (880,560) /                 r=64                     \ (2520,560)/  |
800   ' - - - - '                                            ' - - - - '   |
  |     (Água)        . - - .      . - - - - .      . - - .     (Água)     |
  |                  / BANCO \    /   BANCO   \    / BANCO \               | Y=1020/1060
  |   +---------+   |  OESTE  |  |   CENTRAL   |  |  LESTE  |  +---------+ |
1200  |  PÍER   |   |1160,1020|  |(1700, 1060) |  |2240,1020|  |  PÍER   | |
  |   |  OESTE  |    \ r=180 /    \   r=260   /    \ r=180 /   |  LESTE  | |
  |   |(630,1320|   (Q1)           ' - - - - '           (Q2)  |(2770,1320)| Y=1340
  |   +---------+ (1160,1340)                         (2240,1340)+---------+
1600                 +-----------------------------------+                 |
  |                  |       PÍER PRINCIPAL SUL          |                 | Y=1670
  |                  |     (1700, 1670) · 1160x300       |                 |
  |                  |           P = (1700, 1690)        |                 |
1920+----------------------------------------------------------------------+ (Y)

Legenda:
  ~~~  Água Profunda (Perigo constante; piora na Tempestade)
  RECIFE / PÍER = Solo firme permanente (sempre acima da Maré Alta)
  BANCO = Bancos de Areia (secos na Maré Baixa; submergem na Maré Alta)
  (Q1), (Q2), (F) = 3 Quebra-Mares e Pilares de Farol (Contramedida sólida)
```

| Elemento | ID | Categoria | Coordenadas `(x, y)` | Raio / Dimensão | Papel Tático / Sightline |
|---|---|---|---|---|---|
| Spawn Jogador | `spawn_p2` | Spawn | `(1700, 1690)` | `r = 27 px` | Centro do Píer Principal Sul; visão completa da baía norte |
| Spawn Boss | `leviata` | Boss Colossal | `(1700, 380)` | `r = 135 px` (`~32 m` arco) | Bacia norte profunda; alterna submersão e emergências cardeais |
| Píer Sul Principal | `pier_sul_principal` | Solo Firme | `(1700, 1670)` | `1160 × 300 px` | Base inicial segura contra Maré Alta |
| Píer Oeste / Leste | `pier_oeste` / `pier_leste` | Solo Firme | `(630, 1320)` / `(2770, 1320)` | `580 × 400 px` cada | Flancos estáveis para tempestade; pontes de madeira até o píer sul |
| Recife NW / NE | `recife_nw` / `recife_ne` | Solo Firme | `(880, 560)` / `(2520, 560)` | `r = 230 px` cada | Pontos altos frente ao boss; ângulo limpo nas fissuras dorsais |
| Banco Central | `banco_areia_centro` | Solo Inundável | `(1700, 1060)` | `r = 260 px` | Encurralamento tático: seco na vazante, inundado na Maré Alta |
| Bancos Oeste / Leste | `banco_areia_oeste/leste` | Solo Inundável | `(1160, 1020)` / `(2240, 1020)` | `r = 180 px` cada | Conectam píeres aos recifes na Maré Baixa |
| Quebra-Mar SW | `quebramar_sw` | Pilar Contramedida | `(1160, 1340)` | `r = 58 px` | Barra *Investida Quebra-Maré* e cria cobertura vs. *Ruptura de Pressão* |
| Quebra-Mar SE | `quebramar_se` | Pilar Contramedida | `(2240, 1340)` | `r = 58 px` | Contramedida espelhada do lado leste |
| Farol Norte Central | `farol_norte_central` | Pilar Contramedida | `(1700, 680)` | `r = 64 px` | Ilha rochosa central que interrompe o bote frontal do Leviatã |

---

### Bloco 2.3 — Configuração das Mecânicas Ambientais (`costa_abissal`)

1. **Ciclo Determinístico de Maré Dinâmica / Clima (`60 Hz`):**
   - Ciclo total de **`48,0 s` (`2.880 ticks`)**:
     - **Fase A — Maré Baixa (`ticks 0..1439` / `24,0 s`):** Todos os `3` Bancos de Areia permanecem secos e seguros.
     - **Fase B — Aviso de Enchente (`ticks 1440..1679` / `4,0 s`):** Espuma branca/osso avança na orla dos bancos de areia e trovões marcam a subida sem aplicar penalidade ainda (janela justa de evacuação para Recifes ou Píeres).
     - **Fase C — Maré Alta & Tempestade (`ticks 1680..2639` / `16,0 s`):** Os `3` Bancos de Areia viram **Água Profunda**, e a passiva ***Instinto da Tempestade*** ativa automaticamente: velocidade dos projéteis/jatos de *Ruptura de Pressão* sobe `+18%` (`560 → 660 px/s`) e recarga submersa reduz `-25%`.
     - **Fase D — Vazante (`ticks 2640..2879` / `4,0 s`):** Água recua e devolve os bancos de areia antes do próximo ciclo.
     - *(Em Fase 2 `HP ≤ 1800`, o ciclo comprime determinísticamente para `36,0 s`: `14 s` Baixa → `4 s` Aviso → `14 s` Tempestade → `4 s` Vazante.)*
2. **Penalidade da Água Profunda & *Espiral das Profundezas*:**
   - Pisar em `agua_profunda` aplica `fator_velocidade = 0,65`, atrasa a recarga de esquiva em `+35%` e aumenta a força de puxão de *Espiral das Profundezas* de `120 px` para **`240 px`**.
   - Se o jogador permanecer mais de `3,0 s` (`180 ticks`) contínuos em água profunda, o Leviatã prioriza imediatamente *Espiral das Profundezas* no padrão seguinte.
3. **Contramedida dos 3 Quebra-Mares & Fissuras Azuis Brilhantes:**
   - Quando *Investida Quebra-Maré* (`0,90 s` preparo em retângulo de `270 × 1520 px`) colide com `quebramar_sw`, `quebramar_se` ou `farol_norte_central`, o Leviatã **estanca o avanço**, sofre atordoamento lateral de **`2,40 s` (`144 ticks`)** e abre suas **`4` Fissuras Azuis Brilhantes** ao longo do dorso (`lado esquerdo/direito` voltado aos Recifes e Píeres).
   - Golpear os pontos das fissuras a partir de um ângulo protegido pelos Quebra-Mares aplica **`2,0×` de dano** e interrompe a carga de *Ruptura de Pressão*.

---

### Bloco 2.4 — Lista de Assets Necessários (`costa_abissal`)

- **`arena_bg` (Chunks `≤ 2048×2048`, 6 chunks `1940×1480` cobrindo `3400×1920` + sangrias):**
  - `res://assets/art/environment/costa_abissal/arena_bg_nw_1x.png` .. `arena_bg_se_1x.png` (`6` chunks `≤ 2048×2048`).
- **Tiles / Zonas de Terreno:**
  - `env_costa_agua_profunda_01_2x.png` (`512×512`, azul-ardósia noturno `#070C14` / `#15202E` com ondulação pintada em traço `1,5 px`).
  - `env_costa_pier_madeira_01_2x.png` (`512×512`, tábuas escuras desgastadas com pregos de ferro em `#0D0E14`, L* `30–36`).
  - `env_costa_areia_molhada_01_2x.png` + `env_costa_recife_rocha_01_2x.png` (`512×512`).
- **Props de Storytelling:**
  - `prp_costa_quebramar_pedra_2x.png` (`256×320`), `prp_costa_farol_ruina_2x.png` (`256×384`, sem rosto ou emblema), `prp_costa_ancora_ferro_2x.png` (`192×192`), `prp_costa_poste_corda_2x.png` (`128×192`).
- **Objetos Interativos / Portas:**
  - `prp_costa_portal_norte_2x.png` (`384×512`, arco de pedra coberto de cracas que acende em dourado `#E3B23C`).
- **Sprites / Partes do Boss (`~32 m` modular, traço `3,5 px` 1× / `7 px` 2×):**
  - `bos_leviata_cabeca_sheet_2x.png` (`512×384` em `1×` / `1024×768` em `2×`);
  - `bos_leviata_dorso_fissura_sheet_2x.png` (`3` segmentos modulares `384×320` 1× com estado `fechado` e `fissura_azul_aberta` em ciano-magenta para ponto fraco);
  - `bos_leviata_cauda_sheet_2x.png` (`448×320` 1×);
  - `bos_leviata_sombra_submersa_1x.png` (`1024×384`, silhueta opaca `#0D0E14` em `z = -8` que desliza sob a água).
- **VFX Ambientais & Indicadores de Perigo:**
  - `vfx_costa_espuma_mare_mask.png` (`512×256`, máscara P3 animada de subida da maré nos 3 bancos de areia);
  - `vfx_costa_chuva_tempestade_mask.png` (`512×512`, rajadas diagonais finas em `15%` opacidade apenas em `Fase C` — zero obstrução de chão);
  - `vfx_costa_jato_pressao_2x.png` (flipbook 8 quadros de água comprimida `#FFD3EE` / `#7DD3FC`);
  - `vfx_costa_vortice_espiral_2x.png` (flipbook 10 quadros do redemoinho da *Espiral das Profundezas*).

---

## Mapa 3 — `escarpas_copa_quebrada` · Escarpas da Copa Quebrada

### Ficha de Level Design e Fluxo da Câmara
- **ID da Região / Arena:** `escarpas_copa_quebrada` (`Escarpas da Copa Quebrada`)
- **Boss:** **Vigia da Coroa Partida** (`vigia_coroa_partida`) · `Rank A+` · Nível `53` · Bruto de Escarpa / Controlador Multi-Membros · Escala `~20 m`, `~120 t`
- **Tema e Atmosfera:** Complexo verticalizado de falésias partidas e árvores petrificadas suspensas sobre abismos cinza-ardósia: **3 platôs rochosos elevados** (Sul, Oeste, Leste) conectados por **2 pontes estreitas de pedra** ao redor de um vale rebaixado, dominados pela **escarpa norte de observação** onde o Vigia espreita com seis olhos imóveis.
- **Tempo Estimado de Combate:** `4 min 00 s – 5 min 00 s` (`~14.400 – 18.000` ticks vivos)
- **Rumo Crítico (Critical Path):** Nascer no **Platô Sul** `(1600, 1580)` → atravessar uma das **2 Pontes Estreitas** sem ser arremessado pela onda sísmica de *Descida Titânica* → usar os **4 Pilares/Troncos Petrificados (Coberturas Destrutíveis)** nos platôs Oeste/Leste e vale central para absorver *Sobrecarga de Agarrão* → forçar a queda abaixo de `50% HP` (*Renascimento da Coroa*) → subir aos **Platôs Elevados** (Oeste, Leste ou Escarpa Norte) para obter linha de tiro/golpe limpa diretamente na **cabeça vulnerável (`2,2×` dano)** durante a recuperação da metamorfose.
- **Rotas Opcionais / Maestria:** O circuito elevado `Sul → Ponte Oeste → Platô Oeste → Passarela NW → Escarpa Norte → Passarela NE → Platô Leste` forma um **anel completo ao redor do vale central**, permitindo que builds ágeis girem acima das ondas de choque enquanto o boss ocupa o poço central.
- **Curva de Ritmo (Pacing Chart):**
  - `0–15 s` *(Observação)*: Intensidade `3` — *Visão Hexagonal* gira os 6 olhos na escarpa norte `(1600, 420)`, avisando que flanquear costas não reduz rastreamento.
  - `15–105 s` *(Fase 1 — Disputa de Platôs e Destruição de Coberturas)*: Intensidade `4` — o boss usa *Descida Titânica* do pico norte para os platôs e quebra as 4 coberturas com os braços primários.
  - `105–125 s` *(Clímax Intermediário — Renascimento da Coroa)*: Intensidade `5` — `< 50% HP`: crânio ósseo estilhaça em *impact frame*, forma mais feroz regenera e abre janela de `4,0 s` na cabeça exposta (alcançável dos platôs elevados).
  - `125–240 s` *(Fase 2 — Arena Aberta e Risco de Penhasco)*: Intensidade `5` — poucas ou zero coberturas restantes; ondas sísmicas em dobro testam posicionamento longe das beiradas.
- **Beats Narrativos (Lore Freeze P5):**
  1. Os **troncos petrificados** são restos de copas antigas calcificadas pela Beira, sem marcas de machado ou língua humana.
  2. Os **6 olhos** da máscara óssea não têm pálpebras nem expressão — apenas lentes opacas de vigilância que se estilhaçam aos `50% HP`, revelando um crânio mais jovem e feroz por baixo.
- **Cues de Música / Áudio:**
  - *Ambiente:* assobio constante de vento entre abismos (`band-pass` em `320 Hz`).
  - *Combate Fase 1:* tambores graves espaçados (`92 BPM`) + estalo pétreo sincronizado com passos do colosso de `120 t`.
  - *Renascimento da Coroa (`50% HP`):* estilhaço ósseo agudo seguido de coro grave metálico em `118 BPM`.

---

### Bloco 3.1 — Estrutura de Dados do Mapa (`escarpas_copa_quebrada`)

| Campo | Valor Canônico |
|---|---|
| `region_id` / `arena_id` | `escarpas_copa_quebrada` / `arena_escarpas_copa` |
| `largura` × `altura` | `3200.0 × 1880.0 px` |
| `camera_zoom` | `0.94` (visível `16:9`: `2043×1149 px`; `43:18`: `2745×1149 px`) |
| `spawn_jogador` | `(1600.0, 1580.0)` — centro do Platô Sul |
| `spawn_chefe` | `(1600.0, 420.0)` — Escarpa Norte de Observação |
| `chefe_id` | `vigia_coroa_partida` (`Rank A+`, Nível `53`, `4200 HP`, `raio_px = 115.0` corpo + `2` braços `r = 62.0`) |
| `espolio` | `nucleo_da_coroa` (`Núcleo da Coroa`) + `placa_coroa_regenerada` (`Placa de Coroa Regenerada`) |

```gdscript
const MAPA_ESCARPAS_COPA: Dictionary = {
	"region_def": {
		"id": &"escarpas_copa_quebrada",
		"chave_nome": &"REG_ESCARPAS_COPA_NOME",
		"camaras": [&"combate", &"emboscada", &"santuario_cura", &"combate_denso", &"altar_pacto", &"elite_guarda", &"chefe"],
		"pool_inimigos": [&"espreitador_da_fenda", &"baluarte_de_cinza", &"fenda_errante"],
		"chefe": &"vigia_coroa_partida",
		"fragmentos_chefe": 32,
	},
	"arena": {
		"id": "arena_escarpas_copa",
		"formato": "escarpas_verticalizadas",
		"largura": 3200.0,
		"altura": 1880.0,
		"margem": 160.0,
		"camera_zoom": 0.94,
		"spawn_jogador": Vector2(1600.0, 1580.0),
		"spawn_chefe": Vector2(1600.0, 420.0),
		"portal_saida": Vector2(1600.0, 78.0),
		"paleta": {
			"bg": Color("0d0f17"),
			"floor": Color("242936"),
			"accent": Color("d4a373"),
			"border": Color("41485c"),
			"motif": "escarpas",
		},
		"plataformas": [
			{"id": "plato_sul", "elevacao": 0, "forma": "rect", "x": 1600.0, "y": 1560.0, "largura": 1080.0, "altura": 400.0},
			{"id": "vale_central", "elevacao": 0, "forma": "rect", "x": 1600.0, "y": 950.0, "largura": 960.0, "altura": 740.0},
			{"id": "plato_oeste", "elevacao": 1, "forma": "rect", "x": 660.0, "y": 920.0, "largura": 840.0, "altura": 620.0, "bonus_tiro_cabeca": true},
			{"id": "plato_leste", "elevacao": 1, "forma": "rect", "x": 2540.0, "y": 920.0, "largura": 840.0, "altura": 620.0, "bonus_tiro_cabeca": true},
			{"id": "escarpa_norte", "elevacao": 2, "forma": "rect", "x": 1600.0, "y": 380.0, "largura": 1160.0, "altura": 360.0, "pico_observacao": true},
			{"id": "ponte_oeste", "elevacao": 0, "forma": "rect", "x": 980.0, "y": 1300.0, "largura": 320.0, "altura": 170.0, "estreita": true},
			{"id": "ponte_leste", "elevacao": 0, "forma": "rect", "x": 2220.0, "y": 1300.0, "largura": 320.0, "altura": 170.0, "estreita": true},
			{"id": "passarela_nw", "elevacao": 1, "forma": "rect", "x": 1020.0, "y": 540.0, "largura": 240.0, "altura": 170.0},
			{"id": "passarela_ne", "elevacao": 1, "forma": "rect", "x": 2180.0, "y": 540.0, "largura": 240.0, "altura": 170.0},
		],
		"zonas_perigo": [
			{"id": "abismo_oeste", "tipo": "beirada_penhasco", "forma": "borda_externa", "x": 120.0, "y": 940.0, "largura": 240.0, "altura": 1880.0},
			{"id": "abismo_leste", "tipo": "beirada_penhasco", "forma": "borda_externa", "x": 3080.0, "y": 940.0, "largura": 240.0, "altura": 1880.0},
			{"id": "abismo_ponte_sw", "tipo": "beirada_penhasco", "forma": "rect", "x": 980.0, "y": 1460.0, "largura": 260.0, "altura": 150.0},
			{"id": "abismo_ponte_se", "tipo": "beirada_penhasco", "forma": "rect", "x": 2220.0, "y": 1460.0, "largura": 260.0, "altura": 150.0},
		],
		"obstaculos_destrutiveis": [
			{"id": "cob_tronco_central_w", "tipo": "tronco_petrificado", "x": 1260.0, "y": 1060.0, "r": 52.0, "quebra_por": "golpe_braco_primario_boss"},
			{"id": "cob_pilar_central_e", "tipo": "pilar_escarpa", "x": 1940.0, "y": 1060.0, "r": 52.0, "quebra_por": "golpe_braco_primario_boss"},
			{"id": "cob_tronco_plato_w", "tipo": "tronco_petrificado", "x": 740.0, "y": 880.0, "r": 50.0, "quebra_por": "golpe_braco_primario_boss"},
			{"id": "cob_pilar_plato_e", "tipo": "pilar_escarpa", "x": 2460.0, "y": 880.0, "r": 50.0, "quebra_por": "golpe_braco_primario_boss"},
		],
		"interativos": [],
	},
	"enemy_def": {
		"id": &"vigia_coroa_partida",
		"chave_nome": &"BOSS_VIGIA_COROA_NOME",
		"rank": "A+",
		"nivel": 53,
		"arquetipo": "bruto_escarpa_multimembros",
		"comportamento": &"chefe",
		"vida": 4200.0,
		"velocidade": 148.0,
		"raio_px": 115.0,
		"dano": 28.0,
		"alcance_px": 980.0,
		"preparo_s": 0.75,
		"recarga_s": 1.30,
		"velocidade_projetil": 500.0,
		"custo_onda": 0,
		"padroes": [
			{
				"chave_nome": &"PAT_VARREDURA_BRACOS_PRIMARIOS",
				"forma_telegrafo": &"setor",
				"dimensoes": {&"raio_px": 310.0, &"meio_angulo_graus": 110.0},
				"preparo_s": 0.70,
				"execucao_s": 0.25,
				"recarga_s": 1.25,
				"dano": 28.0,
				"efeitos": [&"destroi_cobertura", &"empurrao_160px"],
				"raio_secundario_px": 0.0,
			},
			{
				"chave_nome": &"PAT_SOBRECARGA_AGARRAO",
				"forma_telegrafo": &"retangulo",
				"dimensoes": {&"largura_px": 180.0, &"comprimento_px": 560.0},
				"preparo_s": 0.65,
				"execucao_s": 0.30,
				"recarga_s": 1.40,
				"dano": 32.0,
				"efeitos": [&"agarrao_esmagamento", &"destroi_cobertura"],
				"raio_secundario_px": 0.0,
			},
			{
				"chave_nome": &"PAT_DESCIDA_TITANICA",
				"forma_telegrafo": &"circulo",
				"dimensoes": {&"raio_px": 280.0},
				"preparo_s": 1.00,
				"execucao_s": 0.30,
				"recarga_s": 1.85,
				"dano": 36.0,
				"efeitos": [&"salta_do_pico", &"onda_sismica_520px", &"arremesso_penhasco_260px"],
				"raio_secundario_px": 520.0,
			},
			{
				"chave_nome": &"PAT_RENASCIMENTO_COROA",
				"forma_telegrafo": &"anel",
				"dimensoes": {&"raio_int_px": 0.0, &"raio_ext_px": 410.0},
				"preparo_s": 1.15,
				"execucao_s": 0.45,
				"recarga_s": 4.00,
				"dano": 30.0,
				"efeitos": [&"estilhaca_cranio_osseo", &"janela_critica_cabeca_2_2x"],
				"raio_secundario_px": 410.0,
			},
		],
	},
	"espolio": [
		{"id": "nucleo_da_coroa", "nome": "Núcleo da Coroa", "raridade": "epico", "tipo": "material_boss"},
		{"id": "placa_coroa_regenerada", "nome": "Placa de Coroa Regenerada", "raridade": "raro", "tipo": "material_boss"},
	],
}
```

---

### Bloco 3.2 — Planta / Layout Tático da Arena (`escarpas_copa_quebrada`)

```text
  0        500       1000      1500      2000      2500      3000    3200 (X)
0 +----------------------------------------------------------------------+
  | !!!                     [ PORTAL NORTE ]                        !!!  | Y=78
  | !!!          +----------------------------------+               !!!  |
  | !!!          |   ESCARPA NORTE (Nível +2)       |               !!!  | Y=380
400 !!!   [PasNW]|    BOSS: Vigia (1600, 420)       | [PasNE]       !!!  |
  | !!!  1020,540+------+--------------------+------+2180,540       !!!  |
  | !!!  +--------------+                    +---------------+      !!!  |
  | !!!  | PLATÔ OESTE  |    VALE CENTRAL    |  PLATÔ LESTE  |      !!!  |
800 !!!  |  (Nível +1)  |                    |   (Nível +1)  |      !!!  | Y=880
  | !!!  |  (660, 920)  |  [C1]        [C2]  |  (2540, 920)  |      !!!  |
  | !!!  | [C3](740,880)|1260,1060  1940,1060| [C4](2460,880)|      !!!  | Y=1060
  | !!!  +------+-------+                    +-------+-------+      !!!  |
1200!!!        /  PONTE OESTE          PONTE LESTE    \             !!!  | Y=1300
  | !!!       |  (980,1300)            (2220,1300)    |             !!!  |
  | !!!       |  !!! (Abismo)    (Abismo) !!!         |             !!!  |
  | !!!       +---------------------------------------+             !!!  |
1600!!!       |      PLATÔ SUL / ENTRADA (Nível 0)    |             !!!  | Y=1580
  | !!!       |              P = (1600, 1580)         |             !!!  |
1880+--------------------------------------------------------------------+ (Y)

Legenda:
  !!!  Beiradas de Penhasco (queda por ondas sísmicas sem resistência a knockback)
  [C1..C4] 4 Coberturas Destrutíveis (quebram com golpes dos braços primários)
  Nível +1 / +2 = Terreno Elevado (concede linha de tiro limpa à cabeça no Renascimento)
```

| Elemento | ID | Categoria | Coordenadas `(x, y)` | Raio / Dimensão | Papel Tático / Sightline |
|---|---|---|---|---|---|
| Spawn Jogador | `spawn_p3` | Spawn | `(1600, 1580)` | `r = 27 px` | Centro do Platô Sul; escolhe ponte Oeste ou Leste para subir |
| Spawn Boss | `vigia` | Boss | `(1600, 420)` | `r = 115 px` (`~20 m`) | Escarpa Norte; visão panorâmica 360° via *Visão Hexagonal* |
| Platô Oeste / Leste | `plato_oeste` / `plato_leste` | Terreno Elevado (`+1`) | `(660, 920)` / `(2540, 920)` | `840 × 620 px` | Altura ideal para mirar/atacar a cabeça em *Renascimento da Coroa* |
| Escarpa Norte | `escarpa_norte` | Terreno Elevado (`+2`) | `(1600, 380)` | `1160 × 360 px` | Pico usado pelo boss para lançar *Descida Titânica* |
| Pontes Estreitas | `ponte_oeste` / `ponte_leste` | Gargalo / Risco | `(980, 1300)` / `(2220, 1300)` | `320 × 170 px` | Largura `170 px` com penhasco em ambos os lados |
| Cobertura 1 e 2 | `cob_tronco_central_w` / `cob_pilar_central_e` | Destrutível | `(1260, 1060)` / `(1940, 1060)` | `r = 52 px` | Quebram com 1 ataque dos braços primários no vale central |
| Cobertura 3 e 4 | `cob_tronco_plato_w` / `cob_pilar_plato_e` | Destrutível | `(740, 880)` / `(2460, 880)` | `r = 50 px` | Abrigo nos platôs elevados até o boss pular e destruir |

---

### Bloco 3.3 — Configuração das Mecânicas Ambientais (`escarpas_copa_quebrada`)

1. **Passiva *Visão Hexagonal* (Anulação de Flanqueamento):**
   - Os `6` olhos cobrem setores de `60°` contíguos (`360°` completos). Bônus de dano pelas costas são anulados (`× 1,0`) e a trava de mira do início do `Preparo` sempre enxerga qualquer quadrante.
   - **Contra-jogada:** A única forma de reduzir o rastreamento é aproveitar os **`4` Pilares/Troncos Petrificados** (bloqueiam linha de visão de *Sobrecarga de Agarrão* enquanto intactos) ou usar a janela de recuperação após *Descida Titânica* / *Renascimento da Coroa*.
2. **Disputa de Terreno Elevado (`elevacao +1 / +2`):**
   - **Vantagem do Boss:** A cada `3` padrões na Fase 1 (`2` na Fase 2), o Vigia salta para o ponto mais alto livre (`escarpa_norte` ou `plato_oeste/leste` oposto ao jogador) e prepara *Descida Titânica* (`1,00 s` / `60 ticks` de preparo).
   - **Vantagem do Jogador:** Estar em `elevacao >= 1` (`plato_oeste`, `plato_leste` ou `escarpa_norte`) quando o Vigia cai no vale central ou nos platôs em *Renascimento da Coroa* coloca a hitbox da cabeça no mesmo plano de mira horizontal/descendente, habilitando **acerto direto na cabeça (`2,2×` dano)** por **`4,00 s` (`240 ticks`)** durante a recuperação pós-estilhaçamento.
3. **Beiradas de Penhasco & Onda Sísmica (Determinística):**
   - Ao aterrissar de *Descida Titânica*, emite onda sísmica anelar (`r = 520 px`, expansão `780 px/s`). Quem for atingido sem esquiva ativa nem resistência a knockback sofre **`260 px` de arremesso radial**.
   - Se `pos_final` cruzar a borda de qualquer plataforma/ponte sobre `beirada_penhasco`: aplica **`22` de dano de queda** e executa `Movement.teleport()` para a última coordenada segura firme (`ultimo_chao_firme`), com `0,50 s` (`30 ticks`) de atordoamento de recuperação.
4. **4 Coberturas Destrutíveis:**
   - Cada cobertura tem `estado ∈ {intacta, destruida}` (sem HP parcial complexo). Qualquer execução de *Varredura dos Braços Primários* ou *Sobrecarga de Agarrão* cujo polígono encoste em uma cobertura destrutível altera seu estado para `destruida` no tick do impacto, remove sua colisão do array `arena.pilares` e substitui o sprite por escombro raso (`z = -7`).

---

### Bloco 3.4 — Lista de Assets Necessários (`escarpas_copa_quebrada`)

- **`arena_bg` (Chunks `≤ 2048×2048`, 6 chunks cobrindo `3200×1880` + abismos):**
  - `res://assets/art/environment/escarpas_copa_quebrada/arena_bg_nw_1x.png` .. `arena_bg_se_1x.png`.
- **Tiles / Zonas de Terreno:**
  - `env_escarpas_rocha_plato_01_2x.png` (`512×512`, degraus sombreados de altura em tinta `#0D0E14` e ardósia `#242936` marcando visualmente o nível `+1` e `+2` sem texto).
  - `env_escarpas_ponte_estreita_2x.png` (`384×256`, lajes fendidas com bordas lascadas sobre o vazio).
- **Props de Storytelling & Destrutíveis:**
  - `prp_escarpas_tronco_petrificado_intacto_2x.png` (`256×320`, traço `3 px` bloqueante) + `_destruido_2x.png` (`256×192`, traço `1,5 px` apoio);
  - `prp_escarpas_pilar_intacto_2x.png` (`256×320`) + `_destruido_2x.png` (`256×192`).
- **Sprites / Partes do Boss (`~20 m`, `~120 t`, traço `3,5 px` 1× / `7 px` 2×):**
  - `bos_vigia_torso_sheet_2x.png` (`512×448` em `1×` / `1024×896` em `2×`);
  - `bos_vigia_cabeca_fase1_2x.png` (crânio ósseo com `6` olhos circulares `#E0259C`) e `bos_vigia_cabeca_fase2_2x.png` (coroa regenerada estilhaçada com filete interno pulsante);
  - `bos_vigia_bracos_multi_2x.png` (rig `2D` de `4` braços articulados: `2` primários pesados com garras de esmagamento + `2` secundários de agarre).
- **VFX Ambientais & Indicadores de Perigo:**
  - `vfx_escarpas_onda_sismica_2x.png` (flipbook `8` quadros de anel de poeira pétrea `#CFC6B4` / `#FFD3EE`);
  - `vfx_escarpas_estilhaco_cranio_2x.png` (flipbook `10` quadros em `impact frame` para *Renascimento da Coroa*);
  - Indicadores de beirada de penhasco: hachura de sombra vertical abrupta + partículas de pedregulhos caindo continuamente nas bordas (`z = -7`).

---

## Mapa 4 — `fendas_cinzentas` · Fendas Cinzentas (Fosso-Prisão Antigo)

### Ficha de Level Design e Fluxo da Câmara
- **ID da Região / Arena:** `fendas_cinzentas` (`Fosso-Prisão Antigo`)
- **Boss:** **Tirano Quebra-Grilhões** (`tirano_quebra_grilhoes`) · `Rank S` · Nível `74` · Bruto de Cerco / Juggernaut Imparável · Escala `~25 m`, `~180 t`
- **Tema e Atmosfera:** Grande pátio-prisão retangular em pedra cinzenta pesada (`3500 × 1840`), rasgado por três faixas de correntes metálicas colossais partidas no piso e cercado por quatro **Monolitos de Contenção** rúnicos de aço e basalto, deixando amplos corredores laterais de flanqueamento. *(Nota Art Bible §6.1: arquitetura de contenção monumental antiga sem jaulas da Doutrina de Pactos e sem emblemas institucionais do Campus.)*
- **Tempo Estimado de Combate:** `4 min 15 s – 5 min 15 s` (`~15.300 – 18.900` ticks vivos)
- **Rumo Crítico (Critical Path):** Nascer no portão sul `(1750, 1600)` → sair imediatamente do eixo frontal da primeira *Investida de Compressão* usando os **Corredores Laterais Amplos** (`x < 620` ou `x > 2880`) → evitar ficar preso nas **3 Zonas de Correntes Partidas** (`-22%` velocidade) → posicionar-se atrás de um dos **4 Monolitos de Contenção** para atrair a investida do Tirano → punir os membros atordoados durante os `2,50–3,50 s` de *stagger* (`2,0×` dano) → gerenciar a escalada de poder/velocidade quando o Tirano entrar em *Frenesi Quebra-Grilhões* (`< 50% HP`).
- **Rotas Opcionais / Maestria:** Alternar o uso dos 4 Monolitos em sentido horário (conservando ao menos 2 monolitos intactos para os `< 50% HP`) permite anular os avanços mais rápidos do *Frenesi Quebra-Grilhões* quando a recarga reduz e o arco frontal de *Rasgo do Tirano* fica letal.
- **Curva de Ritmo (Pacing Chart):**
  - `0–15 s` *(Abertura do Cerco)*: Intensidade `3` — correntes no norte se partem; `960 px/s` de ameaça linear anuncia o peso do Juggernaut.
  - `15–110 s` *(Fase 1 — Matador & Touro)*: Intensidade `4` — o jogador conduz o Tirano através das zonas de correntes contra os Monolitos NW/NE/SW/SE.
  - `110–130 s` *(Ruptura — Frenesi Quebra-Grilhões)*: Intensidade `5` — aos `50% HP` (`3200 HP`), elos remanescentes estouram (`+25%` Poder, `+22%` Velocidade, `-30%` recargas).
  - `130–270 s` *(Fase 2 — Fúria de Cerco)*: Intensidade `5` — *Investida de Compressão* passa a encadear `2` avanços consecutivos caso o 1º não colida num Monolito!
- **Beats Narrativos (Lore Freeze P5):**
  1. Os **4 Monolitos de Contenção** têm argolas grossas arrancadas de dentro para fora, mas nenhuma placa diz quem aprisionou o Tirano ou há quanto tempo ele quebrou os grilhões.
  2. Os sulcos profundos nas lajes mostram dezenas de investidas passadas na mesma direção, antes mesmo de o Iniciado chegar.
- **Cues de Música / Áudio:**
  - *Entrada:* arrastar ensurdecedor de ferro maciço sobre pedra + eco reverberante de fosso fundo.
  - *Combate:* ritmo industrial orgânico de bigornas surdas e sopros graves (`112 BPM` → `134 BPM` em *Frenesi*).
  - *Impacto em Monolito:* estrondo sísmico grave + tilintar longo de tensão estrutural rachando.

---

### Bloco 4.1 — Estrutura de Dados do Mapa (`fendas_cinzentas`)

| Campo | Valor Canônico |
|---|---|
| `region_id` / `arena_id` | `fendas_cinzentas` / `arena_fendas_cinzentas` |
| `largura` × `altura` | `3500.0 × 1840.0 px` |
| `camera_zoom` | `0.90` (visível `16:9`: `2133×1200 px`; `43:18`: `2867×1200 px`) |
| `spawn_jogador` | `(1750.0, 1600.0)` — portão sul do pátio |
| `spawn_chefe` | `(1750.0, 460.0)` — pórtico norte das correntes partidas |
| `chefe_id` | `tirano_quebra_grilhoes` (`Rank S`, Nível `74`, `6400 HP`, `raio_px = 128.0`) |
| `espolio` | `nucleo_do_tirano` (`Núcleo do Tirano`) + `garra_fendedora` (`Garra Fendedora`) |

```gdscript
const MAPA_FENDAS_CINZENTAS: Dictionary = {
	"region_def": {
		"id": &"fendas_cinzentas",
		"chave_nome": &"REG_FENDAS_CINZENTAS_NOME",
		"camaras": [&"combate", &"emboscada", &"santuario_cura", &"combate_denso", &"altar_pacto", &"elite_guarda", &"chefe"],
		"pool_inimigos": [&"baluarte_de_cinza", &"coro_fraturado", &"fenda_errante"],
		"chefe": &"tirano_quebra_grilhoes",
		"fragmentos_chefe": 42,
	},
	"arena": {
		"id": "arena_fendas_cinzentas",
		"formato": "patio_prisao_retangular",
		"largura": 3500.0,
		"altura": 1840.0,
		"margem": 180.0,
		"camera_zoom": 0.90,
		"spawn_jogador": Vector2(1750.0, 1600.0),
		"spawn_chefe": Vector2(1750.0, 460.0),
		"portal_saida": Vector2(1750.0, 78.0),
		"paleta": {
			"bg": Color("0e0f14"),
			"floor": Color("232630"),
			"accent": Color("9ca3af"),
			"border": Color("424756"),
			"motif": "fendas_prisao",
		},
		"pilares": [], # Monólitos geridos em obstaculos_destrutiveis (2 cargas de impacto cada)
		"zonas_seguras": [
			{"id": "corredor_flanco_oeste", "tipo": "corredor_flanqueamento", "forma": "rect", "x": 400.0, "y": 920.0, "largura": 440.0, "altura": 1480.0},
			{"id": "corredor_flanco_leste", "tipo": "corredor_flanqueamento", "forma": "rect", "x": 3100.0, "y": 920.0, "largura": 440.0, "altura": 1480.0},
		],
		"zonas_perigo": [
			{"id": "correntes_centro", "tipo": "correntes_partidas", "forma": "rect", "x": 1750.0, "y": 780.0, "largura": 820.0, "altura": 140.0},
			{"id": "correntes_oeste", "tipo": "correntes_partidas", "forma": "rect", "x": 1040.0, "y": 920.0, "largura": 520.0, "altura": 140.0},
			{"id": "correntes_leste", "tipo": "correntes_partidas", "forma": "rect", "x": 2460.0, "y": 920.0, "largura": 520.0, "altura": 140.0},
		],
		"obstaculos_destrutiveis": [
			{"id": "monolito_nw", "tipo": "monolito_contencao", "x": 1160.0, "y": 640.0, "r": 68.0, "cargas_impacto": 2, "stagger_s": [2.5, 3.5]},
			{"id": "monolito_ne", "tipo": "monolito_contencao", "x": 2340.0, "y": 640.0, "r": 68.0, "cargas_impacto": 2, "stagger_s": [2.5, 3.5]},
			{"id": "monolito_sw", "tipo": "monolito_contencao", "x": 1160.0, "y": 1200.0, "r": 68.0, "cargas_impacto": 2, "stagger_s": [2.5, 3.5]},
			{"id": "monolito_se", "tipo": "monolito_contencao", "x": 2340.0, "y": 1200.0, "r": 68.0, "cargas_impacto": 2, "stagger_s": [2.5, 3.5]},
		],
		"interativos": [],
	},
	"enemy_def": {
		"id": &"tirano_quebra_grilhoes",
		"chave_nome": &"BOSS_TIRANO_GRILHOES_NOME",
		"rank": "S",
		"nivel": 74,
		"arquetipo": "bruto_cerco_juggernaut",
		"comportamento": &"chefe",
		"vida": 6400.0,
		"velocidade": 156.0,
		"raio_px": 128.0,
		"dano": 34.0,
		"alcance_px": 1350.0,
		"preparo_s": 0.80,
		"recarga_s": 1.25,
		"velocidade_projetil": 0.0,
		"custo_onda": 0,
		"padroes": [
			{
				"chave_nome": &"PAT_RASGO_DO_TIRANO",
				"forma_telegrafo": &"setor",
				"dimensoes": {&"raio_px": 330.0, &"meio_angulo_graus": 100.0},
				"preparo_s": 0.65,
				"execucao_s": 0.25,
				"recarga_s": 1.15,
				"dano": 36.0,
				"efeitos": [&"arco_frontal_mortal", &"sangramento"],
				"raio_secundario_px": 0.0,
			},
			{
				"chave_nome": &"PAT_INVESTIDA_COMPRESSAO",
				"forma_telegrafo": &"retangulo",
				"dimensoes": {&"largura_px": 310.0, &"comprimento_px": 1350.0},
				"preparo_s": 0.85,
				"execucao_s": 0.90,
				"recarga_s": 1.55,
				"dano": 44.0,
				"efeitos": [&"avanco_960pxs", &"destroi_terreno", &"para_em_monolito_stagger_2_0x"],
				"raio_secundario_px": 0.0,
			},
			{
				"chave_nome": &"PAT_PRESSAO_SOBERANA",
				"forma_telegrafo": &"circulo",
				"dimensoes": {&"raio_px": 390.0},
				"preparo_s": 0.80,
				"execucao_s": 0.30,
				"recarga_s": 1.40,
				"dano": 32.0,
				"efeitos": [&"onda_esmagamento", &"abalo_2_0s"],
				"raio_secundario_px": 540.0,
			},
			{
				"chave_nome": &"PAT_FRENESI_QUEBRA_GRILHOES",
				"forma_telegrafo": &"anel",
				"dimensoes": {&"raio_int_px": 0.0, &"raio_ext_px": 460.0},
				"preparo_s": 0.95,
				"execucao_s": 0.40,
				"recarga_s": 1.60,
				"dano": 38.0,
				"efeitos": [&"buff_frenesi_25_poder_22_velocidade", &"investida_dupla_fase2"],
				"raio_secundario_px": 460.0,
			},
		],
	},
	"espolio": [
		{"id": "nucleo_do_tirano", "nome": "Núcleo do Tirano", "raridade": "lendario", "tipo": "material_boss"},
		{"id": "garra_fendedora", "nome": "Garra Fendedora", "raridade": "epico", "tipo": "material_boss"},
	],
}
```

---

### Bloco 4.2 — Planta / Layout Tático da Arena (`fendas_cinzentas`)

```text
  0        500       1000      1500      2000      2500      3000     3500 (X)
0 +-------------------------------------------------------------------------+
  | # # # # # # # # # # # # # [ PORTAL NORTE ] # # # # # # # # # # # # # #  | Y=78
  | # +-----------------------------------------------------------------+ # |
  | # |  ROTAS DE CONTORNO NORTE (200..460)                             | # |
400 # |                    ** BOSS: Tirano (1750, 460) **               | # | Y=460
  | # |    C       [M1]                                [M2]         C   | # |
  | # |    O    (1160,640)                          (2340,640)      O   | # | Y=640
  | # |    R       r=68                                r=68         R   | # |
800 # |    R             ========[Z1: CORRENTES]========            R   | # | Y=780
  | # |    E    ===[Z2]===      (1750,780 · 820x140)   ===[Z3]===   E   | # |
  | # |    D   (1040,920)                             (2460,920)    D   | # | Y=920
  | # |    O                                                        O   | # |
1200# |    R       [M3]                                [M4]         R   | # | Y=1200
  | # |    W    (1160,1200)                         (2340,1200)     E   | # |
  | # |            r=68                                r=68             | # |
  | # |                                                                 | # |
1600# |                        P = (1750, 1600)                         | # | Y=1600
  | # +-----------------------------------------------------------------+ # |
1840+-----------------------------------------------------------------------+ (Y)

Legenda:
  [M1..M4] 4 Monolitos de Contenção (cada um para Investida de Compressão 2x)
  ===[Z1..Z3]=== 3 Zonas de Correntes Partidas no Chão (terreno difícil -22% vel.)
  CORREDOR W / E = Corredores laterais amplos (440 px) livres para flanqueamento
```

| Elemento | ID | Categoria | Coordenadas `(x, y)` | Raio / Dimensão | Papel Tático / Sightline |
|---|---|---|---|---|---|
| Spawn Jogador | `spawn_p4` | Spawn | `(1750, 1600)` | `r = 27 px` | Portão sul; visão imediata do eixo de investida e dos 4 Monolitos |
| Spawn Boss | `tirano` | Boss Juggernaut | `(1750, 460)` | `r = 128 px` (`~25 m`, `~180 t`) | Pórtico norte; domina o centro do pátio |
| Monolito NW | `monolito_nw` | Contramedida (2 cargas) | `(1160, 640)` | `r = 68 px` | Quebra *Investida de Compressão*; abre stagger `2,5 s` / `3,5 s` |
| Monolito NE | `monolito_ne` | Contramedida (2 cargas) | `(2340, 640)` | `r = 68 px` | Simétrico ao `monolito_nw` |
| Monolito SW | `monolito_sw` | Contramedida (2 cargas) | `(1160, 1200)` | `r = 68 px` | Protege quadrante sul esquerdo e bloqueia rota diagonal |
| Monolito SE | `monolito_se` | Contramedida (2 cargas) | `(2340, 1200)` | `r = 68 px` | Protege quadrante sul direito |
| Correntes Centro | `correntes_centro` | Terreno Difícil | `(1750, 780)` | `820 × 140 px` | Marca visual da pista central; reduz movimento em `-22%` |
| Correntes Oeste / Leste | `correntes_oeste` / `leste` | Terreno Difícil | `(1040, 920)` / `(2460, 920)` | `520 × 140 px` | Marcam rotas diagonais de investida entre monolitos |
| Corredores Laterais | `corredor_flanco_w/e` | Rota Segura | `x=400` / `x=3100`, `y=920` | `440 × 1480 px` | Largura folgada para escapar do arco frontal de `330 px` |

---

### Bloco 4.3 — Configuração das Mecânicas Ambientais (`fendas_cinzentas`)

1. **4 Monolitos de Contenção (Interrupção de *Investida de Compressão*):**
   - **Gatilho:** Durante a execução (`0,90 s` / `54 ticks` a `960 px/s`) de *Investida de Compressão*, se o círculo do Tirano (`r = 128 px`) colidir com qualquer Monolito ativo (`r = 68 px`, distância `< 196 px`):
     - O avanço **cessa no mesmo tick**;
     - `cargas_impacto` do Monolito reduz em `1`:
       - **1º Impacto (`cargas_impacto: 2 → 1`):** O Monolito fica visualmente rachado com faíscas metálicas; o Tirano entra em estado `Atordoado` por **`2,50 s` (`150 ticks`)**, recebendo **`2,0×` de dano nos membros** (sua armadura pesada normal reduz dano frontal em `0,75×`, tornando o stagger a chave do DPS).
       - **2º Impacto (`cargas_impacto: 1 → 0`):** O Monolito se estilhaça permanentemente (`remove` da lista de colisão `pilares`), dispara onda de choque radial sem dano no jogador (`r = 160 px`) e aplica `Atordoado` por **`3,50 s` (`210 ticks`)** com `2,0×` de dano.
   - **Destruição de Terreno pela Investida:** Se a investida atravessar o pátio sem atingir um Monolito e bater na muralha externa, deixa um sulco ardente/rachado temporário por `8,0 s` (`480 ticks`) ao longo da linha de `1350 px` (reduz velocidade em `-15%` sem dano direto, preservando legibilidade).
2. **3 Zonas de Correntes Partidas no Chão:**
   - **Regra:** Enquanto o jogador caminha sobre `correntes_centro/oeste/leste` (sem `dash_remaining > 0`), `velocidade_efetiva = velocidade × 0,78` (`-22%`). O boss **ignora** a penalidade e usa exatamente as faixas de correntes como vetores visuais naturais para alinhar *Investida de Compressão*.
   - **Contra-jogada:** Usar *dash* (`1350 px/s`) atravessa uma faixa de `140 px` em `0,10 s` sem sofrer desaceleração e posiciona o jogador nos corredores laterais de `440 px` ou atrás do próximo Monolito.
3. ***Frenesi Quebra-Grilhões* (`HP ≤ 3200` / `< 50%`):**
   - Transição invulnerável de `0,60 s` (`36 ticks`) com estilhaço metálico no peito e braços.
   - **Efeitos permanentes:** Poder `+25%` (`1,25×` em todos os golpes), Velocidade `+22%` (`156 → 190 px/s`), recargas `× 0,70` e *Investida de Compressão* ganha **rebote de 2º avanço** (`0,55 s` de novo preparo em direção ao jogador) sempre que o 1º avanço **não** acertar um Monolito!

---

### Bloco 4.4 — Lista de Assets Necessários (`fendas_cinzentas`)

- **`arena_bg` (Chunks `≤ 2048×2048`, 6 chunks cobrindo `3500×1840` + bordas de muralha):**
  - `res://assets/art/environment/fendas_cinzentas/arena_bg_nw_1x.png` .. `arena_bg_se_1x.png`.
- **Tiles / Zonas de Terreno:**
  - `env_fendas_piso_prisao_01_2x.png` (`512×512`, lajotas cinza-ardósia `#232630` com desgaste linear, `L* 22–32`).
  - `env_fendas_correntes_chao_01_2x.png` (`512×256`, elos partidos pesados afundados na pedra, traço `1,5 px` `#0D0E14`, sem brilho saturado).
- **Props de Storytelling & Destrutíveis:**
  - `prp_fendas_monolito_intacto_2x.png` (`256×384`, obelisco de basalto com argolas rompidas, contorno `3 px`);
  - `prp_fendas_monolito_rachado_2x.png` (`256×384`, fendas em magenta contido `L* ≤ 45`);
  - `prp_fendas_monolito_destruido_2x.png` (`256×256`, base partida no chão, traço `1,5 px`).
- **Objetos Interativos / Portas:**
  - `prp_fendas_portal_norte_2x.png` (`384×512`, grade colossal erguida em arco com halo dourado `#E3B23C`).
- **Sprites / Partes do Boss (`~25 m`, `~180 t`, traço `3,5 px` 1× / `7 px` 2×):**
  - `bos_tirano_corpo_sheet_2x.png` (`576×512` em `1×` / `1152×1024` em `2×`);
  - `bos_tirano_grilhao_frenesi_2x.png` (braçadeiras quebradas + garras fendedoras articuladas em rig `2D`);
  - Animações obrigatórias: `spawn`, `idle`, `run`, `windup_investida`, `attack_investida`, `stagger_monolito`, `windup_rasgo`, `attack_rasgo`, `frenesi_transicao`, `hurt`, `death`.
- **VFX Ambientais & Indicadores de Perigo:**
  - `vfx_fendas_sulco_investida_2x.png` (rastro de lascas de pedra no solo após investida sem impacto);
  - `vfx_fendas_impacto_monolito_2x.png` (flipbook `8` quadros de estilhaço pétreo e faísca branca-dourada);
  - `vfx_fendas_poeira_cerco_mask.png` (`512×256`, névoa cinza pesada nas muralhas externas).

---

## Mapa 5 — `terras_baldias_subterraneas` · Terras Baldias Subterrâneas (Abismo dos Selos)

### Ficha de Level Design e Fluxo da Câmara
- **ID da Região / Arena:** `terras_baldias_subterraneas` (`Abismo dos Selos` — Endgame)
- **Boss:** **Pesadelo das Fendas Subterrâneas** (`pesadelo_fendas_subterraneas`) · `Rank Cataclísmico` · Nível `90` (Endgame) · Entidade Abissal / Devorador Subterrâneo · Escala `~50 m`
- **Tema e Atmosfera:** Caverna tectônica colossal (`3800 × 2100`, `camera_zoom: 0,82` para leitura plena da silhueta de `50 m`), dividida entre uma vasta bacia central de **solo arenoso e fendido** (onde a entidade escava e regenera) e quatro **plataformas periféricas de rocha matriz com runas** que protegem contra emersões diretas e abrigam os dispositivos ancestrais.
- **Tempo Estimado de Combate:** `5 min 30 s – 7 min 00 s` (`~19.800 – 25.200` ticks vivos)
- **Fraquezas Obrigatórias Integradas ao Mapa:** `Luz Sagrada`, `Vibrações Harmônicas`, `Selos Antigos`.
- **Rumo Crítico (Critical Path — Obrigatório para Vencer):** Nascer na **Plataforma Sul de Rocha Matriz** `(1900, 1860)` → ao ver o Pesadelo iniciar *Escavação Abissal* (e *Regeneração Abissal* enquanto submerso), correr pelas plataformas até um dos **3 Cristais / Sinos Harmônicos** (Oeste, Leste ou Norte) e golpeá-lo/interagir (`[E]`) para disparar **Vibrações Harmônicas** que forçam a emersão desorientada da entidade → percorrer os **4 Selos Rúnicos Antigos (`[E]`)** ao redor da bacia para prender o boss na superfície e **cortar a *Regeneração Abissal*** → usar as **3 Fendas de Luz Sagrada** como abrigo contra *Olhar do Abismo* e atrair a bocarra/núcleo do boss sobre uma Fenda de Luz para aplicar **Núcleo Purificado (`2,0×` dano)** → sobreviver a *Devoração Total* na fase final e selar o Abismo.
- **Rotas Opcionais / Maestria:** Ativar os 2 Selos do lado sul primeiro (`SW` e `SE`) reduz imediatamente pela metade a *Regeneração Abissal* antes do primeiro mergulho; combinar um **Sino Harmônico** seguido de **atração sobre uma Fenda de Luz Sagrada** cria uma janela de `6,0 s` de DPS máximo capaz de derrubar uma barra inteira de fase sem enfrentar *Tentáculos do Vazio* estendidos.
- **Curva de Ritmo (Pacing Chart):**
  - `0–20 s` *(Abertura Cataclísmica)*: Intensidade `3` — câmera em `zoom 0,82` revela os `~50 m` de extensão tectônica da sombra na areia antes do primeiro rugido no centro `(1900, 960)`.
  - `20–120 s` *(Fase 1 — O Ritual dos Selos e Sinos)*: Intensidade `4` — o jogador alterna limpeza de *Tentáculos do Vazio*, toque nos Sinos Harmônicos e ativação dos `4` Selos Antigos enquanto se protege de *Olhar do Abismo* nas Fendas de Luz.
  - `120–240 s` *(Fase 2 — `< 60% HP`: Ruptura de Selos e Olhar Contínuo)*: Intensidade `5` — o Pesadelo rompe os Selos após `10,0 s` de contenção, obrigando reativação coordenada enquanto *Olhar do Abismo* varre mais rápido.
  - `240–360 s` *(Clímax — `< 30% HP`: Devoração Total)*: Intensidade `5+` — prepara vórtice gigantesco *Devoração Total* (`r = 820 px`); apenas atingir um Sino Harmônico **ou** concluir os `4` Selos interrompe a execução antes do wipe!
- **Beats Narrativos (Lore Freeze P5):**
  1. As **4 plataformas de rocha matriz** preservam runas gastas anteriores à Universidade — indicando uma contenção geológica antiga, sem qualquer assinatura das 6 Doutrinas do Campus.
  2. Os **3 Sinos Harmônicos** não são sinos de igreja humana, mas diapasões cristalinos naturais cravados na caverna que ressoam em tom idêntico ao *Diapasão de Cristal Azul-Gelo* (sem explicar quem os afinou).
- **Cues de Música / Áudio:**
  - *Ambiente:* zumbido sub-grave tectônico (`42 Hz`) + areia deslizando em cascata nas fendas.
  - *Regeneração Submersa:* pulsação cardíaca lenta e viscosa crescendo em volume até o Sino ser tocado.
  - *Sino Harmônico:* acorde puro de cristal ressonante (`440 Hz + 660 Hz`) que silencia todos os tentáculos por `1,5 s`.
  - *Olhar do Abismo:* chiado metálico de pressão crescente no ouvido enquanto o jogador está fora das Fendas de Luz Sagrada.

---

### Bloco 5.1 — Estrutura de Dados do Mapa (`terras_baldias_subterraneas`)

| Campo | Valor Canônico |
|---|---|
| `region_id` / `arena_id` | `terras_baldias_subterraneas` / `arena_abismo_dos_selos` |
| `largura` × `altura` | `3800.0 × 2100.0 px` |
| `camera_zoom` | `0.82` (visível `16:9`: `2341×1317 px`; `43:18`: `3146×1317 px`) |
| `spawn_jogador` | `(1900.0, 1860.0)` — Plataforma Sul de Rocha Matriz |
| `spawn_chefe` | `(1900.0, 960.0)` — Bacia Central Arenosa |
| `chefe_id` | `pesadelo_fendas_subterraneas` (`Rank Cataclísmico`, Nível `90` Endgame, `9500 HP`, núcleo `r = 145.0 px`, corpo modular `~50 m`) |
| `fraquezas` | `["Luz Sagrada", "Vibrações Harmônicas", "Selos Antigos"]` |
| `espolio` | `nucleo_do_abismo` (`Núcleo do Abismo`) |

```gdscript
const MAPA_TERRAS_BALDIAS: Dictionary = {
	"region_def": {
		"id": &"terras_baldias_subterraneas",
		"chave_nome": &"REG_TERRAS_BALDIAS_NOME",
		"camaras": [&"combate", &"emboscada", &"santuario_cura", &"combate_denso", &"altar_pacto", &"elite_guarda", &"chefe"],
		"pool_inimigos": [&"coro_fraturado", &"fenda_errante", &"baluarte_de_cinza"],
		"chefe": &"pesadelo_fendas_subterraneas",
		"fragmentos_chefe": 75,
	},
	"arena": {
		"id": "arena_abismo_dos_selos",
		"formato": "caverna_tectonica",
		"largura": 3800.0,
		"altura": 2100.0,
		"margem": 180.0,
		"camera_zoom": 0.82,
		"spawn_jogador": Vector2(1900.0, 1860.0),
		"spawn_chefe": Vector2(1900.0, 960.0),
		"portal_saida": Vector2(1900.0, 78.0),
		"paleta": {
			"bg": Color("07060b"),
			"floor": Color("1a1724"),
			"accent": Color("e0259c"),
			"border": Color("372c4a"),
			"motif": "abismo_selos",
		},
		"pilares": [],
		"plataformas_rocha_matriz": [
			{"id": "rocha_sul_entrada", "forma": "rect", "x": 1900.0, "y": 1830.0, "largura": 960.0, "altura": 340.0, "imune_escavacao": true},
			{"id": "rocha_oeste", "forma": "circulo", "x": 660.0, "y": 1050.0, "r": 280.0, "imune_escavacao": true},
			{"id": "rocha_leste", "forma": "circulo", "x": 3140.0, "y": 1050.0, "r": 280.0, "imune_escavacao": true},
			{"id": "rocha_norte", "forma": "circulo", "x": 1900.0, "y": 380.0, "r": 310.0, "imune_escavacao": true},
		],
		"zonas_seguras": [
			{"id": "luz_sagrada_oeste", "tipo": "fenda_luz_sagrada", "x": 840.0, "y": 1050.0, "r": 130.0, "imune_olhar": true, "fraqueza_boss": &"luz_sagrada"},
			{"id": "luz_sagrada_leste", "tipo": "fenda_luz_sagrada", "x": 2960.0, "y": 1050.0, "r": 130.0, "imune_olhar": true, "fraqueza_boss": &"luz_sagrada"},
			{"id": "luz_sagrada_norte", "tipo": "fenda_luz_sagrada", "x": 1900.0, "y": 540.0, "r": 130.0, "imune_olhar": true, "fraqueza_boss": &"luz_sagrada"},
		],
		"zonas_perigo": [
			{"id": "bacia_arenosa_fendida", "tipo": "solo_arenoso_escavavel", "forma": "rect", "x": 1900.0, "y": 1050.0, "largura": 3440.0, "altura": 1760.0},
		],
		"obstaculos_destrutiveis": [],
		"interativos": [
			{"id": "selo_antigo_nw", "kind": "selo_runico_antigo", "pos": Vector2(1180.0, 600.0), "r": 54.0, "ativacao": "interagir_e", "fraqueza": &"selos_antigos"},
			{"id": "selo_antigo_ne", "kind": "selo_runico_antigo", "pos": Vector2(2620.0, 600.0), "r": 54.0, "ativacao": "interagir_e", "fraqueza": &"selos_antigos"},
			{"id": "selo_antigo_sw", "kind": "selo_runico_antigo", "pos": Vector2(1180.0, 1500.0), "r": 54.0, "ativacao": "interagir_e", "fraqueza": &"selos_antigos"},
			{"id": "selo_antigo_se", "kind": "selo_runico_antigo", "pos": Vector2(2620.0, 1500.0), "r": 54.0, "ativacao": "interagir_e", "fraqueza": &"selos_antigos"},
			{"id": "sino_harmonico_w", "kind": "sino_harmonico", "pos": Vector2(540.0, 1050.0), "r": 48.0, "ativacao": "interagir_ou_golpear", "fraqueza": &"vibracoes_harmonicas"},
			{"id": "sino_harmonico_e", "kind": "sino_harmonico", "pos": Vector2(3260.0, 1050.0), "r": 48.0, "ativacao": "interagir_ou_golpear", "fraqueza": &"vibracoes_harmonicas"},
			{"id": "sino_harmonico_n", "kind": "sino_harmonico", "pos": Vector2(1900.0, 260.0), "r": 48.0, "ativacao": "interagir_ou_golpear", "fraqueza": &"vibracoes_harmonicas"},
		],
	},
	"enemy_def": {
		"id": &"pesadelo_fendas_subterraneas",
		"chave_nome": &"BOSS_PESADELO_ABISMO_NOME",
		"rank": "Cataclísmico",
		"nivel": 90,
		"arquetipo": "entidade_abissal_devoradora",
		"comportamento": &"chefe",
		"vida": 9500.0,
		"velocidade": 185.0,
		"velocidade_subterranea": 420.0,
		"raio_px": 145.0,
		"comprimento_total_px": 2500.0,
		"dano": 40.0,
		"alcance_px": 1600.0,
		"preparo_s": 0.90,
		"recarga_s": 1.35,
		"velocidade_projetil": 540.0,
		"custo_onda": 0,
		"fraquezas": [&"luz_sagrada", &"vibracoes_harmonicas", &"selos_antigos"],
		"padroes": [
			{
				"chave_nome": &"PAT_TENTACULOS_VAZIO",
				"forma_telegrafo": &"circulo",
				"dimensoes": {&"raio_px": 155.0, &"qtd_tentaculos": 5.0},
				"preparo_s": 0.75,
				"execucao_s": 0.30,
				"recarga_s": 1.30,
				"dano": 32.0,
				"efeitos": [&"emerge_na_areia", &"ignora_rocha_matriz"],
				"raio_secundario_px": 0.0,
			},
			{
				"chave_nome": &"PAT_ESCAVACAO_REGENERACAO",
				"forma_telegrafo": &"retangulo",
				"dimensoes": {&"largura_px": 320.0, &"comprimento_px": 1500.0},
				"preparo_s": 0.85,
				"execucao_s": 1.20,
				"recarga_s": 1.60,
				"dano": 38.0,
				"efeitos": [&"submerge_regenera_120_hps", &"interrompivel_por_sino_harmonico"],
				"raio_secundario_px": 0.0,
			},
			{
				"chave_nome": &"PAT_OLHAR_DO_ABISMO",
				"forma_telegrafo": &"anel",
				"dimensoes": {&"raio_int_px": 0.0, &"raio_ext_px": 1900.0},
				"preparo_s": 1.60,
				"execucao_s": 0.45,
				"recarga_s": 1.80,
				"dano": 36.0,
				"efeitos": [&"aplica_loucura_desorientacao", &"bloqueado_por_luz_sagrada"],
				"raio_secundario_px": 1900.0,
			},
			{
				"chave_nome": &"PAT_DEVORACAO_TOTAL",
				"forma_telegrafo": &"circulo",
				"dimensoes": {&"raio_px": 820.0},
				"preparo_s": 3.20,
				"execucao_s": 0.50,
				"recarga_s": 2.40,
				"dano": 75.0,
				"efeitos": [&"vortice_succao_arena", &"cancelavel_por_4_selos_ou_sino"],
				"raio_secundario_px": 1350.0,
			},
		],
	},
	"espolio": [
		{"id": "nucleo_do_abismo", "nome": "Núcleo do Abismo", "raridade": "cataclismico", "tipo": "material_boss"},
	],
}
```

---

### Bloco 5.2 — Planta / Layout Tático da Arena (`terras_baldias_subterraneas`)

```text
  0        600       1200      1800      2400      3000      3600   3800 (X)
0 +------------------------------------------------------------------------+
  | : : : : : : : : : : : : : : [ PORTAL NORTE ] : : : : : : : : : : : : : | Y=78
  | : : : : : : : : : : : . - - - - - - - - - - . : : : : : : : : : : : :  |
  |                     /   ROCHA MATRIZ NORTE    \                        |
  |                    |    ((SINO N)) (1900,260)  |                       | Y=260
400                    |  [LUZ N] (1900,540) r=130 |                       | Y=540
  |          [SELO NW]  ' - - - - - - - - - - - - '  [SELO NE]             | Y=600
  |         (1180,600)                               (2620,600)            |
  |            r=54                                     r=54               |
800  . - - - - - .         SOLO ARENOSO FENDIDO         . - - - - - .      |
  | / ROCHA OESTE \      (Escavação & Tentáculos)      / ROCHA LESTE \     |
  ||(SINO W) [LUZ W]     *** BOSS: PESADELO ***       [LUZ E] (SINO E)|    | Y=1050
  ||(540)   (840) r=130    (1900,960 · ~50m)       r=130(2960) (3260) |    |
1200\             /                                    \             /     |
  |  ' - - - - - '                                      ' - - - - - '      |
  |          [SELO SW]                               [SELO SE]             | Y=1500
  |         (1180,1500)                             (2620,1500)            |
1600           r=54    +---------------------------+    r=54               |
  |                    | ROCHA SUL (Entrada Imune) |                       | Y=1830
  |                    |        P = (1900, 1860)   |                       |
2100+----------------------------------------------------------------------+ (Y)

Legenda:
  ROCHA NORTE/OESTE/LESTE/SUL = Rocha Matriz com Runas (imune a escavação direta)
  [SELO NW/NE/SW/SE] = 4 Selos Rúnicos Antigos [E] (cortam Regeneração Abissal)
  (SINO W/E/N) = 3 Cristais / Sinos Harmônicos (golpe/[E] força emersão desorientada)
  [LUZ W/E/N] = 3 Fendas de Luz Sagrada (imunidade a Olhar + enfraquece núcleo 2,0x)
```

| Elemento | ID | Categoria | Coordenadas `(x, y)` | Raio / Dimensão | Papel Tático / Sightline |
|---|---|---|---|---|---|
| Spawn Jogador | `spawn_p5` | Spawn | `(1900, 1860)` | `r = 27 px` | Rocha Matriz Sul; leitura integral da caverna a `zoom 0,82` |
| Spawn Boss | `pesadelo` | Boss Cataclísmico | `(1900, 960)` | `r = 145 px` (`~50 m`) | Bacia central arenosa; sombra rastreadora na submersão |
| 4 Selos Antigos | `selo_antigo_nw/ne/sw/se` | Interativo `[E]` | `(1180,600)`, `(2620,600)`, `(1180,1500)`, `(2620,1500)` | `r = 54 px` | Selam o boss na superfície e anulam *Regeneração Abissal* |
| 3 Sinos Harmônicos | `sino_harmonico_w/e/n` | Interativo / Golpeável | `(540,1050)`, `(3260,1050)`, `(1900,260)` | `r = 48 px` | Emitem *Vibrações Harmônicas* para expulsar o boss da areia |
| 3 Fendas de Luz | `luz_sagrada_w/e/n` | Zona Segura + Armadilha | `(840,1050)`, `(2960,1050)`, `(1900,540)` | `r = 130 px` | Protegem do *Olhar do Abismo* e aplicam `2,0×` de dano no boss |
| 4 Rochas Matriz | `rocha_sul/oeste/leste/norte` | Terreno Imune | Sul `1830`, W `660`, E `3140`, N `380` | `r = 280–310 px` | Não sofrem erupções diretas de *Tentáculos do Vazio* ou emersão |

---

### Bloco 5.3 — Configuração das Mecânicas Ambientais (`terras_baldias_subterraneas`)

Todos os sistemas da luta operam determinísticamente em **`60 Hz` (`ticks`)** e formam um triângulo obrigatório de contra-jogadas (vencer por dano bruto ignorando os mecanismos é matematicamente inviável devido a *Regeneração Abissal* e *Devoração Total*):

1. **Solo Arenoso Fendido vs. Rocha Matriz com Runas:**
   - **Regra:** *Tentáculos do Vazio* (`5` pontos de ataque determinísticos alinhados em arco ao redor do jogador) e *Escavação Abissal* **só podem emergir** dentro de `bacia_arenosa_fendida`. Pontos candidatos que caiam dentro das `4` áreas de `plataformas_rocha_matriz` são empurrados radialmente para a borda de areia mais próxima (`folga = +45 px`).
2. **4 Selos Rúnicos Antigos (`[E]` — Fraqueza *Selos Antigos*):**
   - **Estado por Selo:** `ativo: bool`, `recarga_ticks: int` (`0` = pronto).
   - **Regra Determinística:** Enquanto o Pesadelo está submerso, *Regeneração Abissal* cura **`120 HP/s` (`2,0 HP/tick`)**:
     - `0–1` Selos ativos → `100%` da cura (`120 HP/s`);
     - `2` Selos ativos → `50%` da cura (`60 HP/s`);
     - `3` Selos ativos → `25%` da cura (`30 HP/s`);
     - **`4` Selos ativos simultaneamente:** **Corrente dos Selos Antigos!** O boss sofre interrupção imediata de *Escavação Abissal* ou *Devoração Total*, fica **preso na superfície por `10,0 s` (`600 ticks`)** com **`0 HP/s` de regeneração** e recebe **`+35%` de dano**. Ao fim dos `600 ticks` (ou quando o boss entra em `< 50% HP`), ele estoura os `4` Selos, colocando todos em recarga individual curta de `6,0 s` (`360 ticks`) antes de poderem ser reativados.
3. **3 Cristais / Sinos Harmônicos (`[E]` ou Golpe — Fraqueza *Vibrações Harmônicas*):**
   - **Gatilho:** Atingir com qualquer golpe corpo a corpo, projétil ou pressionar `[E]` no raio de `115 px` dispara uma onda sonora visível (`r_alcance = 1400 px`, `tempo_onda = 0,25 s / 15 ticks`). Cada Sino tem **`recarga_sino = 18,0 s` (`1080 ticks`)**.
   - **Efeito:** Se o Pesadelo estiver em *Escavação Abissal* (submerso) ou carregando *Devoração Total* dentro de `1400 px` do Sino, a onda força **emersão violenta desorientada (`Stagger 3,00 s / 180 ticks`, `1,65×` dano recebido)** e zera a cura em curso.
4. **3 Fendas de Luz Sagrada (Zonas Seguras — Fraqueza *Luz Sagrada*):**
   - **Proteção contra *Olhar do Abismo*:** Quando o boss inicia *Olhar do Abismo* (`1,60 s / 96 ticks` de aviso global com raio de `1900 px`), qualquer combatente **fora** de uma Fenda de Luz Sagrada ativa sofre `36` de dano + status **Desorientação Abissal** (`controles direcionais invertidos` por `2,50 s / 150 ticks`). Permanecer dentro do raio `130 px` de uma Fenda bloqueia `100%` do dano e da desorientação.
   - **Contra-jogada Ofensiva (`Núcleo Purificado`):** Atrair a cabeça/núcleo do boss (`r = 145 px`) para sobrepor uma Fenda de Luz Sagrada ativa consome a carga solar da Fenda por **`12,0 s` (`720 ticks`)**, mas queima o núcleo da entidade por **`6,00 s` (`360 ticks`)**: o Pesadelo recebe **`2,0×` de dano total** (acumulável com o `1,65×` do Sino ou `+35%` dos Selos até o teto seguro de `2,5×`) e causa `-25%` de dano durante o efeito.

---

### Bloco 5.4 — Lista de Assets Necessários (`terras_baldias_subterraneas`)

- **`arena_bg` (Chunks `≤ 2048×2048`, 6 chunks cobrindo `3800×2100` + bordas da caverna):**
  - `res://assets/art/environment/terras_baldias_subterraneas/arena_bg_nw_1x.png` .. `arena_bg_se_1x.png`.
- **Tiles / Zonas de Terreno:**
  - `env_abismo_areia_fendida_01_2x.png` (`512×512`, areia vulcânica cinza-violácea `#1A1724` com fendas secas `#07060B`, `L* 22–30`).
  - `env_abismo_rocha_matriz_01_2x.png` (`512×512`, rocha escura polida com sulcos rúnicos apagados, borda clara `L* 36` para separar imediatamente onde não nascem tentáculos).
- **Props de Storytelling & Objetos Interativos:**
  - `prp_abismo_selo_antigo_apagado_2x.png` (`192×192`, obelisco de pedra partido) e `_aceso_2x.png` (`192×192`, runa dourada `#E3B23C`);
  - `prp_abismo_sino_harmonico_2x.png` (`192×256`, diapasão de cristal azul-pálido neutro sobre pedestal sem texto);
  - `prp_abismo_fenda_luz_sagrada_2x.png` (`320×320`, fissura de luz branca-dourada `#CFC6B4` / `#E3B23C` emanando verticalmente);
  - `prp_abismo_portal_norte_2x.png` (`384×512`).
- **Sprites / Partes do Boss (`~50 m` modular, traço `3,5 px` 1× / `7 px` 2×):**
  - `bos_pesadelo_bocarra_sheet_2x.png` (`640×512` em `1×` / `1280×1024` em `2×`, cabeça colossal multi-olhos e núcleo interno `#E0259C`);
  - `bos_pesadelo_segmento_dorsal_2x.png` (`448×384` em `1×`, reutilizado em `3–4` anéis tectônicos emergentes);
  - `bos_pesadelo_tentaculo_vazio_sheet_2x.png` (`256×384` em `1×`, para `5` instâncias simultâneas);
  - `bos_pesadelo_sombra_tectonica_1x.png` (`1536×512`, sombra sinuosa de `~50 m` exibida em `z = -8` sob a areia durante *Escavação Abissal*).
- **VFX Ambientais & Indicadores de Perigo:**
  - `vfx_abismo_onda_harmonica_2x.png` (anel concêntrico em osso tracejado `#CFC6B4` diferenciando-se do telégrafo SDF magenta);
  - `vfx_abismo_corrente_selos_2x.png` (feixes dourados `#E3B23C` conectando os 4 Selos ao núcleo do boss quando travado na superfície);
  - `vfx_abismo_olhar_vinheta_mask.png` (pulso ocular em bordas durante *Olhar do Abismo* respeitando teto de `3 flashes/s` do Art Bible §7.7);
  - `vfx_abismo_devoracao_vortice_2x.png` (flipbook `12` quadros de espiral de tinta `#0D0E14` e `#E0259C`).

---

## Tabela Comparativa de Progressão (`Rank C+` → `Cataclísmico`)

| Ordem | Região (`id`) | Boss | Rank / Nível | Escala | HP Base | Dimensões Arena (`px`) | `camera_zoom` | Tempo Est. | Risco / Perigo Ambiental | Contramedida / Fraqueza de Terreno | Espólio |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **1** | `colina_raizes_profundas` | *Devorador da Coroa de Espinhos* | `C+` / `21` | `~8 m` (Estático) | `1.850` | `2800 × 1760` | `1.08` | `2m45–3m30` | Solo de Raízes (*Sensor*) + `4` Bolsões de Esporos | `5` Lajes Antigas + Dissipar esporos (Fogo/Vento/Selo) | `Núcleo de Espinho` + `Casca Espinhosa` |
| **2** | `costa_abissal` | *Leviatã da Maré Morta* | `A+` / `48` | `~32 m` (Modular) | `3.600` | `3400 × 1920` | `0.92` | `3m45–4m45` | Água Profunda + Maré Alta (*Instinto da Tempestade*) | `3` Quebra-Mares/Faróis + Fissuras Azuis (`2,0×`) + Recifes | `Núcleo Abissal` + `Escama de Ruína` |
| **3** | `escarpas_copa_quebrada` | *Vigia da Coroa Partida* | `A+` / `53` | `~20 m` / `~120 t` | `4.200` | `3200 × 1880` | `0.94` | `4m00–5m00` | *Visão Hexagonal* (`360°`) + Beiradas de Penhasco | `3` Platôs Elevados (tiro na cabeça `2,2×`) + `4` Coberturas Destrutíveis | `Núcleo da Coroa` + `Placa de Coroa Regenerada` |
| **4** | `fendas_cinzentas` | *Tirano Quebra-Grilhões* | `S` / `74` | `~25 m` / `~180 t` | `6.400` | `3500 × 1840` | `0.90` | `4m15–5m15` | `3` Zonas de Correntes Partidas (`-22%` vel.) + *Frenesi* | `4` Monolitos de Contenção (`stagger 2,0×`) + Corredores de `440 px` | `Núcleo do Tirano` + `Garra Fendedora` |
| **5** | `terras_baldias_subterraneas` | *Pesadelo das Fendas Subterrâneas* | `Cataclísmico` / `90` | `~50 m` (Modular) | `9.500` | `3800 × 2100` | `0.82` | `5m30–7m00` | Arena Arenosa Escavável + *Regeneração Abissal* + *Olhar* | `4` Selos (`Selos Antigos`), `3` Sinos (`Vibrações`), `3` Fendas (`Luz Sagrada`) | `Núcleo do Abismo` |

---

## Mapa de Integração Técnica no Projeto

Esta seção detalha exatamente o que deve ser estendido ou conectado nos arquivos existentes do repositório **sem quebrar** o comportamento atual das 4 regiões do MVP (`limiar`, `veio_instavel`, `fosso_das_cinzas`, `santuario_partido`).

### 1. Novo Módulo `CatalogoMapasBosses` (`src/gameplay/run/catalogo_mapas_bosses.gd`)
- **Papel:** Seguir o mesmo padrão puro e imutável de [catalogo_campanha.gd](file:///c:/Users/lucas/meu-jogo-estudio/src/gameplay/run/catalogo_campanha.gd) (`extends RefCounted`), expondo:
  - `static func mapas() -> Dictionary` (indexado por `region_id`: `"colina_raizes_profundas"`, `"costa_abissal"`, `"escarpas_copa_quebrada"`, `"fendas_cinzentas"`, `"terras_baldias_subterraneas"`);
  - `static func obter_mapa(reg_id: String) -> Dictionary` (retorna `.duplicate(true)` para impedir mutação acidental em runtime);
  - `static func listar_ids_progressao() -> Array[String]`.
- **Integração com `ContentCatalog` / `.tres`:** Cada entrada do `CatalogoMapasBosses` referencia diretamente o `id` do `RegionDef` (`region_def.gd`) e do `EnemyDef` + `BossPatternDef` (`enemy_def.gd`, `boss_pattern_def.gd`). Além disso, [session_catalog.gd](file:///c:/Users/lucas/meu-jogo-estudio/src/foundation/session_catalog.gd) (`lines 39-40, 50-51, 60-61`) atualmente limita `arena.largura` a `[1920, 2880]` e `arena.altura` a `[1080, 1620]`; para suportar estas arenas no validador da fatia, esses limites devem ser expandidos para `largura ∈ [1920, 3800]` e `altura ∈ [1080, 2100]`.

### 2. `GameSession` (`src/gameplay/game_session.gd`)
Pontos exatos de extensão no loop determinístico `step()` (`60 Hz`):
- **Carregamento da Câmara de Chefe (`_carregar_sala_do_mapa` e `_spawn_wave`, `lines 1182–1347`):**
  - Se `CatalogoMapasBosses.obter_mapa(reg_id)` não for vazio e `sala_tipo == "chefe"`, preencher `data["arena"]` com `largura`, `altura`, `camera_zoom`, `pilares`, `zonas_seguras`, `zonas_perigo`, `obstaculos_destrutiveis` e `interativos`, usando **coordenadas diretas** em vez de escalar por `largura_a / 2400.0` (`lines 1323–1324`).
  - Posicionar o jogador via `Movement.teleport(player, mapa_boss.arena.spawn_jogador)` e o chefe em `mapa_boss.arena.spawn_chefe` sem aplicar `Movement.resolve` sobre o chefe caso `velocidade == 0.0` (`colina_raizes_profundas`).
- **Estado Ambiental Determinístico no `step()` (`lines 304–418`):**
  - Manter `env_state: Dictionary` na sessão (zerado em `start()` e no carregamento de sala), rastreando `live_steps` para:
    1. `acum_vibracao` (Arena 1) + ciclo de ativação dos 4 bolsões de esporos + dissipação por `selo` / `fogo` / `vento`;
    2. `mare_tick = live_steps % ciclo_mare_ticks` (Arena 2), alterando `inundada = true/false` nos 3 bancos de areia e o bônus de *Instinto da Tempestade*;
    3. `ultimo_chao_firme: Vector2` (Arena 3) + detecção de saída sobre `beirada_penhasco` para teleporte com dano de queda;
    4. Colisão de `obstaculos_destrutiveis` (Arenas 3 e 4): quando ataque primário do boss (Arena 3) ou *Investida de Compressão* (Arena 4) interceptar um obstáculo com `cargas_impacto > 0`, decrementar carga, aplicar estado `stagger` no boss e remover o círculo de `data.arena.pilares` quando chegar a `0`;
    5. Interativos reutilizáveis/em recarga (Arena 5): estender `interagir_na_sala()` (`lines 1122–1173`) e `_atualizar_proximidade_sala()` (`lines 1252–1274`) para suportar `cooldown_ticks > 0` em vez de `usado = true` permanente (para os `4` Selos Antigos e `3` Sinos Harmônicos, que também respondem a acerto de golpe do jogador em `_attack` / `_projectile_step`).
- **Boss Multi-Estado / Submerso (`_enemy_step` e `_hittable`):**
  - Adicionar flags no dicionário do inimigo: `submerso: bool` (inalvejável por ataques normais enquanto em *Escavação Abissal*, mas alvo da onda dos *Sinos Harmônicos*), `janela_critica_mult: float` (`1.75` / `2.0` / `2.2` em janelas de ponto fraco) e `stagger_ticks: int`.

### 3. `GameCamera` (`src/presentation/game_camera.gd`) e Orquestração em `main.gd` (`src/app/main.gd`)
- **Substituir `base_zoom = 1.12` Fixo em `main.gd` (`lines 159, 214, 295, 312, 330, 373`):**
  - Em `main.gd`, ler `var target_base_zoom: float = float(arena_dict.get("camera_zoom", 1.12))` ao configurar ou trocar de sala (ex.: `1.08` na Colina, `0.92` na Costa, `0.94` nas Escarpas, `0.90` nas Fendas, `0.82` nas Terras Baldias).
  - Na introdução de chefe (`lines 317–328`), interpolar `camera.base_zoom` de `target_base_zoom` até `minf(1.15, target_base_zoom * 1.15)` (ou manter fixo quando `reduced_motion == true`), respeitando o teto de nitidez `1,15` do Art Bible §8.6.
- **`GameCamera._clamp()` (`lines 104–115` de `game_camera.gd`):**
  - Já divide `half_w` e `half_h` por `base_zoom` (`half_w = (width / 2.0) / base_zoom`), logo suporta nativamente zooms de `0.82` a `1.08` sem expor bordas vazias, desde que `arena.largura` e `arena.altura` cumpram os tamanhos definidos neste documento.
  - Em `main.gd` (`_verificar_intro_chefe`, `lines 987–1035`), adicionar os `5` novos `boss_id` ao `match b_kind` com título, fala de entrada e cor temática para o banner de apresentação.

### 4. `world_view.gd` (`src/presentation/world_view.gd`)
- **Carregamento de `arena_bg` Multi-Chunk Sem Distorção (`lines 62–65, 94–100`):**
  - Substituir a suposição rígida de `2400 × 1350` (`sx = room.size.x / 2400.0`) por suporte a **grade de chunks `2048×2048`** (`arena_bg_nw/ne/sw/se` etc.) ou leitura direta das dimensões reais da arena em `arena_data`, obedecendo o teto de `4096 px` da GPU/Art Bible §8.6.
- **Camadas de Terreno e Estados Visuais (`_draw()`, `lines 71–395`):**
  - **`z = -10/-8` (abaixo de sombras e telégrafos):** desenhar `zonas_seguras` (Lajes Antigas, Recifes, Píeres, Fendas de Luz Sagrada), `zonas_perigo` (Bolsões de Esporos, Maré Dinâmica sobre Bancos de Areia, Correntes Partidas, Solo Arenoso) e **sombras móveis submersas** (`bos_leviata_sombra_submersa`, `bos_pesadelo_sombra_tectonica`) mantendo contraste contido (`L* ≤ 45`) para que os telégrafos SDF (`z = -5`) jamais percam leitura.
  - **`y-sort` (`z = 0`):** integrar `obstaculos_destrutiveis` (3 variantes intacto/rachado/destroços para Monolitos e Coberturas) e os `interativos` com `cooldown_ticks` visível em anel osso tracejado (`#CFC6B4`) quando em recarga e halo dourado (`#E3B23C`) quando prontos para `[E]`.
  - **Renderização Modular de Bosses Gigantes (`_enemy`, `lines 1193–1401`):** registrar os `5` novos `actor_id` em `ACTOR_IDS` e desenhar multi-partes (pétalas do *Devorador*, cabeça + dorso com fissuras azuis + cauda do *Leviatã*, braços articulados do *Vigia*, núcleo + tentáculos periféricos do *Pesadelo*) usando `AtlasTexture` dentro dos orçamentos de draw calls (`≤ 200` entidades em `y-sort`).
