# Story 009: Experimento de API de áudio (EX-0016-A)

> **Epic**: experimentos-de-engine
> **Status**: Done
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `docs/architecture/architecture.md`
**Requirement**: nenhum TR próprio. Desbloqueia o épico `audio` (ADR-0016).

**ADR Governing Implementation**: ADR-0016: Áudio: ganchos e vozes
**ADR Decision Summary**: Barramentos, pool de vozes de `AudioStreamPlayer`, eventos para sons pela lista do passo (`SomDef`, `AudioTuning`); `AudioStreamPolyphonic` não é usado.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: tabela "Confirmação de API" do ADR-0016: `pitch_scale`, `stream_paused`, `linear_to_db()`, `res://default_bus_layout.tres` e loop por flag de import são NOT SOURCEABLE; tudo entra no protótipo.

**Control Manifest Rules (this layer)**:
- Required: áudio é o último consumidor da lista de eventos (ADR-0002/0016).
- Forbidden: `AudioStreamPolyphonic`.
- Guardrail: n/a (vozes: orçamento do ADR-0016).

---

## Acceptance Criteria

*Da tabela "Confirmação de API" do ADR-0016 e do EPIC.md.*

- [ ] `AudioServer.get_bus_index(nome)` devolve -1 para barramento inexistente e o índice para existente (layout carregado de `default_bus_layout.tres`).
- [ ] `AudioStreamPlayer.pitch_scale` muda o tom em tempo real; faixa utilizável anotada.
- [ ] `AudioStreamPlayer.stream_paused` pausa e retoma sem reiniciar o stream.
- [ ] `volume_db` e `linear_to_db()`: 1.0 → 0 dB, 0.5 → aprox. -6,02 dB, 0.0 → -inf tratado; valores medidos.
- [ ] `default_bus_layout.tres` carrega no build exportado com os barramentos esperados.
- [ ] Loop do stream do tom contínuo: flag de import (WAV/OGG) que produz loop sem estalo, anotada.
- [ ] Resultado de cada item: "confirmado" ou "usar fallback do ADR-0016".

---

## Implementation Notes

Protótipo em `prototypes/engine-verificacao/audio/` com tons gerados (sem assets finais). Verificar auditivamente o loop; anotar no documento de evidência o que se ouviu.

---

## Out of Scope

- Pool de vozes, `SomDef`, mixagem de produção: épico `audio`.

---

## Files

- `prototypes/engine-verificacao/audio/`
- `production/qa/evidence/experimentos/ex-0016-audio-api.md`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/experimentos/ex-0016-audio-api.md`.

**Status**: [x] Created (2026-11-16)

---

## Dependencies

- Depends on: None
- Unlocks: épico `audio` (todas as stories)

---

## Completion Notes

**Data**: 2026-11-16 · Godot 4.7.2, janela real, WASAPI 48 kHz + `.pck` exportado (binário do editor) · evidência `production/qa/evidence/experimentos/ex-0016-audio-api.md` · protótipo `prototypes/engine-verificacao/audio/` (`gerar.gd`, `audio_probe.gd`).

| Item | Resultado |
|---|---|
| `get_bus_index` | **VERIFICADO** — -1 para inexistente/vazio; 0–3 para Master/Musica/Efeitos/Interface do `default_bus_layout.tres` |
| `pitch_scale` | **VERIFICADO** — tempo real, 0,25–4 medido com erro < 3 % (frequência por cruzamento de zero); `0.0` dá erro e é ignorado |
| `stream_paused` | **VERIFICADO** — retoma do ponto (0,769 → 1,271 após 0,5 s); `playing` lê **false** enquanto pausado |
| `volume_db` / `linear_to_db` | **VERIFICADO** — 0 dB; -6,0206 dB (RMS ×0,5002); 0 → -inf sem erro, silêncio |
| `default_bus_layout.tres` exportado | **VERIFICADO** no `.pck` (release template NÃO RODADO) |
| Loop por flag de import | **VERIFICADO (WAV)** — `edit/loop_mode=2` com `loop_end` padrão: loop contínuo, emenda com salto ~2× a inclinação (sem estalo medido). `loop_end` = nº de amostras gera estalo. OGG **NÃO RODADO**; escuta humana não feita (medição objetiva) |

**ADR-0016 precisa mudar**: tabela "Confirmação de API" para Confirmada; validar `pitch_scale > 0`; pool não pode usar `playing` sozinho como "voz livre" (pausadas leem false); loop WAV com `loop_mode=2` e `loop_end` padrão, proibir `loop_end = n`; não presumir 44,1 kHz.
