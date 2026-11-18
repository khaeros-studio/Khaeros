# Story 004: Seed da run — nascimento, texto F9, entropia e `--seed` de debug

> **Epic**: RNG com seed
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/rng-com-seed.md`
**Requirement**: `TR-rng-002`, `TR-rng-014`, `TR-rng-012` (texto e parse; a exibição na UI é da story 007)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico (com ADR-0015 para o momento do nascimento)
**ADR Decision Summary**: A seed nasce ao confirmar a arma (em Pactos, em `dupla_confirmada`); a fonte recebe entropia, tipo de build e argumentos por injeção; release ignora `--seed` e registra; seed de debug inválida impede criar a run. Formatação e parse seguem F9, estrito.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: A leitura de `--seed` e do tipo de build entra por injeção no ponto de composição; a única chamada de entropia permitida é a função de criação da run (exceção do lint, story 006).

**Control Manifest Rules (this layer)**:
- Required: fonte de fluxos injetada; seed fixa durante a run; máscara u32 na fronteira (ADR-0005)
- Forbidden: `randomize()`/`seed()` e outras chamadas aleatórias fora do ponto de entropia (ADR-0005)
- Guardrail: sem custo por passo; a seed é lida uma vez ao criar a run

---

## Acceptance Criteria

*From GDD `design/gdd/rng-com-seed.md`, scoped to this story:*

- [ ] **AC-17** Formatação: 1067059138 → `3F9A-07C2`; 0 → `0000-0000`; 4294967295 → `FFFF-FFFF`
- [ ] **AC-18** O parse aceita e recusa exatamente as listas do F9 (recusa espaços, prefixo 0x, sinais, hífen fora do 4+4); cada recusa gera mensagem que cita o texto digitado
- [ ] **AC-19** Seed `3F9A07C2`, versão 0.1.0 e impressão falsa `1B4E` (injetada) → `3F9A-07C2 · v0.1.0 · c1B4E`
- [ ] **AC-20** (Integration) Build "debug" injetado: `--seed=3F9A07C2` → seed 1067059138; `--seed=xyz` → nenhuma run, erro mostrado, nenhuma seed sorteada; depois de N sorteios a seed lida continua a mesma
- [ ] **AC-21** (Integration) Build "release" injetado e `--seed=3F9A07C2` → a seed vem da entropia falsa e o log contém "seed ignorada em release"; mais um smoke manual no build exportado
- [ ] **AC-39** Com a Besta confirmada na Escolha de arma e a tela da dupla aberta, ler a seed devolve "sem seed" e pedir fluxo é erro; ao chegar `dupla_confirmada` a seed existe e o primeiro fluxo pedido é (`pactos`, 0, 0); Esc na tela da dupla volta à Escolha sem seed; com Lâmina a seed nasce ao confirmar a arma

---

## Implementation Notes

*Derived from ADR-0005 (Decision: Ciclo de vida; Seed, telemetria e fronteira; Emenda Pactos):*

A fonte recebe entropia, tipo de build e argumentos por injeção (R2/R9); a seed é u32, sorteada uma vez ao criar a run, e fica fixa. `--seed` só vale em debug; em release é ignorada com registro. O rótulo exibe seed, versão e prefixo curto da impressão do catálogo (a impressão completa vai à telemetria e ao relatório de erro). F9 recusa espaços, prefixo 0x, sinais e hífen fora do formato 4+4; o parse não usa `hex_to_int` solto (o lint o proíbe). Em Pactos a seed nasce em `dupla_confirmada` (ADR-0015, Vínculo V16/V16b/V42); telas anteriores não pedem fluxo. Os estados da fonte vêm da story 003.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: ciclo de estados da fonte e matriz de posse
- Story 005: estado inicial exposto à telemetria (AC-23, AC-40)
- Story 007: exibição do texto na pausa, morte, vitória e debug, com copiar

---

## Files

- `src/foundation/rng/texto_da_seed.gd` (formatação e parse F9)
- `src/foundation/rng/criador_de_seed.gd` (entropia injetada, build, `--seed`)
- `tests/unit/rng/texto_da_seed_test.gd`
- `tests/unit/rng/nascimento_da_seed_test.gd`
- `tests/integration/rng/seed_debug_e_release_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/rng/texto_da_seed_test.gd` — must exist and pass
- Integration: `tests/integration/rng/seed_debug_e_release_test.gd`

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `production/epics/rng/story-003-fonte-de-fluxos-posse-e-ciclo-de-vida.md`
- Unlocks: `production/epics/rng/story-005-contrato-de-reproducao-e-consumo-fixo.md`, `production/epics/rng/story-006-lint-de-ci-e-troca-do-rng-da-fatia.md`, `production/epics/rng/story-007-texto-da-seed-na-interface.md`

## Completion Notes

**Concluida em**: 2026-11-16 (gameplay-programmer, sem commit)

- Criados: `src/foundation/rng/texto_da_seed.gd` (`formatar`, `rotulo`, `rotulo_da_fonte`, `interpretar` estrito sem `hex_to_int`), `src/foundation/rng/criador_de_seed.gd` (entropia, build e argumentos injetados; `seed_nasce_na_dupla`), `src/foundation/rng/fonte_de_entropia.gd` (`@abstract`) e `src/foundation/rng/fonte_de_entropia_do_sistema.gd` (unico uso de `RandomNumberGenerator`; arquivos alem da lista da story, necessarios para a injecao), `tests/unit/rng/texto_da_seed_test.gd`, `tests/unit/rng/nascimento_da_seed_test.gd`, `tests/integration/rng/seed_debug_e_release_test.gd`, dublê `tests/unit/rng/entropia_falsa_rng.gd`.
- Testes: texto 5/5, nascimento 5/5, integration debug/release 5/5.
- Decisoes: o campo do menu de debug tem precedencia sobre `--seed=`; em release qualquer seed informada e ignorada com aviso "seed ignorada em release" no relator; AC-39 e provado com um roteiro minimo no teste (o fluxo real de telas e do epico de Run/ADR-0015).
- Pendencias: (1) smoke manual de AC-21 no build exportado; (2) story 006 deve listar `fonte_de_entropia_do_sistema.gd` como excecao do lint; (3) o ponto de composicao (`src/app/main.gd`, nao editado) precisa criar `FonteDeEntropiaDoSistema`, ler `OS.is_debug_build()`/`OS.get_cmdline_user_args()` e um relator real. Arquivos novos em src/ foram gravados com aviso advisory do write-guard (fora da excecao de subagente); revisar no fechamento.
