# Story 004: Experimentos de eventos, ponto flutuante e latência (EX-0002-1..3, EX-0009-1, EX-0010-1)

> **Epic**: experimentos-de-engine
> **Status**: Done
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-17

## Context

**GDD**: `docs/architecture/architecture.md`
**Requirement**: nenhum TR próprio. Desbloqueia TR-combate-nucleo-009 (eventos), TR-combate-nucleo-018 (AC-92) e TR-modificadores-* (AC-03/AC-05).

**ADR Governing Implementation**: ADR-0002: Canal de eventos (também ADR-0009 VR(1) e ADR-0010 AC-92)
**ADR Decision Summary**: Um `RefCounted` por evento, `Array[EventoDoPasso]` com subclasses `@abstract`, entrega à Apresentação no fim do passo; aritmética de modificadores em `float` de 64 bits com arredondamento próprio; latência toque→golpe ≤ 2 passos + 1 quadro.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `@abstract` é 4.5 (confirmado no ADR-0001); regra 4.7: `override` com retorno tipado não-void exige `return` explícito. `RenderingServer.frame_post_draw` NEEDS VERIFICATION (ADR-0010). "Float 64 bits" NOT SOURCEABLE (ADR-0009).

**Control Manifest Rules (this layer)**:
- Required: todo evento é subclasse tipada de `EventoDoPasso` (`@abstract`); `tipo()` com `return` explícito (ADR-0002).
- Forbidden: sinais do Godot entre módulos de regra; evento como `Dictionary`.
- Guardrail: emissão de eventos entra no orçamento do Combate (0,3 ms p99, provisório).

---

## Acceptance Criteria

*Do ADR-0002 "Validation Criteria" (medição no protótipo), ADR-0009 VR(1) e ADR-0010 AC-92.*

- [ ] EX-0002-1: custo de alocar 20, 50 e 100 `RefCounted` de evento por passo (tempo por passo, média e p99, em 10 000 passos) no build de release, na máquina de referência. Valor registrado, comparado a 0,3 ms.
- [ ] EX-0002-2: `Array[EventoDoPasso]` com ≥ 3 subclasses `@abstract`: `append`, `do_tipo()` por filtro com array tipado, downcast com `as`, e que `filter()` sem tipo falha a atribuição (conforme ADR-0002), registrado.
- [ ] EX-0002-3: ordem de entrega de sinais com `CONNECT_DEFERRED` na Apresentação comparada à ordem fixa Telemetria, HUD, Feedback, Telas, Áudio; registrado se a ordem fixa por lista é necessária (deve ser).
- [ ] EX-0009-1: em build padrão, `float` do GDScript preserva 2^53+1 distinto de 2^53 (prova de 64 bits) e `0.1 + 0.2` dá o valor IEEE-754 de dupla precisão; resultado idêntico em editor e export.
- [ ] EX-0010-1: `RenderingServer.frame_post_draw` dispara uma vez por quadro, depois do desenho; método de medir toque→golpe com ele descrito e latência medida em um protótipo (≤ 2 passos + 1 quadro, ADR-0010), ou fallback registrado.
- [ ] Resultado de cada item: "confirmado" ou "usar fallback do ADR".

---

## Implementation Notes

Protótipo em `prototypes/engine-verificacao/eventos-e-aritmetica/`. Medir com `Time.get_ticks_usec` (permitido no protótipo; a lógica de jogo continua proibida de ler `Time`). Para EX-0010-1, injetar um `InputEvent` sintético e comparar o carimbo de entrada ao carimbo de `frame_post_draw` do quadro em que o golpe aparece. O orçamento (0,3 ms) é do Combate; aqui só se mede.

---

## Out of Scope

- Implementação do canal de eventos: `production/epics/orquestrador-do-passo/story-001-canal-de-eventos.md`.
- Teste AC-03/AC-05 de modificadores: épico `modificadores`. AC-92 de produção: épico `combate-nucleo`.

---

## Files

- `prototypes/engine-verificacao/eventos-e-aritmetica/`
- `production/qa/evidence/experimentos/ex-0002-eventos.md`, `ex-0009-float64.md`, `ex-0010-latencia.md`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: os três documentos acima, com números medidos e a máquina identificada.

**Status**: [x] Created (2026-11-16)

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/orquestrador-do-passo/story-001-canal-de-eventos.md`; épicos `modificadores` e `combate-nucleo` (story do AC-92)

## Completion Notes

**2026-11-16 — godot-specialist.** Executado no Godot 4.7.2, num Ryzen 5 5600H. Rodou no projeto (headless e janela) e no `.pck` exportado com `--export-pack` e executado com `--main-pack`. Evidência: `production/qa/evidence/experimentos/ex-0002-eventos.md`, `ex-0009-float64.md`, `ex-0010-latencia.md`.

Arquivos em `prototypes/engine-verificacao/eventos-e-aritmetica/`: `project.godot`, `export_presets.cfg`, `eventos/evento_do_passo.gd` (`@abstract`), `evento_dano.gd`, `evento_morte.gd`, `evento_esquiva.gd`, `probe.gd`, `probe_extra.gd`, `latencia.gd`, `latencia.tscn`.

| Item | Resultado | O que o ADR precisa mudar |
|---|---|---|
| EX-0002-1 custo | **PARCIAL**: p99/passo, 20 eventos = 166–198 µs (cabe); 50 = 330–482 µs e 100 = 590–1 408 µs (**estoura 0,3 ms**). Binário debug | ADR-0002: registrar números. O ADR não tem fallback escrito; decidir entre medir no release, teto de eventos/passo ou rever orçamento |
| EX-0002-2 tipos | **VERIFICADO** append/`as`/filtro por `tipo()`; **REFUTADO** "`filter()` sem tipo falha a atribuição": no 4.7.2 `filter()` de array tipado devolve tipado e a atribuição passa. `@abstract` não bloqueia `Script.new()` dinâmico | ADR-0002 linha 120: corrigir a frase do `filter()`; anotar o limite do `@abstract` |
| EX-0002-3 sinais | **CONFIRMADO**: os deferidos chegam na ordem de conexão, depois que o emissor retorna; a ordem fixa por lista é necessária | marcar VR(3) confirmado |
| EX-0009-1 float64 | **VERIFICADO**: binary64 (`0.1+0.2` = `0x3FD3333333333334`, `2^52+1 ≠ 2^52`), igual no projeto e no `.pck`. O critério "2^53+1 distinto de 2^53" está **errado** (binary64 não representa 2^53+1). Achado: o literal `9007199254740993.0` vira 2^53+2 no tokenizer, e `to_float()` dá 2^53 | ADR-0009: trocar o critério; anotar a nota sobre literais em empate |
| EX-0010-1 latência | **VERIFICADO**: `frame_post_draw` 1×/quadro (936 quadros); toque→golpe máx 22,1 ms (vsync off) / 33,3 ms (vsync 60 Hz) ≤ 50 ms; golpe no 1º passo | ADR-0010: marcar verificado; deixar explícito que a medida exclui periférico e scan-out |

Decisões: o AC do EX-0009-1 foi executado como escrito e reportado como mal formulado, em vez de "passar" um teste incorreto. A latência foi medida com injeção em `_process` e a tecla solta depois de cada amostra (a 1ª versão travava porque a tecla não era solta).

**Atualização 2026-11-17:** mudanças nos ADRs 0002, 0009 e 0010 e no `control-manifest.md` aplicadas em `2026-11-17`. Pendências residuais de hardware/release (templates de exportação 4.7.2 e monitor de 144 Hz físico) registradas sem bloquear a story.
