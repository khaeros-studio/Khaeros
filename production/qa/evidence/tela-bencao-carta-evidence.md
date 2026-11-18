# Evidência de QA — Épico `tela-de-bencao-e-carta`

> **Épico**: Tela de Bênção, Escolha de Arma/Pacto e Consentimento do Pacto (`tela-de-bencao-e-carta`)
> **ADR**: ADR-0012 (UI e HUD — Modelos de Foco Único, Cartas e Telas de Pacto)
> **GDD / UX**: `design/gdd/tela-de-bencao-e-carta.md`, `design/ux/tela-de-bencao.md`, `design/ux/tela-escolha-de-arma-e-pacto.md`, `design/ux/tela-consentimento-do-pacto.md`
> **Data**: 2026-11-18
> **Status**: PASS (9/9 stories completas)

---

## 1. Resumo de Cobertura por Story

| Story | Título | Arquivos Implementados | Testes Unitários | Status |
|---|---|---|---|---|
| `story-001` | `ModeloDeFoco`, `DadosDaCarta` (6 Zonas) e Fileira F1/F2 | `src/presentation/bencao/comandos_de_tela.gd`, `src/presentation/bencao/modelo_de_foco.gd`, `src/presentation/bencao/dados_da_carta.gd` | `tests/unit/tela_bencao/modelo_de_foco_e_fileira_test.gd` | Complete |
| `story-002` | `GrupoDeCartas` — 8 Estados e Travas de `500 ms` e `300 ms` | `src/presentation/bencao/grupo_de_cartas.gd` | `tests/unit/tela_bencao/grupo_de_cartas_travas_troca_e_sinais_test.gd` | Complete |
| `story-003` | Troca de Ofertas (`R`), Confirmação e Sinais (`preco_revelado`, `tela_fechada`) | `src/presentation/bencao/grupo_de_cartas.gd` | `tests/unit/tela_bencao/grupo_de_cartas_travas_troca_e_sinais_test.gd` | Complete |
| `story-004` | `TelaBencaoTuning` e Validação `TB1–TB10` | `src/content/tela_bencao_tuning.gd`, `src/content/validacao/regras_tb.gd` | `tests/unit/tela_bencao/tuning_carta_view_e_bencaos_real_test.gd` | Complete |
| `story-005` | `CartaView` (`320×500`, `offset_transform_visual_only`) e `TelaDeBencaoView` | `src/presentation/bencao/carta_view.gd`, `src/presentation/bencao/tela_de_bencao_view.gd` | `tests/unit/tela_bencao/tuning_carta_view_e_bencaos_real_test.gd` | Complete |
| `story-006` | Integração com o Módulo Real de `Bencaos` (`PortaDaBencaoReal`) | `src/presentation/bencao/portas_da_bencao.gd` | `tests/unit/tela_bencao/tuning_carta_view_e_bencaos_real_test.gd` | Complete |
| `story-007` | Modo `arma` — Escolha de Arma (`lamina`, `ressonancia`, `besta_do_vinculo`) | `src/presentation/bencao/tela_de_bencao_view.gd` | `tests/unit/tela_bencao/modos_arma_maldicao_e_consentimento_test.gd` | Complete |
| `story-008` | Modo `maldicao` — Escolha da Dupla de Maldições (`Campo` + `Reserva`) | `src/presentation/bencao/tela_de_bencao_view.gd` | `tests/unit/tela_bencao/modos_arma_maldicao_e_consentimento_test.gd` | Complete |
| `story-009` | `TelaDeConsentimentoDoPacto` (`Pactuar` vs `Recusar` / `Exorcizar` +6 Fragmentos) | `src/presentation/bencao/tela_consentimento_do_pacto.gd` | `tests/unit/tela_bencao/modos_arma_maldicao_e_consentimento_test.gd` | Complete |

---

## 2. Verificação dos Critérios de Aceitação (`AC-TB-01` a `AC-TB-35`)

1. **Modelo de Foco Único e Geometria F1/F2**:
   - Sem wrap-around nos extremos da fileira; atalhos `1/2/3` apenas movem o foco sem confirmar; clique fora do foco move o foco e clique sobre o foco confirma.
   - `CartaView` utiliza `offset_transform_enabled = true` e `offset_transform_visual_only = true` (`1.06×` e `-12 px`) sem deslocar as cartas vizinhas.
2. **Travas de Segurança F3 (`500 ms` e `300 ms`) e Ordem no Passo**:
   - `500 ms` após o pouso da abertura e `300 ms` após trocar ofertas ou retornar de pausa, durante os quais o foco é livre mas `aceitar` e `trocar` são bloqueados.
   - No mesmo passo, `trocar` (`R`) é avaliado antes de `aceitar`.
3. **Modos `arma`, `maldicao` e `TelaDeConsentimentoDoPacto`**:
   - Modo `arma` foca `ultima_arma` (ou `lamina` por padrão) e exibe aviso quando `besta_do_vinculo` é selecionada sem pactos no perfil.
   - Modo `maldicao` pula a tela quando há `0` espécies pactuadas, usa retratos de `assets/art/ui/maldicoes/*_retrato.png` e suporta desfazer em cascata com `Esc`/`voltar`.
   - `TelaDeConsentimentoDoPacto` apresenta `Pactuar` vs `Recusar` em encontro e `Pactuar` vs `Exorcizar` (`+6` Fragmentos) no chefe Subjugado, ignorando `B`/`voltar` para decisão.
