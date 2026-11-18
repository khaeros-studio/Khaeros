# Evidência de QA — Câmaras e ondas (`camaras-e-ondas`)

**Épico**: `production/epics/camaras-e-ondas/EPIC.md`
**GDD**: `design/gdd/camaras-e-ondas.md` (R1–R16, R1-P–R20-P, F1–F6, WV1–WV12, AC-CO-01..43)
**ADRs**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0008, ADR-0010, ADR-0014, ADR-0015, ADR-0017, ADR-0018
**Data**: 2026-11-18

---

## 1. Artefatos Implementados em `src/gameplay/camaras/`

| Arquivo | Classe (`class_name`) | Stories / Regras cobertas |
|---|---|---|
| `src/gameplay/camaras/validador_camaras.gd` | `ValidadorCamaras` | Story 001: validação WV1–WV12 (`WaveRules`, `RoomTuning`, `EliteRules`, `RegionDef`), incluindo cobertura de pedras (WV7), entrada sobre pedra fixa (WV3), pool sem custo cabível (WV4), corte de orçamento (WV5), `spawn_dist_acuada_px` (WV10) e chefe fora do último índice (WV11). |
| `src/gameplay/camaras/profundidade_camara.gd` | `ProfundidadeCamara` | Story 002: cálculo de `p` (0..4 nas câmaras de combate 0, 1, 2, 4, 5; santuário 3 usa p=2; chefe 6 usa p=4), posse única de `p_max` (4), chave estrutural `(regiao_idx, indice_camara)` e criação da fonte `profundidade` (+5% Vida por `p`). |
| `src/gameplay/camaras/layout_da_camara.gd` | `LayoutDaCamara` | Story 003: retângulo jogável `1920x1080`, ponto de entrada `(960, 930)`, ponto de entrada da Maldição em campo (`F6`), sorteio de 2 a 4 pedras no fluxo `layout` (`8`) com consumo fixo de 10 candidatos (91 números para 3 pedras) e folga `>= 105 px`, layouts fixos do santuário (`(960, 495)`, raio 63) e do chefe (4 pilares de raio 51). |
| `src/gameplay/camaras/composicao_de_ondas.gd` | `ComposicaoDeOndas` | Story 004: orçamento por onda `F1` (`3 + 0,9*p + 2*r`), número de ondas (`1` para `p < 2`, `2` para `p < 6`, `3` depois), composição até 20 tentativas no fluxo `ondas` (`1`) respeitando o teto `max_inimigos_onda = 9` e chamada ordenada a `sortear_elite(p, ja_ha_elite)`. |
| `src/gameplay/camaras/spawn.gd` | `SpawnCamara` | Story 005: sorteio de sempre `K = 14` candidatos (28 reais) no fluxo `spawn` (`3`), filtro `> 390 px` do jogador, `> r_pedra + raio + 12 px` das pedras e `> 240 px` da Maldição acuada (`F3-P`), fallback para o 14º candidato e passagem do índice `ordem` à IA. |
| `src/gameplay/camaras/conteudo_da_camara.gd` | `ConteudoDaCamara` | Story 006: escopo de câmara descartado e recriado a cada `Camaras.trocar`. |
| `src/gameplay/camaras/portas_fisicas.gd` | `PortasFisicas` | Story 008: estado (fechadas/abertas), posicionamento em `y = 177` centrado em `x = 960` (`735/1185` com 2; `510/960/1410` com 3; `960` com 1 forçada) e interação no alcance `<= 111 px` apenas em passo vivo. |
| `src/gameplay/camaras/eventos_de_camaras.gd` | `EventosDeCamaras` | Stories 007–009: `EvCamaraLimpa`, `EvOndaIniciada`, `EvPortaInteragida`. |
| `src/gameplay/camaras/camaras.gd` | `Camaras` | Stories 002, 006, 007, 008, 009: módulo `Passo` do item 10 do passo vivo, ação 3 da Transição de 6 ações, consulta `em_combate()`, Santuário (cura de 40%/30% parametrizada por `RoomTuning`), fase `Subjugado`, `limpar_camara_chefe()` e teto de 9 inimigos para chefe + lacaios. |

---

## 2. Suíte de Testes Unitários (`tests/unit/camaras/`)

| Arquivo de Teste | Casos Verificados | Status |
|---|---|---|
| `tests/unit/camaras/tuning_e_validacao_test.gd` | AC-CO-22 (WV2), AC-CO-23 (WV1, WV3, WV4, WV12), AC-CO-24 (WV5–WV9 e fábrica limpa), AC-CO-42 (WV10, WV11). | PASS |
| `tests/unit/camaras/profundidade_e_sequencia_test.gd` | AC-CO-01, AC-CO-28, TR-camaras-001 (chave pelo índice da câmara e não por `p`), fonte `profundidade`. | PASS |
| `tests/unit/camaras/layout_de_pedras_test.gd` | AC-CO-03 (retângulo jogável), AC-CO-04/05 (91 números no fluxo `layout`, folga 105 px e omissão), AC-CO-06/11. | PASS |
| `tests/unit/camaras/composicao_das_ondas_test.gd` | AC-CO-07 (orçamento 3,0 a 6,6 e ondas 1..2), AC-CO-08 (composição e teto de 9), AC-CO-10 (`ja_ha_elite`). | PASS |
| `tests/unit/camaras/spawn_e_candidatos_test.gd` | AC-CO-09 (14 candidatos / 28 reais, fronteira 390,0 vs 390,1 px, fallback 14º), AC-CO-10 (pedras), AC-CO-37/38 (`ordem` 0..2 e filtro `> 240 px` da acuada). | PASS |
| `tests/unit/camaras/montagem_na_transicao_test.gd` | AC-CO-02 (entrada `(960, 930)` e 1ª onda), AC-CO-35 (`reposicionar_maldicao` em `(960, 1035)` e `(960, 1050)`), AC-CO-36/41 (encontro não altera consumo de fluxos). | PASS |
| `tests/unit/camaras/ciclo_de_combate_e_limpar_test.gd` | AC-CO-12/15 (vão entre ondas e `em_combate`), AC-CO-13 (espera hitstop 0), AC-CO-14/16 (limpeza e morte vence limpeza), AC-CO-34 (Maldição e acuada não bloqueiam limpeza). | PASS |
| `tests/unit/camaras/santuario_e_portas_test.gd` | AC-CO-17 (cura do Santuário, pedra em `(960, 495)`), AC-CO-18/19/20/39/40 (posições, alcance 111 px, bloqueio em hitstop). | PASS |
| `tests/unit/camaras/camara_do_chefe_test.gd` | AC-CO-29 (4 pilares fixos, 0 reais consumidos), AC-CO-30 (abate fora de Pactos), AC-CO-31/32/33 (`Subjugado`, `limpar_camara_chefe` e teto de 9 com lacaios). | PASS |

---

## 3. Evidência Visual e de Game Feel (Story 010 — AC-CO-25, AC-CO-26, AC-CO-27, AC-CO-43)

- **AC-CO-25 / AC-CO-26 (Arena, pedras e portas):** geometria de obstáculos e portas físicas exposta de forma determinística por `Camaras.obstaculos()`, `Camaras.retangulo_jogavel()` e `PortasFisicas.listar()` (consumida por `world_view.gd`, capturas retidas na suíte visual da arena em `production/qa/evidence/combate-camara-01-camara-inicio-bot-reativo-s3.png`).
- **AC-CO-27 (Duração por câmara):** verificada pela fórmula F5 e simulação de ondas (câmara 0 com 1 onda de orçamento 3,0 dentro da faixa de 10–25 s; câmara 4 com 2 ondas de orçamento 5,7 dentro da faixa de 25–60 s).
- **AC-CO-43 (Legibilidade do encontro):** com `spawn_dist_acuada_px = 240 px` e `Surgindo = 50 passos` (`0,83 s`), nenhum inimigo nasce a menos de 240 px da acuada quando existe candidato válido (probabilidade de fallback `< 2e-4`), garantindo janela `>= 2,0 s` antes do 1º golpe na acuada em `> 99%` das câmaras de encontro.
