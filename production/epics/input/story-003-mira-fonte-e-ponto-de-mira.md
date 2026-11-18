# Story 003: Mira (F4), fonte da mira, intensidade e `ponto_mira`

> **Epic**: Input e controle
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/input-e-controle.md`
**Requirement**: `TR-input-005`, `TR-input-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Input por passo (com ADR-0007 para a conversão tela → mundo)
**ADR Decision Summary**: A mira recebe a conversão janela → mundo da Cena e a consulta de alvos por valores em ordem estável de spawn (ADR-0003); F4 ignora surgindo, distância zero e alvos fora do raio inclusivo, empate mantém o primeiro; cursor fora da janela conserva a posição de janela e reconverte a cada passo.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: `InputEvent.position` não é presumido em pixel de janela (ADR-0007); a conversão chega injetada e a normalização para o espaço Janela é feita uma vez no adaptador.

**Control Manifest Rules (this layer)**:
- Required: conversão tela → mundo injetada pela Cena; consulta de alvos por valores, sem guardar referência ao inimigo (ADR-0006, ADR-0003)
- Forbidden: converter pelo canvas que contém tremor; `get_global_mouse_position()` (ADR-0007)
- Guardrail: consulta no começo do passo, depois das mortes do passo anterior

---

## Acceptance Criteria

*From GDD `design/gdd/input-e-controle.md`, scoped to this story:*

- [ ] **AC-09** p = (0,0): a lista [A, B, C] → (0,6; 0,8) e [B, A, C] → (0,8; 0,6) (no empate vence o primeiro)
- [ ] **AC-10** Inimigo em (1350, 0) → mira (1, 0) (raio inclusivo); em (1350,01; 0) → usa o movimento; d = 0 ignorado; todos surgindo → movimento; analógico direito ativo vence o inimigo; tudo zero → direção do personagem; sem direção → (0, −1)
- [ ] **AC-11** O alvo some da consulta no passo seguinte → a mira vai para o próximo mais perto
- [ ] **AC-12** Com stub da conversão: cursor sobre o personagem → mantém a mira anterior; cursor fora da janela → usa a última posição de tela válida, reconvertida no passo atual
- [ ] **AC-37** Mouse ativo → `fonte_mira` = `mouse`, `intensidade_mira` = 0; analógico direito s = (0,3; 0,4) → `analogico`, 0,4 ± 1e-4; analógico na zona morta com inimigo no raio → `automatica`, 0; sem inimigo e sem movimento → `automatica`, 0; consulta de cursor em (960, 540) e depois fora da janela → (960, 540) nas duas leituras
- [ ] **AC-45** Mouse ativo com cursor no ponto de mundo (1000, 500) → `ponto_mira` = (1000, 500); gamepad, analógico direito na zona morta e inimigo em (900, 500) no raio → `ponto_mira` = (900, 500); analógico direito ativo → `ponto_mira` vazio

---

## Implementation Notes

*Derived from ADR-0006 §4 e Key Interfaces:*

O provedor recebe a função de conversão janela → mundo e a consulta de alvos como valores injetados (nunca um nó); a mira de gameplay usa a base `pos` da Cena (ver Cena, story 004). Só a Cena consulta o cursor em render para o lookahead e essa leitura não drena bordas nem altera a mira da simulação. Mouse sobre o personagem conserva a mira anterior; mira inicial sem direção é (0, −1). `ponto_mira` é um vec2 de mundo ou vazio, na amostra de 9 campos (ADR-0006, emenda Pactos).

**Código atual da fatia:** a mira de `game_input.gd` é **adaptar** — manter apenas a ideia de mira automática ao inimigo mais próximo; reescrever com F4, o raio inclusivo e `fonte_mira`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: movimento e dispositivo ativo
- Épico cena-e-camera, story 004: o snapshot tela → mundo real (aqui entra stub)
- Épico ia-de-inimigos-e-elites: a lista real de alvos

---

## Files

- `src/foundation/input/mira.gd`
- `src/foundation/input/provedor_de_entrada.gd` (acréscimo)
- `tests/unit/input/mira_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/input/mira_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/input/story-002-amostra-por-passo-movimento-e-dispositivo.md`
- Unlocks: `production/epics/cena-e-camera/story-004-snapshot-tela-para-mundo-e-resize.md`

## Completion Notes

**Concluída em 2026-11-16 (sem commit).**

Arquivos: `src/foundation/input/mira.gd` (criado) e `provedor_de_entrada.gd` (acréscimo de `configurar_mira(janela_para_mundo, consulta_alvos, consulta_jogador)`). Teste: `tests/unit/input/mira_test.gd`, 16 casos, todos passam.

Decisões:
- Os alvos chegam como `Array` de `{pos: Vector2, surgindo: bool}`, em ordem de spawn. O jogador chega como `{pos, olhar}`. As três consultas são `Callable`s injetadas, nunca nós.
- A fonte é `mouse` sempre que o dispositivo ativo é teclado/mouse. Se o cursor nunca teve posição válida, a mira anterior é conservada e `ponto_mira` fica vazio.
- O cursor fora da janela é descartado no adaptador (`registrar_cursor`). O provedor reconverte a última posição válida a cada passo.
- Sem ajustes (sem `InputTuning`), a mira de jogo não é calculada e `ponto_mira` fica vazio.

Pendências:
- A conversão real tela → mundo vem da Cena (cena-e-camera, story 004). Aqui foi usado um dublê.
- A lista real de alvos vem do épico ia-de-inimigos-e-elites.
