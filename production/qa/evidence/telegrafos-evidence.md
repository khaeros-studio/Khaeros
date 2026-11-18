# Evidência de QA — Telégrafos (`telegrafos`)

- **Épico**: `production/epics/telegrafos/EPIC.md` (`story-001` a `story-010`)
- **GDD Governante**: `design/gdd/telegrafos.md` (`R1–R12`, `F1–F6`, `TL1–TL12`, `V1–V12`, `AC-TL-01` a `AC-TL-36`)
- **ADRs Governantes**: `ADR-0014` (Telégrafos, geometria e teto), `ADR-0001` (Orquestrador do passo), `ADR-0002` (Canal de eventos), `ADR-0004` (Catálogo de dados), `ADR-0008` (Movimento e colisão própria), `ADR-0011` (Pipeline visual), `ADR-0018` (IA de inimigos e chefe)
- **Engine**: Godot 4.7.2 (`RefCounted` puro em GDScript, sem `Area2D`, `ShapeCast2D`, `RayCast2D` ou `Timer`)
- **Data de Fechamento**: 2026-11-18
- **Status Geral**: **PASS / COMPLETE (10/10 stories concluídas)**

---

## 1. Resumo de Implementação e Testes por Story (`001..010`)

| Story | Escopo Principal | Código de Produção (`src/gameplay/telegrafos/`) | Suíte de Testes (`tests/unit/telegrafos/`) | Status |
|---|---|---|---|---|
| **001** | `TelegraphTuning` (10 parâmetros, `R12`), pool fixo pré-alocado de `24` slots (`TelegrafoSlot`), ciclo `LIVRE -> PREENCHENDO -> JANELA_FINAL -> DISPARADO` e 1 telégrafo ativo por inimigo (`AC-TL-01`, `AC-TL-02`, `AC-TL-07`) | `telegrafo_tipos.gd`, `telegraph_tuning.gd`, `telegrafo_slot.gd`, `telegrafos.gd` | `telegrafos_pool_e_ciclo_test.gd` | Complete |
| **002** | Derivação de forma (`FormasDeTelegrafo.derivar`) para `corpo_a_corpo` (`setor`), `distancia` (`retangulo` com corte por obstáculo/parede) e `arremetida` (`retangulo` com largura `2 * (r_i + r_alvo)` pelo raio do alvo travado `JOGADOR`/`ALIADO`/`ACUADA`) (`AC-TL-03` a `AC-TL-06`, `AC-TL-31`) | `formas_de_telegrafo.gd`, `forma_de_telegrafo.gd`, `telegrafos.gd` | `telegrafos_derivar_test.gd` | Complete |
| **003** | `GeometriaDeAcerto` pura (`F1–F6`): `setor_toca`, `retangulo_toca`, `anel_toca`, `circulo_toca`, `circulos_encostam`, `arco_do_golpe`, `alcance_do_raio` e `girar_graus` (`AC-TL-08` a `AC-TL-12`) | `geometria_de_acerto.gd` | `telegrafos_testes_de_acerto_test.gd` | Complete |
| **004** | Progresso no passo (`avancar`), entrada em `JANELA_FINAL`, disparo exato no fim do prazo (`disparou_neste_passo`), limpeza em `varrer()` e troca de câmara (`camara_nova`) (`AC-TL-13` a `AC-TL-16`) | `telegrafos.gd`, `eventos_de_telegrafos.gd` | `telegrafos_disparo_test.gd` | Complete |
| **005** | `alvo_travado` (`JOGADOR`, `ALIADO`, `ACUADA`), `acerta_alvo_travado` com `r_teste = 0` para setor/retângulo inflados e `r_alvo` para círculo/anel, e cancelamento imediato se o alvo travado sai de campo (`AC-TL-17` a `AC-TL-20`, `AC-TL-32` a `AC-TL-34`) | `consulta_de_alvo_maldicao.gd`, `telegrafos.gd` | `telegrafos_alvo_travado_test.gd` | Complete |
| **006** | Quebra (`quebrar(id)` com evento `EvTelegrafoQuebrado` e `"Quebrou!"`) e cancelamentos (`DONO_MORTO`, `TRANSICAO_FASE`, `QUEDA_CHEFE`, `ALVO_SAIU`, `TROCA_CAMARA`) sem disparo (`AC-TL-21` a `AC-TL-24`) | `telegrafos.gd`, `eventos_de_telegrafos.gd` | `telegrafos_quebrar_e_cancelar_test.gd` | Complete |
| **007** | Formas de padrões do chefe (`iniciar_telegrafo_chefe` a partir de `BossPatternDef`: `setor`, `retangulo`, `anel`, `circulo` com `raio_secundario_px` para o puxão da Convergência) (`AC-TL-25`, `AC-TL-26`, `AC-TL-35`) | `formas_de_telegrafo.gd`, `telegrafos.gd` | `telegrafos_formas_do_chefe_test.gd` | Complete |
| **008** | Publicação de até `24` vistas imutáveis (`VistaDeTelegrafo`) ordenadas por `(passos_restantes ASC, inimigo_id ASC)` com `alvo_eh_aliado` e `raio_secundario_px` para os 24 slots SDF do `PipelineVisual` (`AC-TL-27`, `AC-TL-28`, `AC-TL-36`) | `vista_de_telegrafo.gd`, `telegrafos.gd` | `telegrafos_publicar_e_validacao_test.gd` | Complete |
| **009** | Validação de dados `TL1–TL12` (`ValidadorTelegrafos extends RegrasTl`): erros de 1ª passada (`TL1–TL4`), avisos de 1ª passada (`TL5, TL6, TL10`) e avisos de 2ª passada (`TL7–TL9, TL11, TL12` incluindo folga para Maldição e Acuada) (`AC-TL-29`, `AC-TL-30`) | `validador_telegrafos.gd` | `telegrafos_publicar_e_validacao_test.gd` | Complete |
| **010** | Evidência visual e orçamento de desempenho (`varrer + 24 × avancar + publicar <= 0,05 ms` por passo, `0` alocações no passo e `0` uso de RNG) | `telegrafos.gd`, `vista_de_telegrafo.gd` | `telegrafos_publicar_e_validacao_test.gd` | Complete |

---

## 2. Evidência Visual e Orçamento de Desempenho

- **Capturas Visuais Retidas**:
  - `production/qa/evidence/combate-camara-02-telegrafo-melee-bot-reativo-s3.png`: telégrafo de setor (`Eco Perdido`) em carmim com borda nítida e preenchimento progressivo.
  - `production/qa/evidence/combate-camara-03-telegrafo-faixa-bot-reativo-s3.png`: telégrafo retangular (`Anomalia Menor` / `Fenda Errante`) distinguível do golpe do jogador.
- **Orçamento de Desempenho (`ADR-0014`)**:
  - Cenário com `24` telégrafos ativos simultâneos executando `varrer()`, `24 × avancar(id)` e `publicar(vistas)` medido com `Time.get_ticks_usec()`: abaixo do teto de `0,05 ms` por passo com `0` alocações em regime.

**Sign-off técnico (AI Programmer)**: Aprovado (`2026-11-18`).
