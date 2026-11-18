# Evidência de QA — Maldições Aliadas (`maldicoes`)

- **Épico**: `production/epics/maldicoes/EPIC.md` (`story-001` a `story-010`)
- **GDD Governante**: `design/gdd/maldicoes.md` (`R1–R24`, `F1–F7`, `ML1–ML8`, `ML-V1` a `ML-V5`, `ML-A1`, `AC-ML-01` a `AC-ML-36`)
- **ADRs Governantes**: `ADR-0017` (Aliados e invocações), `ADR-0001` (Orquestrador do passo), `ADR-0002` (Canal de eventos), `ADR-0003` (Entidades e portadores), `ADR-0004` (Catálogo de dados), `ADR-0009` (Atributos e modificadores), `ADR-0010` (Resolução do combate no passo), `ADR-0018` (IA de inimigos e chefe)
- **Engine**: Godot 4.7.2 (`RefCounted` puro em GDScript, determinístico, sem `NavigationAgent2D`, `Area2D` ou `Timer`)
- **Data de Fechamento**: 2026-11-18
- **Status Geral**: **PASS / COMPLETE (10/10 stories concluídas)**

---

## 1. Resumo de Implementação e Testes por Story (`001..010`)

| Story | Escopo Principal | Código de Produção (`src/gameplay/maldicoes/`) | Suíte de Testes (`tests/unit/maldicoes/`) | Status |
|---|---|---|---|---|
| **001** | Catálogo das 4 espécies (`vulto_mudo`, `espreitador_da_fenda`, `baluarte_de_cinza`, `soberano_do_limiar`), `TecnicaDef` e validação `ML1–ML8` (`ValidadorMaldicoes` + tabela `F6` 60/40 e paridade de TTK `<= 5%`) (`AC-ML-04`, `AC-ML-23`, `AC-ML-26`, `AC-ML-27`, `AC-ML-36`) | `tecnica_def.gd`, `catalogo_maldicoes.gd`, `validador_maldicoes.gd` | `catalogo_e_validacao_ml_test.gd` | Complete |
| **002** | `ModuloDeMaldicoes`, `MaldicaoRef`, `EstadoDoPacto`, dupla de até 2 Maldições (`1` em campo + `1` na reserva), facção aliada e execução dos 8 sub-passos na ordem canônica da `R23` no item `6.1` (`AC-ML-01` a `AC-ML-03`) | `maldicao_ref.gd`, `estado_do_pacto.gd`, `modulo_de_maldicoes.gd` | `modulo_dupla_e_faccao_test.gd` | Complete |
| **003** | `IADeAliado`: geometria do fio com histerese (`F1`: estoura em `> 480 px`, retorna até `<= 105 px`), seleção de alvo por prioridade (`marca_virote` dentro do fio > inimigo mais perto do jogador com desempate pelo menor `id`) e passiva condicional `faro_do_vinculo` (`+15%` velocidade) (`AC-ML-05`, `AC-ML-06`, `AC-ML-31`) | `ia_de_aliado.gd`, `modulo_de_maldicoes.gd` | `ia_de_aliado_fio_e_alvo_test.gd` | Complete |
| **004** | `AtaqueDaMaldicao` (`Preparo -> Execução -> Recuperação`), entrega de impacto pela `R20` (`aplicar_golpe_maldicao` sem aplicar status da Lâmina nem acumular Selo, creditando abate e `cura_ao_abater` ao dono), golpe pesado do *Baluarte* e habilidade única *Pulso de Soberania* a cada 3º ataque (`AC-ML-07` a `AC-ML-09`, `AC-ML-21`) | `ataque_da_maldicao.gd`, `contexto_da_tecnica.gd` | `ataque_basico_pela_r20_test.gd` | Complete |
| **005** | `ferir_maldicao` (`F7` com redução de dano `carapaca_ancorada`), `exaurir` síncrono nos itens `7/8` (troca automática para a reserva Pronta no mesmo passo sem técnica e sem gastar recarga, aviso `maldicao_saiu_de_campo` à IA encerrando atração com respiro) e passiva `vinculo_inquebravel` (`-20%` no tempo de Exausta: `480` / `432` passos) (`AC-ML-10` a `AC-ML-13`, `AC-ML-30`) | `modulo_de_maldicoes.gd`, `eventos_maldicoes.gd` | `dano_exaustao_e_saida_de_campo_test.gd` | Complete |
| **006** | Contadores do sub-passo 2, regeneração fracionária na reserva (`F2`: `4%/s` de `vida_max` via `acum_regen`), `EspelhoDaDupla` propagando `dano_todo_pct` e `velocidade_pct`, `acrescentar_a_dupla` no meio da run e níveis de vínculo `2/3/4` (`AC-ML-14`, `AC-ML-20`, `AC-ML-33`, `AC-ML-34`) | `modulo_de_maldicoes.gd`, `espelho_da_dupla.gd` | `contadores_regeneracao_e_dupla_test.gd` | Complete |
| **007** | `TrocaDeMaldicao` e `ExecutorDeTecnica`: ação `Troca` (`recarga_troca = 240` passos), execução genérica de Saída + Entrada no mesmo passo com `sinergia_ativa` (`F5`: `+50%` sobre alvo imobilizado, marcado na saída, atraído ou com Abalo) cobrindo os `12` pares da matriz (`AC-ML-15`, `AC-ML-16`) | `troca_de_maldicao.gd`, `executor_de_tecnica.gd` | `troca_e_tecnica_combinada_test.gd` | Complete |
| **008** | `ChamadoDoPacto`: salto de `12` passos (`0,20 s`) com corte contra parede/obstáculo, impacto no pouso com `M` do Especial do jogador, imobilização do comum mais próximo por `90` passos, atração em `210 px` por `90` passos e efeitos próprios (*Eco de Muralha* e *Convergência*) (`AC-ML-17`, `AC-ML-18`, `AC-ML-24`, `AC-ML-25`, `AC-ML-32`) | `chamado_do_pacto.gd`, `executor_de_tecnica.gd` | `chamado_do_pacto_e_atracao_test.gd` | Complete |
| **009** | `reposicionar_maldicao` na troca de câmara (`calcular_ponto_reposicionamento_camara`), leitura imutável `estado_pacto()` para o Bloco do Pacto no HUD e eventos tipados (`EvMaldicaoTrocada`, `EvTecnicaCombinada`, `EvChamadoSalto`, `EvChamadoPouso`, `EvMarcaViroteMudou`, etc.) (`AC-ML-19`, `AC-ML-28`, `AC-ML-29`, `AC-ML-35`) | `modulo_de_maldicoes.gd`, `estado_pacto_leitura.gd`, `eventos_maldicoes.gd` | `camara_leitura_eventos_e_vista_test.gd` | Complete |
| **010** | `VistaDeMaldicao`: estados visuais do fio (`OCULTO`, `CURVO_NORMAL`, `TENSIONADO_TRACEJADO`, `ESTOURADO_PULSANDO`), `usa_telegrafo_de_chao = false` (`ML-V4`), ganchos `sfx_maldicao_*` deduplicados (`ML-A1`) e orçamento do item `6.1 <= 0,25 ms/passo` | `vista_de_maldicao.gd`, `modulo_de_maldicoes.gd` | `camara_leitura_eventos_e_vista_test.gd` | Complete |

---

## 2. Evidência Visual e Orçamento de Desempenho

- **Evidência Visual de Arte e Silhueta**:
  - `production/qa/evidence/arte-maldicoes-chefe-evidence.md`: validação das silhuetas em tinta `#0D0E14` + contorno duplo `#E6DFCF` / `#CFC6B4`, fio de vínculo e distinção imediata contra inimigos (`P3`).
- **Orçamento de Desempenho (`ADR-0017`)**:
  - Execução completa do item `6.1` com dupla ativa, `6` inimigos em câmara e `EspelhoDaDupla` sincronizado: `< 0,25 ms` por passo (`0` uso de RNG).

**Sign-off técnico (AI Programmer)**: Aprovado (`2026-11-18`).
