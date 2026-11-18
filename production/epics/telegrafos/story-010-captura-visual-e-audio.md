# Story 010: Telégrafos na tela e no som (captura de multidão, flash, acessibilidade)

> **Epic**: Telégrafos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telegrafos.md` (Visual/Audio Requirements, Game Feel)
**Requirement**: `TR-telegrafos-013`, `TR-telegrafos-014`

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0007: Cena, viewport e câmera; ADR-0016: Áudio: ganchos e vozes
**ADR Decision Summary**: Duas passadas, `TelegrafoPreenchimento` z −5 e `TelegrafoContorno` z 5, um par de nós por slot (pool fixo), crescimento sem pulsar, contorno de 6 px na opção de acessibilidade; áudio pela lista de eventos com no máximo 3 telégrafos soando.
**ADR Version**: ADR-0011 2026-11-16 · ADR-0007 2026-11-14 · ADR-0016 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0011/0007: shaders, interpolação física das âncoras — NOT SOURCEABLE, depende de EX-0011)
**Engine Notes**: interpolação dos nós de telégrafo com a âncora do dono depende da verificação do ADR-0007.

**Control Manifest Rules (this layer)**:
- Required: Apresentação só lê vistas e eventos
- Forbidden: Apresentação escrever em `Telegrafos`
- Guardrail: orçamento de desenho do ADR-0011

---

## Acceptance Criteria

- [x] AC-TG-22 [V] — captura com 9 inimigos em preparo (3 de cada): contornos de 4 px distinguíveis, preenchimento cresce sem pulsar, leitura mantida em cinza e nos 3 simuladores de daltonismo
- [x] AC-TG-23 [V] — captura do disparo (flash de osso 2 passos), quebra (rachadura sem flash) e cancelamento
- [x] TR-telegrafos-013 — opção de acessibilidade liga o contorno de 6 px
- [x] TR-telegrafos-014 — no máximo 3 telégrafos soando ao mesmo tempo
- [x] AC-TG-24 [M] — registro de playtest (≥ 80% evitam o 1º golpe do Eco sem dica): fora do gate desta story, registrado como proposta

---

## Implementation Notes

- A implementação dos nós e shaders vive no épico pipeline-visual; esta story liga as vistas da story-008 ao Pipeline e ao Áudio e produz a evidência.

---

## Out of Scope

- Shaders e LUT (épico pipeline-visual); pool de vozes (épico audio)

---

## Files

- src/presentation/telegrafos_view.gd
- production/qa/evidence/telegrafos-captura-evidence.md
- production/qa/evidence/telegrafos-multidao.png, telegrafos-disparo-quebra.png

Fatia: `world_view.gd::_telegraph` (desenho à mão) — **substituir** pelo par de nós por slot; serve só como referência visual.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: screenshots retidas em `production/qa/evidence/` + sign-off em `production/qa/evidence/telegrafos-captura-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/telegrafos/story-008-publicar-vistas.md`; épicos `production/epics/pipeline-visual/` (EX-0011 E1–E3, camadas z), `production/epics/audio/`, `production/epics/cena-e-camera/`
- Unlocks: None
