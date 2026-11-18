# Story 005: Contrato de reprodução, consumo fixo e estado inicial ampliado

> **Epic**: RNG com seed
> **Status**: Done
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/rng-com-seed.md`
**Requirement**: `TR-rng-005`, `TR-rng-008`, `TR-rng-013` (consumo fixo de 4 reais), `TR-rng-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico (com ADR-0013 para o perfil de vínculo e ADR-0015 para o encontro de pacto)
**ADR Decision Summary**: Nas finalidades 1–6 e 8 os consumidores mantêm a quantidade e a ordem de sorteios por decisão, independente do combate; spawn sorteia 14 candidatos por nascimento antes de filtrar; `pactos` consome exatamente 4 reais; o estado inicial inclui dupla e perfil de vínculo em runs de Pactos.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: Sem API de engine; os testes usam donos falsos e sinks falsos de telemetria e relatório.

**Control Manifest Rules (this layer)**:
- Required: consumo de `spawn` fixo em 14 candidatos por nascimento, filtros depois do sorteio (ADR-0005)
- Forbidden: o chefe consumir RNG; lacaios consumirem `elites` ou `spawn` (ADR-0018)
- Guardrail: os seis elementos do contrato (seed, versão, impressão, estado inicial, escolhas, usos de troca) reproduzem os registros estruturais

---

## Acceptance Criteria

*From GDD `design/gdd/rng-com-seed.md`, scoped to this story:*

- [ ] **AC-23** A telemetria de início de run e o relatório de erro (sinks falsos) contêm seed, versão, impressão e estado inicial (arma, Doutrina, nível de cada melhoria); a de fim de run e o relatório contêm o caminho (escolhas de porta e bênção e usos de troca)
- [ ] **AC-27** Contrato R7: duas runs A e B com seed `3F9A07C2` e as mesmas escolhas em 5 profundidades, B consumindo `ia` diferente (0 contra 37) → o log das finalidades 1–6 e 8 por profundidade é idêntico; trocar a seed faz os logs diferirem; variante C (sem a troca na profundidade 2) mantém 1–4 e 8 idênticas
- [ ] **AC-28** Pular uma finalidade (Santuário, profundidade 3, sem ondas) não altera as ondas da profundidade 4; nova run na mesma sessão com a mesma seed reproduz a primeira
- [ ] **AC-34** (Logic) Dono falso de spawn com K = 14 candidatos, regra "primeiro candidato a mais de 260 px do jogador", 5 inimigos, a partir de (`spawn`, 0, 2): jogador em (100,100) ou (900,500) → estado do fluxo idêntico após cada inimigo (28 números por inimigo, 140 no total)
- [ ] **AC-35** (Logic) Um consumidor falso que invoca 3 reforços pelo fluxo `ia` no meio da luta não altera (`ondas`, 0, 2), (`spawn`, 0, 2) nem (`layout`, 0, 2)
- [ ] **AC-37** (Logic) Dono falso de Vínculo lendo 4 reais: com garantia (G1) ou sem encontro (`u0 ≥ chance_encontro`), o fluxo avança exatamente 4 reais e o estado depois é igual
- [ ] **AC-38** (Logic) Run de Pactos com encontro no índice 1 contra outra sem encontro, até o índice 5: as saídas de `layout`, `ondas`, `elites`, `spawn`, `portas`, `bencaos` e `raridade` por profundidade são idênticas entre si e às de uma run de Lâmina com a mesma seed e escolhas
- [ ] **AC-40** (Logic) Run de Pactos com dupla (`vulto_mudo`, `espreitador_da_fenda`): o estado inicial exposto à telemetria e ao relatório traz arma e Doutrina `pactos`, a dupla nessa ordem e o perfil (espécies pactuadas com `nivel`, `encontro_pendente`, `primeiro_encontro_visto`, `runs_pactos_sem_encontro`); em Ressonância a dupla vem vazia e o perfil não vem; o texto da seed é igual nos dois casos

---

## Implementation Notes

*Derived from ADR-0005 (Decision: Posse e autorização; Emenda Pactos; Seed, telemetria e fronteira):*

Esta story prova, com donos falsos, os contratos de consumo que os épicos de Câmaras, IA, Portas, Bênçãos e Vínculo vão obedecer; não implementa esses sistemas. `spawn` sorteia a quantidade completa de candidatos antes de aplicar qualquer seleção (a acuada filtra depois, TR-camaras-012). `pactos` é pedido só em runs da Doutrina `pactos`, ao criar a run, com consumo fixo de 4 reais mesmo quando a garantia decide o encontro. Telemetria e relatório de erro recebem a impressão completa e os seis elementos de reprodução nos momentos de R7. O perfil de vínculo vem do perfil salvo (ADR-0013); aqui entra por injeção, sem ler arquivo.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: posse e autorização dos fluxos
- Épicos camaras-e-ondas, ia-de-inimigos-e-elites, portas-e-recompensas, bencaos-tradicoes, vinculo-e-pactos: os donos reais dos sorteios
- Épico persistencia: leitura real do perfil e gravação da telemetria

---

## Files

- `src/foundation/rng/estado_inicial_da_run.gd` (dados de reprodução expostos aos sinks)
- `tests/integration/rng/contrato_de_reproducao_test.gd`
- `tests/integration/rng/consumo_fixo_test.gd`
- `tests/integration/rng/estado_inicial_pactos_test.gd`
- `tests/integration/rng/doubles/` (donos falsos de spawn, ia, vínculo)

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/rng/contrato_de_reproducao_test.gd` — must exist and pass

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `production/epics/rng/story-002-operacoes-e-erros-que-nao-consomem.md`, `production/epics/rng/story-003-fonte-de-fluxos-posse-e-ciclo-de-vida.md`, `production/epics/rng/story-004-seed-da-run-texto-e-entropia.md`
- Unlocks: None

## Completion Notes

**Concluida em**: 2026-11-16 (gameplay-programmer, sem commit)

- Criados: `src/foundation/rng/estado_inicial_da_run.gd` (estado inicial R7/R7-P, `PerfilDeVinculo`, `CaminhoDaRun`, dicionarios para inicio/fim de run e relatorio de erro), `tests/integration/rng/contrato_de_reproducao_test.gd`, `tests/integration/rng/consumo_fixo_test.gd`, `tests/integration/rng/estado_inicial_pactos_test.gd`, `tests/integration/rng/doubles/` (`dono_spawn_falso.gd`, `consumidor_ia_falso.gd`, `dono_vinculo_falso.gd`, `run_simulada.gd`).
- Testes: contrato 6/6 (AC-23, AC-27, AC-28, AC-38), consumo fixo 3/3 (AC-34, AC-35, AC-37), estado inicial 2/2 (AC-40).
- Decisoes: os donos falsos so provam o contrato; valores de fixture (K=14, 260 px, arena, pesos) ficam nos dublês. O dublê de Vinculo consome 4 u32 e usa F3/F6 como funcoes puras de u (mesmo consumo de 4 reais). Fora de Pactos, `definir_pactos` e ignorado: dupla vazia e sem `perfil_vinculo`.
- Pendencias: os donos reais (Camaras, IA, Portas, Bencaos, Vinculo) e a gravacao real de telemetria/relatorio ficam nos seus epicos. Arquivos novos em src/ foram gravados com aviso advisory do write-guard (fora da excecao de subagente); revisar no fechamento.
