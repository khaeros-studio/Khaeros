# Story 004: Início da run — arma, dupla, seed, estado inicial, câmara 0

> **Epic**: Run e regiões (ciclo da run)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` (R2, R2-P)
**Requirement**: `TR-run-002`, `TR-run-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§3, §5); ADR-0005: RNG determinístico; ADR-0001
**ADR Decision Summary**: `→ ATIVA` em ordem: cria seed → `FabricaDaRun` monta o `EscopoDaRun` (entrega da arma: `Portador` com `vida_max`/`velocidade` base e os dois `AttackDef`) → Vínculo planeja o encontro (só Pactos) → guarda `passos_em_jogo()` inicial → `Camaras.trocar(0)` com `primeira_recompensa` → `pedir_estado(TRANSICAO)`. Em Pactos, `pedir_dupla` antes; a seed nasce em `dupla_confirmada`. Entropia injetável; `--seed` só em debug.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: leitura de argumentos de linha de comando é só do `Main` (ADR-0015 §1); a Run recebe a seed de debug já parseada.

**Control Manifest Rules (this layer)**:
- Required: seed nova só em `→ ATIVA` (ADR-0015)
- Required: provedor de entropia injetado; nada de `randi()`/`Time` dentro da regra (ADR-0005)
- Forbidden: módulo lendo o catálogo para descobrir a arma depois da montagem

---

## Acceptance Criteria

*From GDD `design/gdd/run-e-regioes.md`, scoped to this story:*

- [x] **AC-RN-02 / AC-RN-27** Ordem nos dublês: arma, seed, estado inicial, câmara 0 com `primeira_recompensa`, Transição. Com Pactos e 2 pactuadas: arma, `pedir_dupla`, `dupla_confirmada`, seed, estado inicial (dupla entregue às Maldições), câmara 0, Transição; com Lâmina, nenhum `pedir_dupla`.
- [x] **AC-RN-03 / AC-RN-04** Sem escolha, vale a última arma; na primeira run, `arma_padrao`. Provedor devolve 0x3F9A07C2 → seed 0x3F9A07C2; `--seed=1B2C3D4E` em debug → 0x1B2C3D4E; `--seed=XYZ` → a do provedor.
- [x] **AC-RN-05 / AC-RN-28** Vida inicial = Vida máxima: 100 (Lâmina), 80 (Ressonância), 90 (Pactos); a tela de escolha lógica tem 3 cartas e `doutrina()` devolve o token da carta.
- [x] **AC-RN-29 (respostas do Vínculo)** 0 pactuadas: `dupla_confirmada(vulto_mudo, "")`, Ativa com campo = Vulto Mudo; 1: campo = a espécie, reserva vazia, sem tela.

---

## Implementation Notes

*Derived from ADR-0015 §3 / §5:*

- `SessaoDeJogo.confirmar_arma(id)` / `confirmar_dupla(campo, reserva)` delegam à `Run`; testes com `VinculoNulo` e dublê de Vínculo que responde `dupla_confirmada`.
- A "última arma" vem de `PreferenciasDeArma` (perfil); a gravação é da story 010.

---

## Out of Scope

- Story 005: `FabricaDaRun`/`EscopoDaRun` em si.
- Story 009: a tela de escolha (UI).

---

## Files

- `src/gameplay/run/run.gd`
- `src/gameplay/sessao_de_jogo.gd`
- `tests/unit/run/run_inicio_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/run/run_inicio_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/run-e-regioes/story-003-sequencia-da-regiao.md`; épicos `production/epics/rng/EPIC.md`, `production/epics/armas-das-doutrinas/EPIC.md`, `production/epics/vinculo-e-pactos/EPIC.md` (dublê aceitável no teste)
- Unlocks: `production/epics/run-e-regioes/story-005-composicao-e-escopo-da-run.md`

**Código da fatia**: `GameSession.start()` (seed fixa, loadout inicial) — **substituir**; `src/app/main.gd` passa a só ler `--seed` e entregar à composição (**adaptar**).
