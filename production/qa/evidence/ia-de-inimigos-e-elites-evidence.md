# Evidência de QA — IA de Inimigos e Elites (`ia-de-inimigos-e-elites`)

- **Épico**: `production/epics/ia-de-inimigos-e-elites/EPIC.md` (`story-001` a `story-010`)
- **GDD Governante**: `design/gdd/ia-de-inimigos-e-elites.md` (`R1–R22`, `IV1–IV9`, `IA1–IA14`, `AC-IA-01` a `AC-IA-58`)
- **ADRs Governantes**: `ADR-0018` (IA de inimigos e chefe), `ADR-0014` (Telégrafos, geometria e teto), `ADR-0010` (Resolução do combate no passo), `ADR-0017` (Aliados e invocações)
- **Engine**: Godot 4.7.2 (`RefCounted` puro em GDScript, sem `NavigationAgent2D`, `CharacterBody2D` ou `Timer`)
- **Data de Fechamento**: 2026-11-18
- **Status Geral**: **PASS / COMPLETE (10/10 stories concluídas)**

---

## 1. Resumo de Implementação e Testes por Story (`001..010`)

| Story | Escopo Principal | Código de Produção (`src/gameplay/ia/`) | Suíte de Testes (`tests/unit/ia/`) | Status |
|---|---|---|---|---|
| **001** | Lista estável de inimigos ordenada por `id`, `criar_inimigo`, `remover_morto`, `camara_nova` e consultas `vivo`, `atingivel`, `atingiveis` e `mais_perto` (`R1, R19`) | `modulo_de_ia.gd`, `estado_de_inimigo_ia.gd`, `vista_de_inimigo.gd`, `opcoes_de_nascimento.gd` | `ia_lista_e_consultas_test.gd` | Complete |
| **002** | Máquina de fases (`SURGINDO`, `APROXIMACAO`, `PREPARO`, `EXECUCAO`, `RECUPERACAO`, `SUBJUGADO`, `MORTO`) e comportamento `corpo_a_corpo` (*Eco Perdido* / *Eco do Veio*) | `comportamento.gd`, `comportamento_melee.gd`, `modulo_de_ia.gd` | `ia_fases_e_melee_test.gd` | Complete |
| **003** | Comportamentos `distancia` (*Anomalia Menor* / *Anomalia do Veio*: banda `[255; 450] px` + cheque de vista) e `arremetida` (*Fenda Errante* / *Estilhaço Vivo*: avanço travado com contato `1×` e recuo) | `comportamento_ranged.gd`, `comportamento_charger.gd`, `consulta_de_vista.gd` | `ia_ranged_charger_test.gd` | Complete |
| **004** | Movimento com contenção contra pilares e paredes (`conter`) e separação par a par determinística no fim do item 7 (`i < j` em ordem de `id`, metade da sobreposição, normal `(0, -1)` para `i` e `(0, 1)` para `j` em centros coincidentes) | `modulo_de_ia.gd` | `ia_andar_e_separacao_test.gd` | Complete |
| **005** | Elites (`RegrasDeElite`: Vida `× 2,2`, dano `× 1,35`, raio `× 1,15`, armadura permanente por padrão e suporte opcional a quebra por hits com `"Quebrou!"` + hitstop via `pedir_recuperacao`) | `regras_de_elite.gd`, `modulo_de_ia.gd`, `eventos_de_ia.gd` | `ia_elites_e_quebra_test.gd` | Complete |
| **006** | Seleção de alvo (`alvo_efetivo`), `atrair(id, passos, passos_respiro)` sem renovação e com respiro de `0,5 s` (`30` passos), e `maldicao_saiu_de_campo` síncrono | `modulo_de_ia.gd`, `alvo_de_inimigo.gd`, `consulta_da_maldicao.gd` | `ia_alvo_e_atracao_test.gd` | Complete |
| **007** | Pedidos `imobilizar(id, passos)` (`R18`: aceito por comuns e lacaios, recusado por elites e chefes) e `puxar(id, centro, distancia_px, parar_a_px)` (`R18b` / `TR-ia-019`: aceito por comuns e elites, recusado por chefes) | `modulo_de_ia.gd`, `formulas_do_chefe.gd` | `ia_imobilizar_puxar_test.gd` | Complete |
| **008** | Foco na Maldição acuada (`R22`: inimigos comuns/elites nascidos com `ordem >= 0` par enquanto `acuada_atingivel()` miram `ACUADA`, voltando a `JOGADOR` quando o encontro termina) | `consulta_da_acuada.gd`, `modulo_de_ia.gd` | `ia_acuada_test.gd` | Complete |
| **009** | Integração do chefe ativo (`ComportamentoChefe`, `PadroesDoChefe`, `EstadoDoChefe`, `DeslocamentosDoChefe`) e lacaios invocados no item 7 | `comportamento_chefe.gd`, `padroes_do_chefe.gd`, `estado_do_chefe.gd`, `deslocamentos_do_chefe.gd` | `ia_chefe_e_validacao_test.gd` | Complete |
| **010** | Validação `IV1–IV9` / `IA1–IA14` (`ValidadorIA`) e publicação de vistas (`publicar`) | `validador_ia.gd`, `modulo_de_ia.gd` | `ia_chefe_e_validacao_test.gd` | Complete |

**Sign-off técnico (AI Programmer)**: Aprovado (`2026-11-18`).
