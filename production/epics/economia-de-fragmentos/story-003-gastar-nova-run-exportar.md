# Story 003: Gastar, Nova run e exportar/importar sem arquivo

> **Epic**: Economia de Fragmentos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/economia-de-fragmentos.md` (R5, R6, R7, F2, Edge Cases)
**Requirement**: `TR-economia-005`, `TR-economia-006`, `TR-economia-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§6, Implementation Guidelines); ADR-0013: Persistência do MVP
**ADR Decision Summary**: `nova_run()` só zera `coletados_run` (a conta é de sessão; o escopo de run é recriado, a conta não); o saldo fica fora do save no MVP (decisão 21) e `exportar()`/`importar()` existem sem arquivo.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Nenhuma API de engine; nada de `FileAccess`/`ConfigFile` aqui.

**Control Manifest Rules (Feature)**:
- Required: `nova_run()` da sessão chama `conta.nova_run()` depois de soltar o escopo de run
- Required: `saldo` nunca vai para `perfil.cfg`; a run nunca é salva no MVP
- Forbidden: `reset()` em módulo de escopo de run (a conta é de sessão: `nova_run()` é a única operação explícita)

---

## Acceptance Criteria

*From GDD `design/gdd/economia-de-fragmentos.md`, scoped to this story:*

- [x] AC-EF-10 a AC-EF-14 (gastar): saldo 26, `gastar(15)` → 11 e `saldo_mudou(11, −15, motivo)`, `coletados_run` intacto; gasto exato zera; saldo 11, `gastar(15)` → `saldo_insuficiente`, sem evento; custo 0, −3, 1.5 → `EC1`; dois gastos seguidos de 15 com saldo 20 → o 2º recusado.
- [x] AC-EF-15 / AC-EF-16: `nova_run()` com saldo 11 e coletados 11 → saldo 11, coletados 0; morte e abandono (dublês da Run) não mudam o saldo.
- [x] AC-EF-17 a AC-EF-19: `exportar()` = saldo; `importar(40)` numa conta nova → 40 e coletados 0; `importar(-5)`, `1.5`, `"x"` mantêm o saldo e emitem `EC2`; `importar(2 000 000)` com teto 999 999 → 999 999.
- [x] AC-EF-20: conta recriada (simula fechar o jogo) → saldo 0; nenhum arquivo é lido ou gravado.

---

## Implementation Notes

*Derived from ADR-0015 §6 e ADR-0013:*

- Assinaturas do ADR: `gastar(quantidade: int) -> bool`, `nova_run() -> void`, `exportar() -> int`, `importar(valor: Variant) -> void`. O GDD fala em `gastar(custo, motivo)`: o motivo vai no evento; se a assinatura do ADR não tiver `motivo`, use parâmetro opcional `motivo: StringName = &""` e registre o desvio na revisão.
- `gastar` é atômico; ninguém chama no MVP (não há Oficina) — testado com dublê.
- `importar` valida tipo `int`, ≥ 0; corta no `saldo_max`.
- ADR-0013 (TR-economia-009): `exportar`/`importar` seguem sem arquivo; o `RepositorioDePerfil` não os chama.

---

## Out of Scope

- Story 004: quem chama `nova_run()` na sessão (composição)
- Épico persistencia: perfil e `perfil.cfg`

---

## Files

- `src/gameplay/economia/conta_fragmentos.gd`
- `tests/unit/economia/conta_gastar_e_ciclo_test.gd`

Código atual da fatia: nenhum equivalente; construção do zero.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/economia/conta_gastar_e_ciclo_test.gd` — must exist and pass
**Status**: [x] Created and passing (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/economia-de-fragmentos/story-001-conta-creditar-e-eventos.md`
- Unlocks: `production/epics/economia-de-fragmentos/story-005-ordem-com-run-e-portas.md`

## Completion Notes

**2026-11-16 (gameplay-programmer).** `gastar`, `nova_run`, `exportar`, `importar` em `src/gameplay/economia/conta_fragmentos.gd`; teste `tests/unit/economia/conta_gastar_e_ciclo_test.gd` (14 casos, passou).

Decisões: `gastar(quantidade: Variant, motivo: StringName = &"") -> bool` — desvio registrado (o ADR não tem `motivo`; o GDD R5 tem). `importar` corta no `saldo_max` e não emite evento. Nenhuma API de disco (teste confere a fonte). Quem chama `conta.nova_run()` na sessão é a `SessaoDeJogo` (épico run-e-regioes).
