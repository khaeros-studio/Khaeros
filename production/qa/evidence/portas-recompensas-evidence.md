# Evidência de QA — Portas e recompensas (`portas-e-recompensas`)

**Épico**: `production/epics/portas-e-recompensas/EPIC.md`
**GDD**: `design/gdd/portas-e-recompensas.md` (R1–R11, R1-P–R12-P, F1–F4, PV1–PV8, AC-PR-01..37)
**ADRs**: ADR-0001, ADR-0002, ADR-0004, ADR-0005, ADR-0009, ADR-0011, ADR-0012, ADR-0015
**Data**: 2026-11-18

---

## 1. Artefatos Implementados em `src/gameplay/portas/`

| Arquivo | Classe (`class_name`) | Stories / Regras cobertas |
|---|---|---|
| `src/gameplay/portas/validacao_reward_table.gd` | `ValidacaoRewardTable` | Story 001: validação PV1–PV8 sobre `RewardTable`, incluindo cálculo exato de `P(bênção na escolha) = 0,895` para PV5 e verificação cruzada com o pool de bênçãos e escolhas livres `1 + k` (PV8). |
| `src/gameplay/portas/sorteio_de_portas.gd` | `SorteioDePortas` | Story 002: sorteio ponderado sem reposição (`F2`) consumindo **sempre 4 reais** (`u0..u3`) do fluxo `portas` (`4`), garantindo tipos distintos em cada escolha livre. |
| `src/gameplay/portas/formulas_de_portas.gd` | `FormulasDePortas` | Story 004: `F1` (`fragmentos(p) = base + floor(p / passo)` → 2, 2, 2, 3, 3 para p 0..4, máximo 10 no Limiar `F1-P`), `F3/F3-P` (`E[bênçãos] = 4,58` com `k = 4`) e `F4` (`cura = round(vida_max * cura_porta)`). |
| `src/gameplay/portas/vista_de_porta.gd` | `VistaDePorta` | Story 007/008: estrutura imutável de apresentação de cada porta (ícone/tipo, quantidade da **próxima** câmara de combate, rótulo `"+2"`, `"+3"`, `"+30%"`, `"3 ofertas"`, ou vazio para `santuario`/`chefe`/`ultima`). |
| `src/gameplay/portas/eventos_de_portas.gd` | `EventosDePortas` | Stories 005/007: `EvRecompensa`, `EvPortasAbertas`, `EvPortaEscolhida`. |
| `src/gameplay/portas/portas.gd` | `Portas` | Stories 003, 004, 005, 006, 007: máquina de estados pós-limpeza (`COMBATE -> CONCEDENDO_RECOMPENSA -> AGUARDANDO_BENCAO -> AGUARDANDO_PACTO -> PORTAS_ABERTAS -> PORTA_ESCOLHIDA / FIM_DA_REGIAO`), portas forçadas (`santuario` antes do 3, `chefe` antes do 6, 0 reais consumidos), conversão de bênção em Fragmentos quando pool = 0 (R3), prioridade da morte (passo 0 da R2) e travessia da porta avançando a Run. |

---

## 2. Suíte de Testes Unitários (`tests/unit/portas/`)

| Arquivo de Teste | Casos Verificados | Status |
|---|---|---|
| `tests/unit/portas/portas_validacao_test.gd` | AC-PR-18 (PV1, PV2, PV7), AC-PR-19 (PV3–PV6 e fábrica sem avisos), AC-PR-37 (PV8 com pool de 4 vs 5 bênçãos). | PASS |
| `tests/unit/portas/portas_sorteio_test.gd` | AC-PR-07 (`u0 = 0,2999` vs `0,3`), AC-PR-09 (tipos distintos), AC-PR-11 (fronteiras `0,4999/0,5`, `0,8333/0,8334`, `0,6666/0,6667`), AC-PR-13 (peso 0), AC-PR-14 (`P(bênção) = 0,895`). | PASS |
| `tests/unit/portas/portas_forcadas_test.gd` | AC-PR-08, AC-PR-10, AC-PR-32, AC-PR-33 (chaves 0, 1, 3, 4 consomem 4 reais cada; forçadas nos índices 2 e 5 consomem 0 reais; índice 6 sem portas). | PASS |
| `tests/unit/portas/portas_conceder_test.gd` | AC-PR-01 (`primeira_recompensa = bencao`), AC-PR-03 (pool vazio converte bênção em Fragmentos), AC-PR-04/34 (2, 2, 2, 3, 3; soma 10), AC-PR-05 (cura 30% em Lâmina 100 e Ressonância 80). | PASS |
| `tests/unit/portas/portas_fluxo_limpeza_test.gd` | AC-PR-02/25 (`recompensa -> pedir_oferta -> tela_fechada -> bencao_escolhida -> portas`), AC-PR-23 (morte vence limpeza), AC-PR-06/30/31 (santuário, índice 5 comum e chefe índice 6). | PASS |
| `tests/unit/portas/portas_aguardando_pacto_test.gd` | AC-PR-26 (espera `pacto_resolvido`), AC-PR-27 (ordem com bênção e `pacto_resolvido` lembrado), AC-PR-28 (sem espera quando `Fugiu`), AC-PR-29 (duplicado ignorado). | PASS |
| `tests/unit/portas/portas_escolha_test.gd` | AC-PR-12/15 (`VistaDePorta` mostra quantidade da próxima câmara de combate), AC-PR-16/36 (porta `chefe` sem recompensa e sem quantidade), AC-PR-20 (injeção sem SceneTree), AC-PR-35 (`E[bênçãos] = 4,58`). | PASS |
