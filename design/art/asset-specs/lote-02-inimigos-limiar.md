# Asset Specs — Lote 2: inimigos do Limiar (Eco Perdido, Anomalia Menor, Fenda Errante, elite)

> **Fonte:** `design/gdd/ia-de-inimigos-e-elites.md` (R3–R7, Visual/Audio) · **Art Bible:** §2.2, §3.1–3.2, §4.1–4.3, §5.5–5.9, §8.2–8.3, §8.7
> **Gerado:** 2026-11-13 · rascunho do art-director (lean; technical-artist não consultado) · lista de assets aprovada pelo usuário em 2026-11-12
> **Status:** E0 aprovada · as demais folhas estão pendentes

## 0. Decisões pendentes do usuário (do rascunho do art-director)

1. Fichas sem as peças do rig: a Anomalia sai sem os cristais e o Eco sem os fiapos. **Aplicado na E0.**
2. Idle dentro das folhas 1 (`spawn` 4 + `idle` 2 na linha 1). É a recomendação, e foi seguida até haver decisão.
3. A Fenda entra na família das Anomalias: cunha, sem vespa. O conceito marca a "vespa de cristal" como pendente de aval do CD.
4. "A Anomalia flutua" (GDD) passa a ser lida como "mantém distância", e ela é desenhada apoiada no chão (§5.5).
5. Escala do elite: ×1,15 (Art Bible §5.6) contra raio ×1,2 (GDD). Com 1,2 o traço chega a 7,2 px, acima do teto de 7. Depende do game-designer e do technical-artist.
6. Coroa em ouro `#E3B23C` com aro em tinta. É uma proposta; a §4.3 não fixa a cor.
7. Tons derivados fora da §4.1 (`#A9B8C2`, `#6B5E72`, `#8A7C8F`, `#F070C0`, `#B88A2A`): todos com L* entre 42 e 75 e G − max(R,B) ≤ 62. Precisam entrar na checagem da §8.5.

## 1. Design

- **Eco Perdido** (§3.2: humano "subtraído")
  - Vulto alto e magro (1,0–1,1 do Iniciado, ~90 px) que flutua.
  - O capuz fundo tem a ponta caída em gancho, pingando tinta.
  - O rosto é oval, liso e claro, numa cavidade preta.
  - Os braços terminam numa ponta única, sem mão.
  - Um buraco vazado atravessa o peito.
  - A barra é rasgada em dentes com forro preto, e ele não tem pernas.
  - Cores: luz `#A9B8C2`, meio-tom `#6F8494`, sombra `#0D0E14`, sem acento.
  - Move-se deslizando, arrastado e inclinado à frente.
  - Referências de forma: `assets/art/source/ref/enm_eco_perdido_ref_{leonardo,dreamina}_v01.jpg`.
- **Anomalia Menor** (§3.2: imitação "com excesso")
  - Domo baixo e largo (~55 × 90 px) de lodo firme, com contorno duro.
  - Seis patas, cada uma com uma articulação a mais.
  - Boca redonda em cano na frente, que é o ponto emissor.
  - Olhos assimétricos: 3 de um lado e 1 do outro.
  - No dorso, cinco cortes chatos onde entram os cristais (peça do rig).
  - Cores: corpo `#6B5E72`, topo `#8A7C8F`; magenta `#E0259C`/`#F070C0` só nas peças.
  - Move-se aos arrancos, em ritmo errado.
- **Fenda Errante** (§3.1: cunha de investida)
  - Cunha horizontal (~60 × 110 px).
  - Espinho de cristal magenta na proa, um pouco torto.
  - Rachadura reta no dorso, fora do centro, que se abre no preparo.
  - Seis patas finas com uma articulação a mais.
  - Fileira de 4 olhos de um lado só.
  - Sem asas, sem ferrão e sem antenas.
  - Na morte, parte-se ao longo da rachadura.
- **Elite**
  - Corpo-base ×1,15 (ver decisão 5), coroa de espinhos e placas de armadura.
  - A aura dourada é VFX, fora do lote.

## 2. Folhas (prompts em `prompts/`, brutos em `assets/art/source/raw/`)

| # | Bruto | Grade | Conteúdo |
|---|---|---|---|
| E0 / A0 / F0 | `enm_<nome>_ficha_raw_vNN` | 4×1 | 3/4 de frente, 3/4 de costas, perfil, detalhe (não exportada) |
| E1 / A1 / F1 | `enm_<nome>_spawnrun_<dir>_raw_vNN` | 6×2 | linha 1: `spawn` 01–04 + `idle` 01–02; linha 2: `run` 01–06 |
| E2 / A2 / F2 | `enm_<nome>_ataquemorte_<dir>_raw_vNN` | 5×2 | linha 1: `windup` 01–03 + `attack` 01–02; linha 2: `recover` 01–02 + `hurt` 01 + `death` 01–02 |
| X0 | `enm_elite_pecas_raw_vNN` | 3×2 | 3 coroas + 3 conjuntos de placas |

- `<nome>` = `eco_perdido`, `anomalia_menor` ou `fenda_errante`; `<dir>` = `frente34` ou `costas34`.
- Cada inimigo tem uma conversa própria no Gemini, com a ficha dele como primeira imagem. A X0 fica numa conversa própria, sem imagem.
- O Eco usa a conversa `gemini.google.com/app/155c612cfa4c23ec`.
- Quadro exportado: 320×320 2× para os comuns e 384×384 para o elite (§8.3). Nome do arquivo: `enm_eco_perdido_windup_frente34_01_2x.png`.

**Quadros por ação, por direção, a 12 qps (1 quadro = 5 passos):**

| Ação | Quadros | Observação |
|---|---|---|
| `spawn` | 4 | shader por cima |
| `idle` | 2 | loop |
| `run` | 6 | loop |
| `windup` | 3 | o 3º é segurado: Eco 1/1/3, Anomalia 2/2/3, Fenda 2/2/4 |
| `attack` | 2 | Eco 1/1; Anomalia: o 01 dura 1 quadro e o 02 é o coice; Fenda: 01 e 02 alternados durante os 26 passos |
| `recover` | 2 | Eco 5/5, Anomalia 9/9, Fenda 6/10 |
| `hurt` | 1 | segurado durante o tranco procedural |
| `death` | 2 | o resto é VFX |

São 22 quadros por direção e 132 no lote. O elite reusa esses quadros com `s × 1,15`, mais as peças. Recomendação ao technical-artist: tocar o preparo e a recuperação pelo `timer` do jogo.

## 3. Peças do rig (fora das folhas, pintadas uma vez)

- **Eco:**
  - `part_fiapos_<dir>`, com os estados `pendente` e `arrastado`. O surgir é shader ou partícula.
  - **`part_antebraco_d/e`** (decisão do usuário, 2026-11-13): o antebraço termina numa ponta única de pincel e é pintado uma vez a partir da E0. O motivo é que na E1 a ponta saiu como garra ou como toco em 5 das 12 poses.
- **Anomalia:** `part_cristal_01…05` e `part_emissor_fechado/aberto`.
- **Fenda:** nenhuma peça. Plano B: `part_proa`, se o espinho variar entre as poses.
- **Elite:** uma coroa por inimigo (espinhos retos de ouro) e placas de metal `#5C6678` com friso de ouro:
  - Eco: ombreiras e gorjal;
  - Anomalia: duas selas;
  - Fenda: placa da proa e placa dorsal.

## 4. Poses das folhas

Em todas as folhas: só o corpo, sem estilhaço, partícula, fumaça, poeira nem rastro; a "frente" segue a direção da folha. Na A1 e na A2, acrescentar: "use SOMENTE as figuras [1] a [3] da primeira imagem; o corpo sai SEM cristais, com os cinco cortes chatos e a boca vazia".

- **E1:**
  1. encolhido, com metade da altura;
  2. meio erguido;
  3. quase em pé;
  4. em pé, braços abertos;
  5. idle, cabeça inclinada para a esquerda;
  6. idle, cabeça inclinada para a direita, barra balançando;
  7. a 12: desliza arrastado, tronco 15° à frente, braços alternados e a barra balançando.
- **E2:**
  1. puxa o braço direito para trás;
  2. braço mais alto e o outro à frente;
  3. preparo máximo, segurado;
  4. varrida horizontal;
  5. continuação;
  6. recuperação curvada;
  7. recuperação se endireitando;
  8. dano, jogado para trás;
  9. morte: dobra-se;
  10. morte: monte baixo de manto, com o capuz no topo.
- **A1:**
  1. achatada, patas recolhidas;
  2. um lado das patas abre;
  3. o outro lado abre;
  4. em pé;
  5. idle, parada;
  6. idle, espasmo;
  7. a 12: arrancos em ritmo errado, com parada brusca e tranco lateral.
- **A2:**
  1. traseira desce;
  2. boca abre, apontada à frente;
  3. preparo máximo, segurado;
  4. disparo, o corpo recua num tranco;
  5. coice;
  6. recuperação esparramada;
  7. recuperação torta;
  8. dano, empurrada de lado;
  9. morte: tomba;
  10. morte: achatada, patas para cima.
- **F1:**
  1. deitada;
  2. traseira sobe;
  3. patas abrem;
  4. em pé;
  5. idle;
  6. idle medindo a distância;
  7. a 12: andar ligeiro com trios de patas alternados.
- **F2:**
  1. abaixa o espinho;
  2. encolhe como mola, a rachadura começa a abrir;
  3. preparo máximo com a rachadura aberta, segurado;
  4. avanço;
  5. avanço, patas na fase oposta;
  6. freada derrapando;
  7. se ajeita;
  8. dano;
  9. morte: começa a se partir;
  10. morte: partida em duas metades.
- **costas34:** o rosto e a boca nunca aparecem. A ação vai para a direita e para longe de quem olha.

## 5. Riscos no Gemini

- **Ele copia o layout 4×1 da ficha:** abrir com "não é ficha".
- **Em 5×2 entrega 9 figuras:** pedir "EXATAMENTE 5 por fileira".
- **Desenha VFX mesmo proibidos:** apagar no recorte.
- **Vira a cabeça de perfil nas costas:** marcar no rig.
- **Põe cristais nas folhas da Anomalia:** pedir o corpo limpo.
- **Transforma a Fenda em vespa ou aranha.**
- **Faz a coroa trançada como cipó:** pedir espinhos retos.
- **Escala varia por folha:** calcular `s` por folha e montar a prancha a 90 px antes de fechar.
- **Downloads:** pedir em PNG.
