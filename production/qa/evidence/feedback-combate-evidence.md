# Evidência de QA — Épico `feedback-de-combate`

> **Épico**: Feedback de Combate (`feedback-de-combate`)
> **ADR**: ADR-0011 (Pipeline Visual e Feedback), ADR-0007 (Cena e Câmera), ADR-0016 (Áudio)
> **GDD**: `design/gdd/feedback-de-combate.md`
> **Data**: 2026-11-18
> **Status**: PASS (8/8 stories completas)

---

## 1. Resumo de Cobertura por Story

| Story | Título | Arquivos Implementados | Testes Unitários | Status |
|---|---|---|---|---|
| `story-001` | `FeedbackTuning` (`FB1–FB3`) e `CatalogoDeRespostas` | `src/presentation/feedback/catalogo_de_respostas.gd`, `src/presentation/feedback/pedidos_de_feedback.gd` | `tests/unit/feedback/feedback_tuning_e_catalogo_test.gd` | Complete |
| `story-002` | `ArbitroDeFeedback` Puro | `src/presentation/feedback/arbitro_de_feedback.gd` | `tests/unit/feedback/arbitro_e_preempcao_test.gd` | Complete |
| `story-003` | Preempção e `SeletorDeImpulso` de Câmera (Remetente Único) | `src/presentation/feedback/seletor_de_impulso.gd` | `tests/unit/feedback/arbitro_e_preempcao_test.gd` | Complete |
| `story-004` | `PoolDeNumeros` de Dano Flutuantes (`F1`, `F2`, `F5`, `R6`, `R16`) | `src/presentation/feedback/pool_de_numeros.gd` | `tests/unit/feedback/pool_de_numeros_de_dano_test.gd` | Complete |
| `story-005` | `DegradacaoDeVfx` por Uso Medido (`F3`, `R4`, `R8`) | `src/presentation/feedback/degradacao_de_vfx.gd` | `tests/unit/feedback/degradacao_relogios_e_maldicoes_test.gd` | Complete |
| `story-006` | Relógios (`t_vivo`/`t_apres`), Pausa, Transição e Opções | `src/presentation/feedback/respostas_vivas.gd`, `src/presentation/feedback/arbitro_de_feedback.gd` | `tests/unit/feedback/degradacao_relogios_e_maldicoes_test.gd` | Complete |
| `story-007` | Respostas Visuais das Maldições (`R15`, `R16`, 13 Eventos) | `src/presentation/feedback/catalogo_de_respostas.gd`, `src/presentation/feedback/respostas_vivas.gd` | `tests/unit/feedback/degradacao_relogios_e_maldicoes_test.gd` | Complete |
| `story-008` | Vistas e `PoolDeVfx` Pré-Alocado | `src/presentation/feedback/pool_de_vfx.gd` | `tests/unit/feedback/degradacao_relogios_e_maldicoes_test.gd` | Complete |

---

## 2. Verificação dos Critérios de Aceitação (`AC-FB-01` a `AC-FB-42`)

1. **Catálogo e Validação (`FB1–FB3`)**:
   - Cobertura integral da tabela `R3`, das lacunas `R10` e dos 13 eventos de Maldições da `R15` (`maldicao_atacou`, `maldicao_atingida`, `maldicao_exaurida`, `maldicao_regenerada`, `troca_feita`, `troca_indisponivel`, `chamado_disparado`, `chamado_pouso`, `tecnica_combinada`, `virote_marcou`, `virote_expirou`, `pacto_firmado`, `pacto_recusado`, `chefe_subjugado`, `chefe_exorcizado`).
   - Validação de histerese `FB3`: `sair_nivel_1 (0.75) < entrar_nivel_1 (0.90) <= sair_nivel_2 (0.85) + 0.10` e `sair_nivel_2 (0.85) < entrar_nivel_2 (0.95)`.
2. **Remetente Único de Câmera (`SeletorDeImpulso`)**:
   - No máximo 1 `PedidoImpulso` enviado por passo para `ImpulsosDeCamera.receber(...)`.
   - Hierarquia estrita `chefe > pesado > leve`, desempate por maior `escala` e `recusou_morte > jogador_atingido`.
   - Ataques básicos das Maldições não geram impulso; `chamado_pouso` e `tecnica_combinada` enviam preset `leve` com escala `0.6`.
3. **Pool de 6 Números de Dano Flutuantes (`PoolDeNumeros`)**:
   - Faixa `"golpe"` soma por alvo dentro de `0.30 s` (incluindo dano do jogador, da Maldição, de parede e de explosão).
   - Faixa `"dourado"` nunca soma; golpes da Maldição nunca usam `"dourado"`; `jogador_atingido` e `maldicao_atingida` nunca geram número flutuante.
   - Despejo determinístico na ordem `status -> golpe -> dourado` (mais antigo primeiro).
4. **Degradação Graciosa e Relógios (`DegradacaoDeVfx`, `RespostasVivas`)**:
   - Histerese em `0.90/0.75` (Nível 1: corta `P4`) e `0.95/0.85` (Nível 2: corta `P4` e `P3`); no teto `>= 1.0`, desaloja `P4 -> P3 -> P2` preservando sempre `P0` e `P1`.
   - Flash de acerto em `maldicao_atingida` limitado a 1 a cada 20 passos vivos (`<= 3/s`).
