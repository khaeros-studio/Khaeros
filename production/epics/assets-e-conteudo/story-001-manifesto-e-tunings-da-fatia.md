# Story 001: Manifesto do catálogo e `*Tuning` migrados do gameplay.json

> **Epic**: Assets e conteúdo
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R1 tipos, R9 validação); Tuning Knobs de cada GDD dono (Combate, Armas, Câmera, Input, Visual, Bênçãos, HUD, Tela de bênção, Run…)
**Requirement**: N/A — épico transversal sem TR próprio (EPIC.md, "Cobertura de TR"); os TRs de dados (`TR-conteudo-*`, `TR-hud-010`, `TR-tela-bencao-012` e os `*-Tuning` de cada sistema) ficam nos épicos dos sistemas e validam estes arquivos.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: Um carregador lê explicitamente `assets/data/content_catalog.tres` (entradas com tipo e caminho, na ordem gravada) e publica catálogo, impressão e ajustes juntos só após zero erros. Esquema por tipo declara campos, tipos, obrigatoriedade e limites; a ordem do manifesto entra na impressão SHA-256.
**ADR Version**: ADR-0004 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `CACHE_MODE_IGNORE_DEEP` com o manifesto real — NEEDS VERIFICATION (ADR-0004 Verification Required 2).

**Control Manifest Rules (Foundation)**:
- Required: esquema declara campos, tipos, obrigatoriedade, limites e regras entre campos
- Forbidden: executar o importador de conteúdo em runtime
- Guardrail: catálogo — mediana de 5 cargas frias ≤ 250 ms; validação ≤ 30 ms

---

## Acceptance Criteria

*From the epic scope (entrega 1) and the owners' tuning tables:*

- [x] `assets/data/content_catalog.tres` existe e lista, em ordem estável, um `.tres` por `*Tuning` do MVP: Combat, Armas, Camera, Input, Visual, Bencaos, Run, Hud (17 campos), TelaBencao (10 campos), Audio, Feedback, Camaras, Economia (os de Pactos ficam na story 004).
- [x] Cada valor de fábrica é igual ao padrão da tabela Tuning Knobs do GDD dono; os valores que hoje vivem em `data/integration/gameplay.json` migram com o mesmo número (tabela de correspondência no PR).
- [x] O carregador de produção chega a Pronto com zero erros (nenhum HU/TB/… disparado pelo dado de fábrica — AC-HD-37 e AC-TB-35, "o dado de fábrica não gera nenhum código").
- [x] Smoke check registrado em `production/qa/smoke-<data>.md`.

---

## Implementation Notes

*Derived from ADR-0004 (Carga e publicação; Validação):*

- Os tipos de Resource ficam em `src/content/` (épico `conteudo`); esta story só cria os **dados**.
- Ordem do manifesto é contrato (impressão); acrescentar sempre no fim.
- `gameplay.json` continua lido pela fatia até a story 005 aposentá-lo.

---

## Out of Scope

- Stories 002–004: definições de conteúdo (armas, inimigos, bênçãos, regiões, Pactos)
- Story 005: CSV canônico, importação e paridade

---

## Files

- `assets/data/content_catalog.tres` (novo)
- `assets/data/tuning/*.tres` (novos)
- `src/foundation/session_catalog.gd` (adaptar só se precisar ler os `.tres` durante a transição; substituído pelo carregador do épico `conteudo`)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: smoke check pass (`production/qa/smoke-*.md`)
**Status**: [x] Created (`production/qa/evidence/assets-e-conteudo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/conteudo/` (stories dos tipos de Resource, do carregador e do validador)
- Unlocks: `production/epics/assets-e-conteudo/story-002-armas-ataques-e-inimigos.md`; `production/epics/hud/story-001-modelo-do-hud-leitura-e-relogio.md`; `production/epics/tela-de-bencao-e-carta/story-004-tela-bencao-tuning-validacao.md`
