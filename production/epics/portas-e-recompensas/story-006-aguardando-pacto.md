# Story 006: Estado Aguardando pacto (passo 2b)

> **Epic**: Portas e recompensas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/portas-e-recompensas.md` (Regras da emenda Pactos: R2-P 2b)
**Requirement**: `TR-portas-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§4 passo 2b, §5); ADR-0002: Canal de eventos
**ADR Decision Summary**: depois da recompensa (e da Bênção, se houver), se `vinculo.encontro_aguardando()` for verdadeiro, as Portas entram em Aguardando pacto até `pacto_resolvido`; a ordem é recompensa → Bênção → pacto → portas. A Run e as Portas só conhecem a `PortaDoVinculoNaRun` (`VinculoNulo` = sem Pactos).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: `VinculoNulo` sobrescreve `encontro_aguardando() -> bool` com `return false` explícito (regra 4.7).

**Control Manifest Rules (this layer)**:
- Required: todo colaborador opcional tem variante Nula (ADR-0015)
- Forbidden: as Portas conhecerem sorteio, acuada ou pontos do Vínculo

---

## Acceptance Criteria

*From GDD `design/gdd/portas-e-recompensas.md`, scoped to this story:*

- [x] **AC-PR-26** Câmara do encontro limpa com recompensa `fragmentos` e `encontro_aguardando()` verdadeiro: `recompensa(fragmentos, 2)` sai, as Portas entram em Aguardando pacto e não pedem as portas; ao chegar `pacto_resolvido`, pedem as portas no mesmo passo.
- [x] **AC-PR-27** Com recompensa `bencao`: `recompensa` → `pedir_oferta` → `tela_fechada`/`bencao_escolhida` → espera `pacto_resolvido` → portas; um `pacto_resolvido` recebido antes do 2b é lembrado e o 2b segue na hora.
- [x] **AC-PR-28** `encontro_aguardando()` falso (sem encontro, ou acuada em `Fugiu`): as portas são pedidas sem esperar.
- [x] **AC-PR-29** Um 2º `pacto_resolvido` é ignorado (portas pedidas uma vez); `jogador_morreu` em Aguardando pacto: nenhuma porta é pedida.

---

## Implementation Notes

*Derived from ADR-0015 §4–§5:*

- Campo `_pacto_resolvido_lembrado: bool` no estado das Portas da câmara corrente (escopo de câmara/run; recriado, não zerado).
- A saída de Aguardando pacto também checa `run.ativa()`.

---

## Out of Scope

- Épico `vinculo-e-pactos`: tela de consentimento, `pacto_resolvido`.

---

## Files

- `src/gameplay/portas/portas.gd`
- `tests/unit/portas/portas_aguardando_pacto_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/portas/portas_aguardando_pacto_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/portas-e-recompensas/story-005-fluxo-da-limpeza.md`; épico `production/epics/vinculo-e-pactos/EPIC.md` (`PortaDoVinculoNaRun` + `VinculoNulo`; pode ser dublê no teste)
- Unlocks: None

**Código da fatia**: nenhum equivalente; construção do zero.
