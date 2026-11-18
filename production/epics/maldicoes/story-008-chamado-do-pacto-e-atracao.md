# Story 008: Chamado do Pacto e atração limitada (sem renovação, com respiro)

> **Epic**: Maldições (Doutrina de Pactos)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/maldicoes.md` (R13, R17, R23, F4, F4b)
**Requirement**: `TR-maldicoes-012`, `TR-maldicoes-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Aliados e invocações; ADR-0010: Resolução do combate no passo; ADR-0018: IA de inimigos e chefe
**ADR Decision Summary**: `pode_chamar`/`pedir_chamado(player_id, ponto, dano, m_chamado)` chamados pelo Combate no item 5; executa no 6.1 do mesmo passo. Destino fixado no início (limitado a `alcance_chamado_px`, cortado no 1º obstáculo por `GeometriaDeAcerto.alcance_do_raio`); salto linear em `passos(duracao_salto_s)`, imune a dano e empurrão. No pouso: golpe de área com `M_chamado`, imobiliza o comum mais perto do centro, atrai todos em `raio_atracao_px` via `ia.atrair(id, 90, 30)`; guarda o id só se a IA aceitar. A IA é dona dos contadores, da recusa sem renovação e do respiro.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH (ADR-0010) / LOW (ADR-0017, 0018)
**Engine Notes**: Sem física na regra.

**Control Manifest Rules (Core)**:
- Required: durações de atração e respiro lidas do `MaldicoesTuning`
- Forbidden: o módulo guardar número próprio de atração
- Guardrail: item 6.1 ≤ 0,1 ms

---

## Acceptance Criteria

- [x] AC-ML-17 (R13, F4; emenda: atração 90 passos, dano com `M_chamado`): jogador em `(500,500)` mirando `(1000,500)`, `vulto_mudo` em `(440,500)` → salta até `(920,500)` em 12 passos, causa 17 aos dois Ecos (`M = 1`), imobiliza só o comum por 90 passos e atrai ambos por 90 passos.
- [x] AC-ML-18 (R13): as duas Maldições `Exausta` → o Chamado é recusado e a recarga do Especial permanece 0.
- [x] AC-ML-32 (R23): Chamado aceito no item 5 e `troca` no buffer no mesmo passo → começa o salto, a troca é recusada com `troca_indisponivel(saltando)`, nenhuma técnica.
- [x] AC-ML-24 (R17, F4b): atraído em `t=0` (90), Pulso em `t=50` e Chamado em `t=100` recusados; Eco mira o jogador de `t=90` a `t=119`; novo Chamado em `t=120` atrai por 90.
- [x] AC-ML-25 (F4b): Chamado a cada 120 passos e Pulso a cada 108 por 3600 passos → nunca > 90 passos seguidos atraído; soma ≤ 2700 (75%).
- [x] AC-ML-36 (comportamento) [a confirmar]: *Baluarte* com Chamado a cada 120 passos sobre o chefe por 3600 passos → Abalo de 90 passos por pouso, 30 sem Abalo antes do seguinte, soma ≤ 2700.

---

## Implementation Notes

- Sub-passos 4 e 6 do 6.1. Emite `EvChamadoSalto`, `EvChamadoPouso`, `EvAtraido`, `EvImobilizado`; `chamado_indisponivel` é só do Combate.
- `efeito_chamado` (Raro+) executado pelo `ExecutorDeTecnica`.

---

## Out of Scope

- A recusa e a recarga do Especial (Combate R3.1): épico `combate-nucleo` / `armas-das-doutrinas`.

---

## Files

- `src/gameplay/maldicoes/chamado_do_pacto.gd`
- `tests/integration/maldicoes/chamado_do_pacto_e_atracao_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/maldicoes/chamado_do_pacto_e_atracao_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/maldicoes/story-007-troca-e-tecnica-combinada.md`; épicos `production/epics/combate-nucleo/` (item 5, `pedir_chamado`), `production/epics/ia-de-inimigos-e-elites/` (`atrair`, `imobilizar`, respiro), `production/epics/armas-das-doutrinas/` (Especial da Besta)
- Unlocks: `production/epics/maldicoes/story-009-camara-leitura-eventos-e-orcamento.md`
