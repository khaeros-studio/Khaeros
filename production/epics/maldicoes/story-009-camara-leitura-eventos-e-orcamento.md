# Story 009: Troca de câmara, leitura `estado_pacto`, eventos da R20 e orçamento do item 6.1

> **Epic**: Maldições (Doutrina de Pactos)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/maldicoes.md` (R14, R19, R20, R21)
**Requirement**: `TR-maldicoes-013`, `TR-maldicoes-014`, `TR-maldicoes-015`, `TR-maldicoes-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Aliados e invocações; ADR-0002: Canal de eventos; ADR-0015: Ciclo da run e composição; ADR-0012: UI e HUD; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: `reposicionar_maldicao(player_id, pos)` (chamado pelas Câmaras): `SEGUINDO`, fio, alvo e marca limpos, atrações/imobilizações encerradas com aviso à IA, reserva intocada. `estado_pacto(player_id)` é leitura sem efeito colateral. Eventos são subclasses de `EventoDoPasso` com `player_id`, emissor único (tabela §10); nunca em passo congelado. Item 6.1 medido pelo `MedidorDeOrcamento` contra 0,1 ms p99.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH (ADR-0001/0002) / LOW (ADR-0017)
**Engine Notes**: `Time.get_ticks_usec()` só no adaptador real do medidor.

**Control Manifest Rules (Core)**:
- Required: eventos na lista do passo; Apresentação só lê
- Forbidden: sinal do Godot na regra
- Guardrail: Maldições (item 6.1) 0,1 ms p99, cena de estresse, 600 passos

---

## Acceptance Criteria

- [x] AC-ML-19 (R14): `espreitador_da_fenda` `60/95` em campo, `vulto_mudo` `Exausta` com 210, `recarga_troca = 90` → no corte do wipe, o Espreitador fica junto ao jogador com `60/95`, marca limpa, 210 e 90 preservados.
- [x] AC-ML-35 (R14 emenda): `reposicionar_maldicao((960, 1035))` com Baluarte (raio 30), marca, 2 atraídos e `estourou_fio` → `(960, 1035)` em `Seguindo`, `estourou_fio` falso, `marca_virote_mudou` vazio e 2 `atracao_fim`, reserva igual; com raio de teste 60, ponto `(960, 1020)`.
- [x] AC-ML-28 (R19): *Soberano* Exausto há 100 passos e *Vulto* `Saltando` com recarga 90 → `reserva.estado = Exausta`, `restante_exausta = 380`, `total_exausta = 480`, `campo.estado = Saltando`, `recarga_troca_passos = 90`, `recarga_troca_total = 240`, `troca_disponivel = falso`; igual na pausa.
- [x] AC-ML-29 (R20): troca manual, troca automática, Virote em outro inimigo, estouro do fio e Chamado que atrai 2 → exatamente `troca_feita(manual)` + `tecnica_combinada`; `troca_feita(automatica)`; `marca_virote_mudou`; 1 `fio_estourou`; 2 `atraido` e 2 `atracao_fim`; nenhum `chamado_indisponivel` das Maldições.
- [x] TR-maldicoes-019: item 6.1 com p99 ≤ 0,1 ms na cena de estresse (600 passos), medido pelo `MedidorDeOrcamento`.

---

## Implementation Notes

- Sub-passo 1 do 6.1 emite `atracao_fim`/`imobilizacao_fim` dos ids que a IA dá como livres.
- `EstadoPactoLeitura` é um registro somente leitura consumido pelo Bloco do Pacto do HUD (épico `hud`).

---

## Out of Scope

- Bloco do Pacto no HUD: épico `production/epics/hud/`. Sons: story 010 e épico `audio`.

---

## Files

- `src/gameplay/maldicoes/estado_pacto_leitura.gd`, `eventos_maldicoes.gd`, `modulo_de_maldicoes.gd`
- `tests/integration/maldicoes/camara_leitura_e_eventos_test.gd`
- `tests/integration/maldicoes/orcamento_item_6_1_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/maldicoes/camara_leitura_e_eventos_test.gd`, `tests/integration/maldicoes/orcamento_item_6_1_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/maldicoes/story-008-chamado-do-pacto-e-atracao.md`; épicos `production/epics/camaras-e-ondas/` (chamada na troca de câmara), `production/epics/orquestrador-do-passo/` (`MedidorDeOrcamento`, catálogo de eventos)
- Unlocks: `production/epics/maldicoes/story-010-fio-marca-e-ganchos-de-som.md`, épico `production/epics/hud/` (Bloco do Pacto)
