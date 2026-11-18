# Evidência de QA — Armas das doutrinas (`armas-das-doutrinas`)

- **Épico**: `production/epics/armas-das-doutrinas/EPIC.md` (`story-001` a `story-008`)
- **GDD Governante**: `design/gdd/armas-das-doutrinas.md` (`R1–R12`, `F1–F7`, `AV1–AV12`, `V1–V12`, `AC-AR-01` a `AC-AR-29`)
- **ADRs Governantes**: `ADR-0001`, `ADR-0002`, `ADR-0003`, `ADR-0004`, `ADR-0005`, `ADR-0009`, `ADR-0010`, `ADR-0012`, `ADR-0013`, `ADR-0017`
- **Data**: 2026-11-18
- **Status Geral**: **PASS / COMPLETE (8/8 stories concluídas)**

---

## 1. Artefatos Implementados em `src/gameplay/armas/`

| Arquivo | Classe (`class_name`) | Stories / Regras cobertas |
|---|---|---|
| `src/gameplay/armas/fabrica_de_armas.gd` | `FabricaDeArmas` | Stories 001 & 003: esquema de `WeaponDef`/`AttackDef`/`ArmasTuning`, dados canônicos das 3 armas do MVP (`lamina`, `ressonancia`, `pactos`), cálculo de `recuperacao_passos()` (`F2`) e nomes/descrições canônicos (`R8`). |
| `src/gameplay/armas/formulas_de_armas.gd` | `FormulasDeArmas` | Stories 002 & 007: funções puras `F1–F7` (`dps_golpe`, `dps_combinado`, `ttk_chefe_continuo`, `paridade_ttk`, `ttk_ataque_discreto`, `folga_dano_pulso`, `vida_por_profundidade`, `golpes_ate_matar`, `golpes_ate_morrer`, `empurrao_efetivo`, `alcance_testado_px`, `fracao_especial`, `dps_composto_pactos` 60/40). |
| `src/gameplay/armas/validador_armas.gd` | `ValidadorArmas` | Story 003: validação de `V2` (1ª passada), `AV1–AV9`, `CV3/5/8/10/13/17/19` via `AV6`, `WV8` (cobertura de projétil nas ondas) e `R8/V5` (nomes canônicos e distinção `"Corte"` vs `"O Corte Fantasma"`). |
| `src/gameplay/armas/arma_da_run.gd` | `ArmaDaRun` | Story 004: máquina de estados da arma na run (`ESCOLHENDO -> EQUIPADA -> ENCERRADA`), criação do `Portador` do jogador com `vida_max=130`, `velocidade=220`, `cargas_esquiva=1`, `raio=14`, injeção no `Combate` e filtragem da pool de bênçãos pela `doutrina_id`. |
| `src/gameplay/armas/escolha_de_arma.gd` | `EscolhaDeArma` | Story 005 & 008: persistência de `[armas] ultima_arma` em `user://preferencias.cfg` via `ArmazemDeArquivos`, modo `build_playtest` (pré-seleciona `lamina` com `0` leituras/escritas em disco) e adaptador de cartas da tela de escolha (`rotulo_velocidade` `Rápido`/`Médio`/`Cadenciado`, `vida_efetiva`, `possui_maldicao`). |
| `src/gameplay/armas/besta_do_vinculo.gd` | `BestaDoVinculo` | Story 006: mecânica da *Besta do Vínculo* (`pactos`), incluindo aplicação de `Marca do Virote` no inimigo atingido pelo `Virote do Vínculo`, resolução do `ponto_chamado` (inimigo marcado mais próximo ou `120 px` na direção da mira presa à câmara) e emissão de `EvChamadoIndisponivel` durante a recarga de `3,0 s` (`180` passos). |
| `src/gameplay/armas/ev_arma_equipada.gd`, `ev_acerto_virote.gd`, `ev_chamado_indisponivel.gd` | `EvArmaEquipada`, `EvAcertoVirote`, `EvChamadoIndisponivel` | Stories 004 & 006: eventos tipados do passo (`arma_equipada`, `acerto_virote`, `chamado_indisponivel`). |

---

## 2. Paridade de DPS e Tabelas de Referência (`F1–F7`, Story 007)

| Arma (`id`) | `DPS_ataque` (`F1`) | `DPS_especial` (`F1`) | `DPS_combinado` (`F1`) | `TTK_chefe` (`900` de Vida, `F2`) | Fração Especial |
|---|---|---|---|---|---|
| `lamina` (*Lâmina de Sangue*) | `66,471 /s` | `30,000 /s` | `96,471 /s` | `9,329 s` (`9,28 s` discreto) | `31,1%` |
| `ressonancia` (*Cajado da Ressonância*) | `62,857 /s` | `34,667 /s` | `97,524 /s` | `9,228 s` (`9,15 s` discreto) | `35,5%` |
| `pactos` (*Besta do Vínculo* + Maldição) | `40,000 /s` (solo) | `18,333 /s` (solo) | `58,333 /s` (solo ~60%) / `96,333 /s` (`+ Vulto` `38,0/s`) | `9,343 s` (`+ Vulto`) | `31,4%` |

- **Paridade `paridade_ttk` (`AV3`)**:
  - Par `(lamina, ressonancia)`: `0,54% <= 12%` (PASS).
  - Trio `(lamina, ressonancia, pactos + Vulto Mudo)`: `0,62% <= 12%` (PASS).
- **Simulação Determinística de 600 Passos (`10,0 s`, `AC-AR-16` / `AC-AR-27`)**:
  - `lamina`: `964` de dano total em `10,0 s` (`96,4 /s`).
  - `ressonancia`: `976` de dano total em `10,0 s` (`97,6 /s`).
  - `pactos`: `585` de dano solo da Besta em `10,0 s` (`58,5 /s`, `60,3%` do DPS solo) + `380` de dano do *Vulto Mudo* (`38,0 /s`, `39,7%` do composto) = `965` de dano composto (`96,5 /s`), confirmando a divisão `60 / 40` em combate real.

---

## 3. Suíte de Testes Unitários (`tests/unit/armas/`) e Evidência Visual (`Story 008`)

| Arquivo de Teste | Casos Verificados | Status |
|---|---|---|
| `tests/unit/armas/weapondef_test.gd` | Story 001: esquema fechado de `WeaponDef`/`AttackDef`/`ArmasTuning`, valores exatos de fábrica das 3 armas e `recuperacao_passos()` (`11, 13, 18, 22, 16, 20, 26, 17, 22`). | PASS |
| `tests/unit/armas/formulas_de_armas_test.gd` | Story 002: `F1` a `F7`, tabelas de golpes até matar (`3, 3, 5` / `3, 2, 4` / `4, 4, 7`), golpes até morrer (`8, 7, 5, 5` para 130 de Vida e `7, 5, 4, 4` para 110 de Vida da Besta), empurrão efetivo e alcance de projétil (`411 px`). | PASS |
| `tests/unit/armas/validacao_armas_test.gd` | Story 003: `V2` (12 verificações de faixa), `AV1–AV9`, `CV3/5/8/10/13/17/19` via `AV6`, `WV8` e distinção canônica `"Corte"` vs `"O Corte Fantasma"` (`AC-AR-20`). | PASS |
| `tests/unit/armas/escolha_e_injecao_test.gd` | Stories 004, 005 & 008: `ArmaDaRun` (`ESCOLHENDO -> EQUIPADA -> ENCERRADA`), recusa de troca no meio da run (`AC-AR-01`), filtro de bênçãos por `doutrina_id` (`AC-AR-02`), persistência de `ultima_arma` (`AC-AR-17`), fallback sem aviso (`AC-AR-18`), `build_playtest` sem tocar no disco (`AC-AR-19`) e adaptador de cartas da tela de escolha (`AC-AR-29`). | PASS |
| `tests/unit/armas/besta_e_dps_test.gd` | Stories 006 & 007: `Virote do Vínculo` (`Marca do Virote`), `Chamado do Pacto` com recarga de `180` passos (`3,0 s`), resolução do `ponto_chamado` (inimigo marcado mais próximo vs `120 px` na mira presa à arena), emissão de `EvChamadoIndisponivel` e simulação de 600 passos das 3 armas (`AC-AR-16`, `AC-AR-23..28`). | PASS |
