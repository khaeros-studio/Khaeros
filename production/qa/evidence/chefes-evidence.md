# Evidência de QA — Chefes: Soberano do Limiar (`chefes`)

- **Épico**: `production/epics/chefes/EPIC.md` (`story-001` a `story-010`)
- **GDD Governante**: `design/gdd/chefes.md` (`R1–R9b`, `F1–F6`, `CH1–CH8`, `CH-V1` a `CH-V4`, `CH-A1`, `AC-CH-01` a `AC-CH-27`)
- **ADRs Governantes**: `ADR-0018` (IA de inimigos e chefe), `ADR-0014` (Telégrafos, geometria e teto), `ADR-0017` (Aliados e invocações), `ADR-0010` (Resolução do combate no passo), `ADR-0015` (Câmaras e ondas)
- **Engine**: Godot 4.7.2 (`RefCounted` puro em GDScript, `0` consumo de RNG durante toda a luta)
- **Data de Fechamento**: 2026-11-18
- **Status Geral**: **PASS / COMPLETE (10/10 stories concluídas)**

---

## 1. Resumo de Implementação e Testes por Story (`001..010`)

| Story | Escopo Principal | Código de Produção (`src/gameplay/chefes/` e `src/gameplay/ia/`) | Suíte de Testes (`tests/unit/chefes/`) | Status |
|---|---|---|---|---|
| **001** | `CatalogoChefes` (*Soberano do Limiar* `700 HP`, `4` padrões `BossPatternDef`, `ChefesTuning` de 13 campos) e `ValidacaoChefes extends RegrasCh` (`CH1–CH8`, sobrevivência mínima `CH5` e teto de lacaios `CH6`) (`AC-CH-21`, `AC-CH-22`, `AC-CH-26`) | `catalogo_chefes.gd`, `validacao_chefes.gd` | `chefes_validacao_test.gd` | Complete |
| **002** | Montagem da arena do *Soberano do Limiar* em `(960; 285)` com `4` pilares de `51 px`, máquina de fases (`SURGINDO 50 -> APROXIMACAO 30 -> PREPARO -> EXECUCAO -> RECUPERACAO`) e rotação determinística `(0 -> 1 -> 2 -> 3 -> 0)` com `0` chamadas a RNG (`AC-CH-01`, `AC-CH-10`, `AC-CH-13`) | `modulo_de_chefes.gd`, `src/gameplay/ia/comportamento_chefe.gd` | `chefes_maquina_test.gd` | Complete |
| **003** | Padrão 0 (*Garra do Véu Rasgado*: setor `165 px`, `78,46°`, `16` de dano) e Padrão 1 (*Irrupção do Limiar*: avanço de `24` passos a `675 px/s`, `18` de dano no máximo `1×` por contato) respeitando `alvo_travado` (`JOGADOR` vs `ALIADO`) (`AC-CH-04` a `AC-CH-06`, `AC-CH-11`) | `src/gameplay/ia/padroes_do_chefe.gd`, `src/gameplay/ia/comportamento_chefe.gd` | `chefes_padroes_0_1_test.gd` | Complete |
| **004** | Padrão 2 (*Pulso de Soberania*: anel `r_int = 75 px`, `r_ext = 210 px`, `15` de dano + empurrão `900 px/s` no alvo travado + `12` projéteis radiais a cada `30°` com o mesmo `alvo_travado`) (`AC-CH-07`, `AC-CH-27`) | `src/gameplay/ia/padroes_do_chefe.gd`, `src/gameplay/ia/modulo_de_ia.gd` | `chefes_padrao_2_test.gd` | Complete |
| **005** | Padrão 3 (*Convergência da Fenda*: puxão de `75 px` em `<= 420 px` sobre jogador e Maldição em campo, golpe circular `225 px` de `14` de dano e invocação lateral de até `2` *Ecos Perdidos* respeitando `max_lacaios_vivos` e `max_inimigos_onda`) (`AC-CH-08`, `AC-CH-09`, `TR-chefes-017`) | `src/gameplay/ia/padroes_do_chefe.gd`, `src/gameplay/ia/formulas_do_chefe.gd`, `src/gameplay/ia/modulo_de_ia.gd` | `chefes_padrao_3_test.gd` | Complete |
| **006** | Transição de Fúria em `<= 350 HP` (`50%`): cancela telégrafo ativo, zera atração e abre respiro de `30` passos, entra em `TRANSICAO_FASE` invulnerável por `30` passos (`0,50 s`), aplica pulso repulsor de `120 px` em `< 240 px` e ativa Fase 2 (`velocidade × 1,15`, `recarga × 0,60`) (`AC-CH-03`, `AC-CH-12`, `AC-CH-14`) | `src/gameplay/ia/modulo_de_ia.gd`, `src/gameplay/ia/comportamento_chefe.gd`, `src/gameplay/ia/formulas_do_chefe.gd` | `chefes_transicao_e_defesas_test.gd` | Complete |
| **007** | Defesas do chefe: imune a empurrão (`fator_empurrao = 0`), cambaleio, `"Quebrou!"` (`pedir_recuperacao`), imobilização (`imobilizar`) e puxão (`puxar`), aceitando Abalo e atração com respiro (`AC-CH-02`) | `src/gameplay/ia/modulo_de_ia.gd`, `src/gameplay/ia/regras_de_elite.gd` | `chefes_transicao_e_defesas_test.gd` | Complete |
| **008** | Queda do chefe (`chefe_vencido`): hitstop de `36` passos (`0,60 s`), descarte imediato de projéteis inimigos, telégrafos e lacaios invocados (sem somar abates nem `cura_ao_abater` pelos lacaios), precedência da morte do jogador no mesmo passo e bifurcação em `s + 37` (`EvChefeSubjugado` em Pactos vs `+6` Fragmentos + `limpar_camara_chefe()` fora de Pactos) (`AC-CH-15`, `AC-CH-16`, `AC-CH-19`, `AC-CH-20`, `AC-CH-23`) | `modulo_de_chefes.gd`, `contratos_de_chefes.gd`, `eventos_de_chefes.gd`, `chefes_nulo.gd` | `chefes_queda_e_subjugado_test.gd` | Complete |
| **009** | Estado `SUBJUGADO` e decisão `escolha(id, &"pactuar" | &"exorcizar")` na ordem estrita da `R9b`: `Combate.resolver_subjugado(id, escolha)` -> se `exorcizar`, remove o chefe, emite `EvChefeExorcizado` e credita `+6` Fragmentos -> `Camaras.limpar_camara_chefe()` por último, ignorando 2ª escolha repetida (`AC-CH-17`, `AC-CH-18`, `AC-CH-24`, `AC-CH-25`) | `modulo_de_chefes.gd`, `eventos_de_chefes.gd` | `chefes_queda_e_subjugado_test.gd` | Complete |
| **010** | `VistaBarraDeChefe` (`960×14 px` em `y = 48`, entalhe em `50% / 350 HP` rachado na Fúria, moldura em Osso claro sólido nos `30` passos invulneráveis de `TransicaoFase`, fade-out `0,25 s` em `Subjugado`/`Morto`, `mostrar_fio_sob_pes = false`) e `8` ganchos sonoros `chefe_*` (`CH-V1` a `CH-V4`, `CH-A1`) | `vista_barra_de_chefe.gd`, `modulo_de_chefes.gd` | `chefes_transicao_e_defesas_test.gd`, `chefes_queda_e_subjugado_test.gd` | Complete |

---

## 2. Evidência Visual e Determinismo

- **Evidência Visual de Arte e Silhueta**:
  - `production/qa/evidence/arte-maldicoes-chefe-evidence.md`: validação visual do *Soberano do Limiar*, coroa de chifres partidos, manto em fita e leitura dos 4 padrões de ataque.
- **Determinismo (`ADR-0018 §8`)**:
  - Verificado em `tests/unit/chefes/chefes_maquina_test.gd`: `0` chamadas a `FluxoRng` durante toda a luta do chefe (`chamadas_inteiro == 0` e `chamadas_real == 0`).

**Sign-off técnico (AI Programmer)**: Aprovado (`2026-11-18`).
