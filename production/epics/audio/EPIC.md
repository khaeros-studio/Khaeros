# Epic: Áudio: ganchos e vozes

> **Layer**: Presentation
> **GDD**: docs/architecture/adr-0016-audio-ganchos-e-vozes.md
> **Architecture Module**: Áudio (barramentos, pool de vozes, eventos→sons)
> **Status**: Complete
> **Stories**: 5 / 5 Complete (`story-001` a `story-005`)
> **Engine Risk**: MEDIUM
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Barramentos, pool de vozes com prioridade, eventos→sons pela lista do passo (`SomDef`, `AudioTuning`), tom do telégrafo, pausa e Bênção. Sem GDD próprio no MVP: o ADR-0016 deriva dos ganchos do Feedback e dos Telégrafos.

## Dependências entre épicos

- orquestrador-do-passo
- feedback-de-combate
- telegrafos
- experimentos-de-engine (EX-0016-A)

## Estado atual do código

Nenhum código na fatia de 2026-11-14 cobre este módulo: construção do zero.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0016: Áudio: ganchos e vozes](../../../docs/architecture/adr-0016-audio-ganchos-e-vozes.md) | Barramentos, pool de vozes, eventos→sons pela lista do passo (SomDef, AudioTuning) | MEDIUM |

## Cobertura de TR

Não é dono de TR-IDs. Implementa os TRs de áudio de outros sistemas: `TR-feedback-008` (épico feedback-de-combate) e `TR-telegrafos-014` (épico telegrafos); as stories desses TRs são escritas aqui ou referenciam este épico.

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every item of the scope above closed with its result recorded
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
